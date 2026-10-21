#!/usr/bin/env bash
# cleanup-liberty.sh  v1.2
# Interactive menu for Liberty / Podman cleanup tasks.

set -uo pipefail

CONTAINER_NAME="server-info-app"
IMAGE_NAME="liberty-server-info:1.0"
PORT_HTTP=9080
PORT_HTTPS=9081
PORT_ADMIN=9443

# ── Helper ────────────────────────────────────────────────────────────────────
header() {
    echo ""
    echo "========================================="
    echo "  $*"
    echo "========================================="
}

# Remove every container whose image name contains a Liberty pattern.
# This catches containers that were started with a name other than CONTAINER_NAME.
remove_all_liberty_containers() {
    echo ""
    echo "--- Sweeping for any remaining Liberty containers ---"
    # Match images from: icr.io/appcafe/open-liberty, websphere-liberty, liberty-*
    local liberty_containers
    liberty_containers=$(podman ps -a --format "{{.Names}} {{.Image}}" \
        | awk '/open-liberty|websphere-liberty|liberty-/{print $1}')

    if [ -z "${liberty_containers}" ]; then
        echo "  [SKIP] No additional Liberty containers found."
        return 0
    fi

    local sweep_errors=0
    while IFS= read -r cname; do
        # Stop if running
        if podman ps --format "{{.Names}}" | grep -q "^${cname}$"; then
            podman stop "${cname}" >/dev/null \
                && echo "  [OK] Stopped '${cname}'." \
                || { echo "  [FAIL] Could not stop '${cname}'."; sweep_errors=$((sweep_errors+1)); continue; }
        fi
        # Remove
        podman rm "${cname}" >/dev/null \
            && echo "  [OK] Removed '${cname}'." \
            || { echo "  [FAIL] Could not remove '${cname}'."; sweep_errors=$((sweep_errors+1)); }
    done <<< "${liberty_containers}"

    [ "${sweep_errors}" -eq 0 ] \
        || echo "  [WARN] ${sweep_errors} container(s) could not be fully cleaned."
}

# ── Task 1 : Clean container and image ───────────────────────────────────────
clean_container_and_image() {
    header "Clean Container and Image"

    # Stop container
    echo ""
    echo "[1/3] Stopping container: ${CONTAINER_NAME} ..."
    if podman ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        podman stop "${CONTAINER_NAME}"
        echo "      [OK] Container stopped."
    else
        echo "      [SKIP] Container '${CONTAINER_NAME}' was not running."
    fi

    # Remove container
    echo ""
    echo "[2/3] Removing container: ${CONTAINER_NAME} ..."
    if podman ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        podman rm "${CONTAINER_NAME}"
        echo "      [OK] Container removed."
    else
        echo "      [SKIP] Container '${CONTAINER_NAME}' not found."
    fi

    # Remove any other lingering Liberty containers
    remove_all_liberty_containers

    # Remove image
    echo ""
    echo "[3/3] Removing image: ${IMAGE_NAME} ..."
    if podman images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${IMAGE_NAME}$"; then
        podman rmi "${IMAGE_NAME}"
        echo "      [OK] Image removed."
    else
        echo "      [SKIP] Image '${IMAGE_NAME}' not found."
    fi

    # Verify
    echo ""
    echo "----- Verification -----"
    local errors=0
    if podman ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        echo "  [FAIL] Container '${CONTAINER_NAME}' still exists!"
        errors=$((errors + 1))
    else
        echo "  [OK] Container '${CONTAINER_NAME}' is gone."
    fi
    if podman images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${IMAGE_NAME}$"; then
        echo "  [FAIL] Image '${IMAGE_NAME}' still exists!"
        errors=$((errors + 1))
    else
        echo "  [OK] Image '${IMAGE_NAME}' is gone."
    fi
    [ "${errors}" -eq 0 ] \
        && echo "  All done." \
        || echo "  [WARN] ${errors} task(s) did not complete as expected."
}

# ── Task 2 : Clean wlp directory ─────────────────────────────────────────────
clean_wlp() {
    header "Clean wlp Directory"

    echo ""
    echo "[1/1] Removing wlp directory (if present) ..."
    if [ -d "./wlp" ]; then
        rm -rf "./wlp"
        echo "      [OK] wlp directory removed."
    else
        echo "      [SKIP] wlp directory not found."
    fi

    # Verify
    echo ""
    echo "----- Verification -----"
    if [ -d "./wlp" ]; then
        echo "  [FAIL] wlp directory still exists!"
    else
        echo "  [OK] wlp directory is gone."
    fi
}

# ── Task 3 : Stop processes on ports 9080 and 9443 ───────────────────────────
stop_ports() {
    header "Stop Processes on Ports ${PORT_HTTP}, ${PORT_HTTPS} and ${PORT_ADMIN}"

    local errors=0

    for PORT in "${PORT_HTTP}" "${PORT_HTTPS}" "${PORT_ADMIN}"; do
        echo ""
        echo "Freeing port ${PORT} ..."
        PORT_PIDS=$(lsof -ti tcp:"${PORT}" 2>/dev/null || true)
        if [ -n "${PORT_PIDS}" ]; then
            echo "  Found PID(s) on port ${PORT}: ${PORT_PIDS}"
            echo "${PORT_PIDS}" | xargs kill -9
            echo "  [OK] Process(es) killed."
        else
            echo "  [SKIP] No process found on port ${PORT}."
        fi
    done

    # Verify
    echo ""
    echo "----- Verification -----"
    for PORT in "${PORT_HTTP}" "${PORT_HTTPS}" "${PORT_ADMIN}"; do
        PORT_PIDS=$(lsof -ti tcp:"${PORT}" 2>/dev/null || true)
        if [ -n "${PORT_PIDS}" ]; then
            echo "  [FAIL] Port ${PORT} is still in use by PID(s): ${PORT_PIDS}"
            errors=$((errors + 1))
        else
            echo "  [OK] Port ${PORT} is free."
        fi
    done
    [ "${errors}" -eq 0 ] \
        && echo "  All done." \
        || echo "  [WARN] ${errors} port(s) could not be freed."
}

# ── Task 4 : Cleanup all ──────────────────────────────────────────────────────
cleanup_all() {
    header "Cleanup All"

    # Container stop
    echo ""
    echo "[1/6] Stopping container: ${CONTAINER_NAME} ..."
    if podman ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        podman stop "${CONTAINER_NAME}"
        echo "      [OK] Container stopped."
    else
        echo "      [SKIP] Container '${CONTAINER_NAME}' was not running."
    fi

    # Container remove
    echo ""
    echo "[2/6] Removing container: ${CONTAINER_NAME} ..."
    if podman ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        podman rm "${CONTAINER_NAME}"
        echo "      [OK] Container removed."
    else
        echo "      [SKIP] Container '${CONTAINER_NAME}' not found."
    fi

    # Remove any other lingering Liberty containers
    remove_all_liberty_containers

    # Image remove
    echo ""
    echo "[3/6] Removing image: ${IMAGE_NAME} ..."
    if podman images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${IMAGE_NAME}$"; then
        podman rmi "${IMAGE_NAME}"
        echo "      [OK] Image removed."
    else
        echo "      [SKIP] Image '${IMAGE_NAME}' not found."
    fi

    # Kill ports
    echo ""
    echo "[4/6] Freeing ports ${PORT_HTTP}, ${PORT_HTTPS} and ${PORT_ADMIN} ..."
    for PORT in "${PORT_HTTP}" "${PORT_HTTPS}" "${PORT_ADMIN}"; do
        PORT_PIDS=$(lsof -ti tcp:"${PORT}" 2>/dev/null || true)
        if [ -n "${PORT_PIDS}" ]; then
            echo "      Found PID(s) on port ${PORT}: ${PORT_PIDS}"
            echo "${PORT_PIDS}" | xargs kill -9
            echo "      [OK] Port ${PORT} — process(es) killed."
        else
            echo "      [SKIP] No process found on port ${PORT}."
        fi
    done

    # wlp dir
    echo ""
    echo "[5/6] Removing wlp directory (if present) ..."
    if [ -d "./wlp" ]; then
        rm -rf "./wlp"
        echo "      [OK] wlp directory removed."
    else
        echo "      [SKIP] wlp directory not found."
    fi

    # Verify
    echo ""
    echo "========================================="
    echo " Verification"
    echo "========================================="
    local errors=0

    podman ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$" \
        && { echo "  [FAIL] Container '${CONTAINER_NAME}' still exists!"; errors=$((errors+1)); } \
        || echo "  [OK] Container '${CONTAINER_NAME}' is gone."

    podman images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${IMAGE_NAME}$" \
        && { echo "  [FAIL] Image '${IMAGE_NAME}' still exists!"; errors=$((errors+1)); } \
        || echo "  [OK] Image '${IMAGE_NAME}' is gone."

    [ -d "./wlp" ] \
        && { echo "  [FAIL] wlp directory still exists!"; errors=$((errors+1)); } \
        || echo "  [OK] wlp directory is gone."

    for PORT in "${PORT_HTTP}" "${PORT_HTTPS}" "${PORT_ADMIN}"; do
        PORT_PIDS=$(lsof -ti tcp:"${PORT}" 2>/dev/null || true)
        [ -n "${PORT_PIDS}" ] \
            && { echo "  [FAIL] Port ${PORT} still in use by PID(s): ${PORT_PIDS}"; errors=$((errors+1)); } \
            || echo "  [OK] Port ${PORT} is free."
    done

    echo ""
    if [ "${errors}" -eq 0 ]; then
        echo "  All cleanup tasks completed successfully."
    else
        echo "  [WARN] ${errors} task(s) did not complete as expected. Review output above."
    fi
}

# ── Menu ──────────────────────────────────────────────────────────────────────
show_menu() {
    echo ""
    echo "========================================="
    echo "   Liberty Cleanup Script  v1.2"
    echo "========================================="
    echo "  1) Clean container and image"
    echo "  2) Clean wlp directory"
    echo "  3) Stop processes on ports ${PORT_HTTP}, ${PORT_HTTPS} and ${PORT_ADMIN}"
    echo "  4) Cleanup all"
    echo "  5) Exit"
    echo "-----------------------------------------"
    printf "  Select an option [1-5]: "
}

while true; do
    show_menu
    read -r choice
    case "${choice}" in
        1) clean_container_and_image ;;
        2) clean_wlp ;;
        3) stop_ports ;;
        4) cleanup_all ;;
        5) echo ""; echo "  Goodbye."; echo ""; exit 0 ;;
        *) echo ""; echo "  [!] Invalid option '${choice}'. Please enter 1-5." ;;
    esac
    echo ""
    printf "  Press ENTER to return to the menu ..."
    read -r
done

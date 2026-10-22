# Introduction to Liberty — Hands-on Labs (Laptop Edition)

| | |
|---|---|
| **Audience** | Techniacl Sellers, Developers and Administrators new to WebSphere / Open Liberty |
| **Format** | Self-paced, runs entirely on your own laptop (no cloud account needed) |
| **Duration** | About 90 minutes (Lab 1: 40 min, Lab 2: 25 min, Lab 3: 25 min) |
| **Operating systems** | macOS, Linux, or Windows with WSL2. All commands are for **bash/zsh**. |
| **Server name used** | `mylibertyserver` (you may pick another name, but use the same one everywhere) |

---

## Contents

1. [Objective](#1-objective)
2. [Environment preparation](#2-environment-preparation)
3. [Lab 1 — Liberty Kernel: install, configure and run](#3-lab-1--liberty-kernel-install-configure-and-run)
4. [Lab 2 — Developer productivity with Maven and dev mode](#4-lab-2--developer-productivity-with-maven-and-dev-mode)
5. [Lab 3 — Containerizing the application with Podman](#5-lab-3--containerizing-the-application-with-podman)
6. [Troubleshooting](#6-troubleshooting)
7. [Final cleanup](#7-final-cleanup)

---

## How to read this guide

- Every command is in a grey code block. Copy and paste it into your terminal exactly as shown, one block at a time.
- Lines starting with `#` inside a code block are comments. You can paste them too.
- **Expected** tells you what you should see. If you see something different, go to [Troubleshooting](#6-troubleshooting).
- Text in `<angle brackets>` is a placeholder you must replace with your own value.
- Several steps need **two terminals**. The guide labels them **Terminal 1** and **Terminal 2**.
- All activities in a terminal window must start from the `LAB_HOME` directory. Before running anything in a new terminal (Terminal 1 or Terminal 2), run `cd "$LAB_HOME"` and confirm with `pwd`. All commands use paths relative to `LAB_HOME`, unless a step tells you to move into a subfolder (see [section 2.2](#22-choose-your-lab-home-directory)).

---

## 1. Objective

### 1.1 Objectives

After completing these labs you will be able to:

1. Install Liberty from the **kernel zip**, create a server, and add only the features you need.
2. Deploy an application by dropping a WAR into `dropins/`, and enable the **Admin Center** to manage the server.
3. Use the **Liberty Maven plugin** and **dev mode** (`liberty:dev`) to run an application and apply `server.xml` changes live, without restarting.
4. Package the application and server configuration into a **container image** with Podman and run it locally.

Key concepts covered: Liberty directory layout, `server.xml`, feature manager (`featureUtility`), `dropins/` hot deployment, MicroProfile Health, dev mode, container images based on `icr.io/appcafe/open-liberty`.

### 1.2 Lab details

```text
Lab 1                     Lab 2                       Lab 3
Zip install        --->   Maven dev mode       --->   Container image
(bare Liberty)            (live coding)               (Podman)
```

#### Lab 1 — Liberty Kernel: install, configure and run

- **Focus:** the administrator view of Liberty, built up from a minimal runtime.
- **What you do:** unzip the kernel, create the `mylibertyserver` server, install `webProfile-11.0` with `featureUtility`, apply `server.xml`, start the server, deploy `server-info.war` through `dropins/`, then enable and open the Admin Center.
- **Result:** a running server with an application and a management console.
- **Tools:** `server`, `featureUtility`, `productInfo`, browser.
- **Duration:** about 40 minutes.

#### Lab 2 — Developer productivity with Maven and dev mode

- **Focus:** the developer view of Liberty and the inner development loop.
- **What you do:** clone the Open Liberty *Getting Started* guide, run it with `liberty:run`, switch to `liberty:dev`, enable `mpHealth` in `server.xml`, and watch `/health` change from 404 to `UP` without a restart.
- **Result:** hands-on experience of live configuration and code reloading.
- **Tools:** Git, Maven wrapper (`./mvnw`), `curl`, a text editor.
- **Duration:** about 25 minutes.

#### Lab 3 — Containerizing the application with Podman

- **Focus:** moving the same server and application into a container.
- **What you do:** test a bare-Liberty baseline, review the `Dockerfile`, build the `liberty-server-info:1.0` image, run it as `server-info-app`, and compare the result with Lab 1.
- **Result:** a portable image running the same application on port 9080.
- **Tools:** Podman, `Dockerfile`, browser.
- **Duration:** about 25 minutes.

> **Order matters.** Lab 3 reuses the server you build in Lab 1. Do the labs in order, or complete Lab 1 steps 1.1 to 1.12 before starting Lab 3.

---

## 2. Environment preparation

Do all of section 2 once, before Lab 1.

### 2.1 Install the prerequisites

Before installing, check if you already have the required tools installed on your system:

| Tool | Version | Verification command | Needed for |
|---|---|---|---|
| Java JDK | **17 or later** (Java 17 or 21) | `java -version` | Labs 1, 2 |
| Podman | 4.x or later | `podman --version` | Lab 3 |
| Git | any recent | `git --version` | Setup, Lab 2 |
| curl | any | `curl --version` | Lab 2 |
| unzip | any | `unzip -v` | Lab 1 |
| tree *(optional, for display)* | any | `tree --version` | Lab 1 |
| Web browser | any modern browser | n/a | All labs |

> **Note:** If `java -version` reports Java 17 or 21 (Temurin, IBM Semeru, or OpenJDK) and `podman --version` is already available, you do **not** need to reinstall them. Proceed to [Section 2.2](#22-choose-your-lab-home-directory).

---

#### Detailed Installation Guide

##### 1. Java JDK (Version 17 or 21)

Any standard Java 17+ distribution works (e.g. Eclipse Temurin, IBM Semeru Runtime, OpenJDK):

* **macOS (using Homebrew):**
  ```bash
  brew install --cask temurin@17
  ```
  *(Or if using **SDKMAN!**: `sdk install java 17.0.15-sem` or `sdk use java 17.0.15-sem`)*

* **Ubuntu / Debian / WSL2 (Windows):**
  ```bash
  sudo apt update
  sudo apt install -y openjdk-17-jdk
  ```

* **Direct download:** Download from [Adoptium (Eclipse Temurin)](https://adoptium.net) or [IBM Semeru Runtimes](https://developer.ibm.com/languages/java/semeru-runtimes/).

* **Verification:**
  ```bash
  java -version
  ```
  *Ensure the output indicates version 17 or 21.*

---

##### 2. Podman & CLI Tools

Podman is used in Lab 3 for containerizing the application.

* **macOS:**
  ```bash
  brew install git tree podman
  ```
  *(Alternative: install [Podman Desktop](https://podman-desktop.io/) which bundles Podman CLI and GUI)*

  > **Important for macOS users:** Because macOS is not Linux, Podman requires a lightweight virtual machine. Initialize and start it once:
  > ```bash
  > podman machine init
  > podman machine start
  > ```

* **Ubuntu / Debian / WSL2 (Windows):**
  *(Windows users: open an **Ubuntu** WSL2 terminal and run all commands inside it)*
  ```bash
  sudo apt update
  sudo apt install -y git curl unzip tree podman
  ```
  *(On native Linux / WSL2, Podman runs natively without needing `podman machine init`)*

* **Verification:**
  ```bash
  podman --version
  podman info | head -5
  ```

### 2.2 Choose your lab home directory

All lab files, the Liberty installation and the Lab 2 project will live under **one folder** that you choose. This keeps your laptop tidy and makes cleanup easy.

**Choose a location** that:

- you can write to (no `sudo` needed),
- has at least **3 GB** of free space (Liberty, features, Maven downloads, container images),
- has **no spaces** in the path (for example, `~/liberty-labs`, not `~/My Documents/liberty labs`).

The default suggestion is `~/liberty-labs`. You can use any other path.

Create it and store its path in a variable called `LAB_HOME`:

```bash
# Change the path on the next line if you want a different location
export LAB_HOME="$HOME/liberty-labs"

mkdir -p "$LAB_HOME"
cd "$LAB_HOME"
pwd
```

**Expected:** `pwd` prints the full path of your lab folder, for example `/Users/jane/liberty-labs`.

Make the variable available in every future terminal. Run **one** of the following, depending on your shell (`echo $SHELL` tells you which):

```bash
# zsh (default on macOS)
echo "export LAB_HOME=\"$LAB_HOME\"" >> ~/.zshrc

# bash (default on most Linux distributions and WSL2)
echo "export LAB_HOME=\"$LAB_HOME\"" >> ~/.bashrc
```

> From now on, **whenever you open a new terminal**, start with:
>
> ```bash
> cd "$LAB_HOME"
> ```
>
> If the variable is empty (`echo "$LAB_HOME"` prints nothing), run the `export LAB_HOME=...` line above again.

### 2.3 Download the lab files and the Liberty kernel

**Step A — get the lab files from this repository** (<https://github.com/sebasporro/LibertyBasics>):

```bash
cd "$LAB_HOME"
git clone https://github.com/sebasporro/LibertyBasics.git lab-repo
```

All lab files stay inside the cloned repository, in the `lab-repo/Assets/` folder. They are **not** copied anywhere else. The labs refer to them by the path `lab-repo/Assets/<file>`, always from `LAB_HOME`. Make the cleanup script executable:

```bash
chmod +x lab-repo/Assets/cleanup.sh
```

| File (in `lab-repo/Assets/`) | Purpose |
|---|---|
| `server.xml` | Basic server configuration with the `webProfile-11.0` feature (Labs 1, 3) |
| `server.xml.admin` | Same configuration plus `adminCenter-1.0`, a user registry and the administrator role (Lab 1) |
| `server-info.war` | Sample application (Labs 1, 3) |
| `Dockerfile` | Container build definition (Lab 3) |
| `cleanup.sh` | Interactive cleanup script (section 7) |

**Step B — download the Liberty kernel zip.** The kernel is not stored in this repository. Download it yourself:

- **Open Liberty** (free, open source): go to <https://openliberty.io/start/> or <https://openliberty.io/downloads/>, open *All GA Releases*, and download the **Kernel** package (`openliberty-kernel-<version>.zip`) of the latest release, or of the version your instructor tells you.
- **WebSphere Liberty** (requires an IBM entitlement): download the kernel zip from your IBM download source. The labs were written with `wlp-kernel-26.0.0.8.zip`.

> **Where the zip must be placed:** directly in the root of `LAB_HOME` (for example `~/liberty-labs/openliberty-kernel-<version>.zip`), **next to** the `lab-repo/` folder. Not inside `lab-repo/`, not inside `lab-repo/Assets/`, and not left in your browser's `Downloads` folder. Step 1.2 runs `unzip` from `LAB_HOME`, so the zip must be there **before** you unzip it, and the `wlp/` folder will be created next to it.
>
> ```text
> $LAB_HOME/
> ├── lab-repo/
> └── openliberty-kernel-<version>.zip    <-- place the downloaded zip here
> ```
>
> Browsers save files to `Downloads` by default. Move the file into `LAB_HOME` after downloading (adjust the file name to match yours):
>
> ```bash
> mv ~/Downloads/openliberty-kernel-*.zip "$LAB_HOME"/
> # WebSphere Liberty users: mv ~/Downloads/wlp-kernel-*.zip "$LAB_HOME"/
> ```

All steps are identical for both. Once the zip is in `LAB_HOME`, tell the shell the exact name of the file:

```bash
cd "$LAB_HOME"
ls *.zip
# Replace the name below with the file name printed by the command above
export LIBERTY_ZIP="openliberty-kernel-26.0.0.8.zip"
echo "export LIBERTY_ZIP=\"$LIBERTY_ZIP\"" >> ~/.zshrc    # use ~/.bashrc if you use bash
```

> If the Liberty version you download is different from the version in the lab text, the command output will differ slightly. This is expected.

### 2.4 Free the lab ports

The labs use port **9080** (HTTP) and **9443** (HTTPS and Admin Center). Check that nothing is listening on them:

```bash
lsof -i tcp:9080 -i tcp:9443
```

**Expected:** no output (the ports are free). If a process is listed, stop it before continuing.

### 2.5 Podman machine (macOS and Windows only)

On macOS, Podman runs containers inside a small virtual machine. Create and start it once. **Linux and WSL2 users can skip this step.**

```bash
podman machine init
podman machine start
podman info | head -5
```

If `podman machine init` says the machine already exists, run only `podman machine start`.

### 2.6 Network access

The labs download content from the internet: Liberty features and Maven artifacts (Labs 1, 2), the Open Liberty Getting Started project from GitHub (Lab 2), and the `icr.io/appcafe/open-liberty` base image (Lab 3). Make sure you can reach `repo.maven.apache.org`, `github.com` and `icr.io`. If you are behind a corporate proxy, see [Troubleshooting](#6-troubleshooting).

### 2.7 Environment check

Run this block. Every command must succeed before you start Lab 1.

```bash
cd "$LAB_HOME"
echo "LAB_HOME=$LAB_HOME"
echo "LIBERTY_ZIP=$LIBERTY_ZIP"
java -version
git --version
curl --version | head -1
unzip -v | head -1
podman --version
ls -l "$LIBERTY_ZIP" lab-repo/Assets/server.xml lab-repo/Assets/server.xml.admin lab-repo/Assets/server-info.war lab-repo/Assets/Dockerfile lab-repo/Assets/cleanup.sh
```

**Expected:**

- `LAB_HOME` and `LIBERTY_ZIP` are both printed with a value.
- Java reports version 17 or later.
- `ls -l` lists all six files without `No such file` errors.

> Do not leave a `wlp/` folder from a previous attempt in `LAB_HOME`. `unzip` would merge into it. If one exists, run `rm -rf "$LAB_HOME/wlp"` before Lab 1.

---

## 3. Lab 1 — Liberty Kernel: install, configure and run

**Goal:** install Liberty from a zip, build up a server by adding features, deploy an application, and enable the Admin Center.

**Terminal:** one terminal is enough (a second one is optional for following the log).

Start every session of this lab with:

```bash
cd "$LAB_HOME"
```

### Step 1.1 — Inspect the downloaded kernel zip

```bash
ls -lh "$LIBERTY_ZIP"
```

**Expected:** a file of roughly 15–20 MB. The kernel distribution is a minimal runtime. It contains no optional features. They are installed on demand from the Liberty repository.

### Step 1.2 — Expand the zip

> The zip must already be in `LAB_HOME` (see section 2.3, Step B), next to `lab-repo/`. Run `unzip` from `LAB_HOME`, so that `wlp/` is created there.

```bash
unzip "$LIBERTY_ZIP" -x "__MACOSX/*" "*/.DS_Store"
```

**Expected:** many `inflating:` lines, and a new `wlp` folder in `LAB_HOME`.

### Step 1.3 — Explore the directory layout

```bash
tree -L 1 wlp
```

(No `tree`? Use `ls wlp` instead.)

| Directory | Contents |
|---|---|
| `bin/` | Command-line tools: `server`, `featureUtility`, `productInfo` |
| `lib/` | Runtime libraries |
| `templates/` | Server configuration templates |
| `usr/` | **Your** servers and shared resources. This is the only place you normally change. |

### Step 1.4 — Create a server

```bash
./wlp/bin/server create mylibertyserver
```

**Expected:** `Server mylibertyserver created.`

### Step 1.5 — Explore the server directory

```bash
tree -L 2 wlp/usr/servers/mylibertyserver
```

Look for `server.xml` (configuration) and `dropins/` (hot-deploy folder). The `logs/` folder appears after the first start.

### Step 1.6 — Review the features available

```bash
./wlp/bin/productInfo featureinfo
```

Only a few core features are listed. Remember the list so you can compare it in the next step.

### Step 1.7 — Install the Web Profile feature set

```bash
./wlp/bin/featureUtility installFeature webProfile-11.0
```

Accept the license prompt if one appears (type `y`, then Enter). Then list the features again:

```bash
./wlp/bin/productInfo featureinfo
```

**Expected:** a much longer list than in step 1.6. `featureUtility` downloaded many features from Maven Central.

### Step 1.8 — Apply the server configuration

```bash
cp ./lab-repo/Assets/server.xml ./wlp/usr/servers/mylibertyserver/server.xml
cat ./wlp/usr/servers/mylibertyserver/server.xml
```

Key elements to review:

| Element | Meaning |
|---|---|
| `<featureManager>` | Lists the features the server loads (here `webProfile-11.0`) |
| `<httpEndpoint>` | HTTP port 9080 and HTTPS port 9443 |
| `<applicationManager autoExpand="true"/>` | Expands WAR/EAR files on deployment |
| `<ssl>` | Default SSL configuration trusting the JVM's default certificates |

### Step 1.9 — Start the server

```bash
./wlp/bin/server start mylibertyserver
```

**Expected:** `Server mylibertyserver started with process ID <number>.`

Follow the log (optional, in **Terminal 2**; press `Ctrl+C` to leave `tail`):

```bash
cd "$LAB_HOME"
tail -f ./wlp/usr/servers/mylibertyserver/logs/messages.log
```

Look for `CWWKF0011I: The server mylibertyserver is ready to run a smarter planet` and for the HTTP/HTTPS port messages (`CWWKO0219I`).

### Step 1.10 — Verify the server

Open <http://localhost:9080> in your browser. No application is deployed yet, so you may see a 404 page or a default welcome page. Either way, it confirms that Liberty is listening on port 9080.

Command-line alternative:

```bash
curl -I http://localhost:9080
```

### Step 1.11 — Deploy the sample application

```bash
cp ./lab-repo/Assets/server-info.war ./wlp/usr/servers/mylibertyserver/dropins/server-info.war
```

Liberty monitors `dropins/` and deploys the WAR automatically. Check the log:

```bash
grep -E "CWWKZ0001I|CWWKT0016I" ./wlp/usr/servers/mylibertyserver/logs/messages.log
```

**Expected:** `CWWKZ0001I: Application server-info started` and a line with the URL `http://localhost:9080/server-info/`.

### Step 1.12 — Test the application

Open <http://localhost:9080/server-info>. The context root comes from the WAR file name.

### Step 1.13 — Enable the Admin Center

```bash
diff ./lab-repo/Assets/server.xml ./lab-repo/Assets/server.xml.admin
cp ./lab-repo/Assets/server.xml.admin ./wlp/usr/servers/mylibertyserver/server.xml
./wlp/bin/featureUtility installServerFeatures mylibertyserver
```

The `diff` output shows the changes:

| Change | Why |
|---|---|
| `adminCenter-1.0` feature | The web console |
| `host="*"` on `httpEndpoint` | Allows access from outside `localhost` |
| `<basicRegistry>` with user `admin` | The Admin Center requires a user registry |
| `<administrator-role>` | Gives the `admin` user the administrator role |

> The credentials `admin` / `adminpwd` are for **lab use only**. Never use hard-coded passwords outside a training environment.

### Step 1.14 — Restart the server

```bash
./wlp/bin/server stop mylibertyserver
./wlp/bin/server start mylibertyserver
```

### Step 1.15 — Open the Admin Center

Open <https://localhost:9443/adminCenter>. Your browser will warn about a self-signed certificate. Accept it for the lab. Log in with **admin** / **adminpwd**. Explore the *Explore* tool, then open the `server-info` application.

### Step 1.16 — Stop the server

You must free port 9080 before Lab 2.

```bash
./wlp/bin/server stop mylibertyserver
```

**Expected:** `Server mylibertyserver stopped.`

Keep the `wlp` folder. Lab 3 reuses it.

### Lab 1 checkpoint

- [ ] Server `mylibertyserver` started and answered on port 9080
- [ ] `server-info` responded at `/server-info`
- [ ] Admin Center login succeeded on port 9443
- [ ] Server stopped (`./wlp/bin/server status mylibertyserver` prints `Server mylibertyserver is not running.`)

**Discussion questions**

1. Why install `webProfile-11.0` separately instead of shipping it in the zip?
2. What would happen if you removed `<feature>webProfile-11.0</feature>` from `server.xml` while the server was running?

---

## 4. Lab 2 — Developer productivity with Maven and dev mode

**Goal:** run the Open Liberty *Getting Started* guide with the Liberty Maven plugin, then use dev mode to enable a feature live.

**Terminals:** Terminal 1 runs the server. Terminal 2 sends test requests.

**Before you start:** the Lab 1 server must be stopped (`"$LAB_HOME/wlp/bin/server" status mylibertyserver` must report not running), otherwise port 9080 is busy.

### Step 2.1 — Clone the project (Terminal 1)

```bash
cd "$LAB_HOME"
mkdir -p lab2
cd lab2
git clone https://github.com/openliberty/guide-getting-started.git
```

### Step 2.2 — Move into the `start` directory (Terminal 1)

```bash
cd "$LAB_HOME/lab2/guide-getting-started/start"
pwd
```

All Maven commands in this lab run from this folder in **Terminal 1** and **Terminal 2**. The project is a Jakarta EE / MicroProfile WAR built with the Maven wrapper (`./mvnw`), so you do not need to install Maven.

### Step 2.3 — Start Liberty with Maven (Terminal 1)

```bash
./mvnw liberty:run
```

The first run takes a few minutes: it downloads Maven, compiles the project, downloads Liberty and installs the features listed in `src/main/liberty/config/server.xml`. Leave this terminal running.

**Expected:** the log ends with `CWWKF0011I: The server defaultServer is ready to run a smarter planet`.

### Step 2.4 — Test the system properties endpoint (Terminal 2)

Open a **new terminal** and run:

```bash
curl http://localhost:9080/system/properties
```

**Expected:** a JSON document with all JVM system properties.

### Step 2.5 — Stop the server (Terminal 2)

```bash
cd "$LAB_HOME/lab2/guide-getting-started/start"
./mvnw liberty:stop
```

**Expected:** Terminal 1 returns to the prompt, and Terminal 2 prints `BUILD SUCCESS`.

### Step 2.6 — Start dev mode (Terminal 1)

```bash
./mvnw liberty:dev
```

Dev mode keeps the server running and watches your source files, configuration and dependencies. Changes are compiled and applied automatically. Wait until the log shows `Press the Enter key to run tests on demand.` Leave this terminal running.

### Step 2.7 — Check that the health endpoint does not exist yet (Terminal 2)

```bash
curl -i http://localhost:9080/health
```

**Expected:** `HTTP/1.1 404 Not Found`, because the MicroProfile Health feature is not enabled.

> If you get `200 OK` instead, the project already enables `mpHealth`. Remove the `<feature>mpHealth</feature>` line from `src/main/liberty/config/server.xml`, wait for dev mode to apply the change, and run the command again.

### Step 2.8 — Enable MicroProfile Health

Open this file in any text editor:

```
$LAB_HOME/lab2/guide-getting-started/start/src/main/liberty/config/server.xml
```

Add this line inside the `<featureManager>` block, with the other `<feature>` lines:

```xml
<feature>mpHealth</feature>
```

Save the file and watch **Terminal 1**. Dev mode reports that the server configuration was updated. **No restart is needed.**

### Step 2.9 — Test the health endpoint again (Terminal 2)

```bash
curl http://localhost:9080/health
```

**Expected:** JSON containing `"status":"UP"`.

### Step 2.10 — Optional: live code change

1. Open this file in your editor:

   ```
   $LAB_HOME/lab2/guide-getting-started/start/src/main/java/io/openliberty/sample/system/SystemResource.java
   ```

2. Make a small change (for example, change the `description` text of `@Timed`) and save.
3. Watch **Terminal 1**: dev mode recompiles and redeploys the application.
4. Repeat the `curl` command from step 2.4.

### Step 2.11 — Stop dev mode (Terminal 1)

Type `q` and press Enter, or press `Ctrl+C`.

**Expected:** the server stops and you get your prompt back. Check that port 9080 is free:

```bash
lsof -i tcp:9080
```

### Lab 2 checkpoint

- [ ] `/system/properties` returned JSON
- [ ] `/health` returned 404 before and `UP` after the `server.xml` change
- [ ] No restart was needed between the two
- [ ] Dev mode stopped and port 9080 is free

**Discussion questions**

1. What are the differences between `liberty:run` and `liberty:dev`?
2. Which file defines which Liberty features this application needs?

---

## 5. Lab 3 — Containerizing the application with Podman

**Goal:** build an image with the Liberty runtime and the `server-info` application, run it as a container, and compare it with the installation from Lab 1.

**Terminal:** one terminal.

**Prerequisites:** the `wlp` folder from Lab 1 (steps 1.1 to 1.12 at least), Podman installed (and the Podman machine started on macOS/Windows), and port 9080 free.

Start with:

```bash
cd "$LAB_HOME"
```

### Step 3.1 — Test the application on bare Liberty (baseline)

Lab 1 left the Admin Center configuration in the server. Go back to the basic configuration so the baseline matches what goes into the container, make sure the application is deployed, and start the server:

```bash
cp ./lab-repo/Assets/server.xml ./wlp/usr/servers/mylibertyserver/server.xml
cp ./lab-repo/Assets/server-info.war ./wlp/usr/servers/mylibertyserver/dropins/server-info.war
./wlp/bin/server start mylibertyserver
```

Open <http://localhost:9080/server-info> and note the information shown (Java version, OS, Liberty version). You will compare it later.

### Step 3.2 — Stop the bare Liberty server

Port 9080 must be free for the container.

```bash
./wlp/bin/server stop mylibertyserver
```

### Step 3.3 — Confirm Podman works

```bash
podman --version
podman info | head -5
```

On macOS/Windows, if `podman info` fails, run `podman machine start` (see section 2.5).

### Step 3.4 — Review the Dockerfile

```bash
cat lab-repo/Assets/Dockerfile
```

**Expected content:**

```dockerfile
FROM icr.io/appcafe/open-liberty:kernel-slim-java17-openj9-ubi

COPY --chown=1001:0 server.xml /config/server.xml
RUN features.sh
COPY --chown=1001:0 server-info.war /config/dropins/server-info.war
RUN configure.sh
```

| Instruction | Meaning |
|---|---|
| `FROM ...kernel-slim-java17-openj9-ubi` | Base image: Liberty kernel only, Java 17 (OpenJ9), Red Hat UBI |
| `COPY server.xml /config/server.xml` | Same server configuration used in Lab 1 |
| `RUN features.sh` | Installs only the features declared in `server.xml` |
| `COPY server-info.war /config/dropins/` | Same dropins deployment as Lab 1 |
| `RUN configure.sh` | Final image tuning (shared class cache, etc.) |
| `--chown=1001:0` | Files owned by the non-root user the container runs as |

### Step 3.5 — Build the image

Build from the `./Assets` folder, where the `Dockerfile`, `server.xml` and `server-info.war` are. Using it as the build context keeps the image build small (it does not send `wlp/` or the Liberty zip to Podman):

```bash
podman build -t liberty-server-info:1.0 lab-repo/Assets
```

The first build downloads the base image and the features, so it takes a few minutes. **Expected:** the last lines show `Successfully tagged localhost/liberty-server-info:1.0`.

> The image uses the basic `server.xml` (`webProfile-11.0`) from `lab-repo/Assets`. The Admin Center version is a separate file (`server.xml.admin`) and is never used here.

### Step 3.6 — Verify the image

```bash
podman images
```

**Expected:** `liberty-server-info` with tag `1.0` is listed.

### Step 3.7 — Run the container

```bash
podman run -d --name server-info-app -p 9080:9080 liberty-server-info:1.0
```

**Expected:** a long container ID is printed.

### Step 3.8 — Confirm the container is running

```bash
podman ps
podman logs server-info-app | tail -5
```

**Expected:** `podman ps` shows `server-info-app` with status `Up`. The log contains `CWWKF0011I ... ready to run a smarter planet` (wait a few seconds and repeat if it is not there yet).

### Step 3.9 — Test the containerized application

Open <http://localhost:9080/server-info> and compare it with the baseline from step 3.1. The Java version, OS and Liberty details are those of the container image, not of your laptop.

### Lab 3 checkpoint

- [ ] Image `liberty-server-info:1.0` is built
- [ ] Container `server-info-app` is running
- [ ] `/server-info` responds and shows different OS details than on bare Liberty

**Discussion questions**

1. What is the benefit of `RUN features.sh` over copying a full Liberty installation into the image?
2. How would you pass a different HTTP port or password to the container without rebuilding the image?

---

## 6. Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `LAB_HOME` or `LIBERTY_ZIP` is empty | New terminal without the variables | Run the `export` lines from sections 2.2 and 2.3 again |
| `No such file or directory` for a lab file | Wrong current folder | `cd "$LAB_HOME"` and run `ls` |
| `Address already in use`, or the browser shows the wrong app | Another process uses port 9080 or 9443 | `lsof -ti tcp:9080`, then `kill <pid>`; or stop the previous server or container |
| `unzip` merges into an old `wlp/` | Left over from a previous run | `rm -rf "$LAB_HOME/wlp"` and unzip again |
| `featureUtility` cannot connect | No internet, or a proxy is required | Check your network. For a proxy, set `proxyHost`, `proxyPort`, `proxyUser` and `proxyPassword` in `$LAB_HOME/wlp/etc/featureUtility.properties` |
| `./mvnw` cannot download Maven or dependencies | No internet, or a proxy is required | Configure `HTTP_PROXY`/`HTTPS_PROXY`, or the `.mvn/settings` for your proxy |
| Java version error at startup | JDK older than 17, or `JAVA_HOME` points to an old JDK | Install JDK 17+ and set `JAVA_HOME` |
| `git clone` says the destination already exists | Folder `guide-getting-started` already exists | Work inside `$LAB_HOME/lab2`, or delete the old folder |
| `./mvnw: Permission denied` | Wrapper lost its execute bit | `chmod +x "$LAB_HOME/lab2/guide-getting-started/start/mvnw"` |
| `/health` returns 200 in step 2.7 | `mpHealth` already enabled in the cloned `server.xml` | Remove the `mpHealth` feature, save, and retest |
| `Cannot connect to Podman` | Podman machine not running (macOS/Windows) | `podman machine start` |
| `podman run` fails with `name already in use` | Old container exists | `podman rm -f server-info-app` |
| Container starts but the browser cannot connect | Port mapping missing or port already used | Use `-p 9080:9080`; check `podman ps` and `lsof -i tcp:9080` |
| Browser warns about the certificate | Liberty uses a generated self-signed certificate | Accept the warning (lab only) |

---

## 7. Final cleanup

When you finish the labs, run the cleanup script **from `LAB_HOME`**, using its path inside the repository. It is an interactive menu:

```bash
cd "$LAB_HOME"
./lab-repo/Assets/cleanup.sh
```

| Option | Action |
|---|---|
| 1 | Stops and removes the lab container and image (`server-info-app`, `liberty-server-info:1.0`) and any other Liberty container |
| 2 | Removes the `wlp/` directory of the **current folder** |
| 3 | Kills any process on ports 9080, 9081 and 9443 |
| 4 | All of the above |
| 5 | Exit |

> **Warning:** options 3 and 4 use `kill -9` on whatever listens on those ports, including programs unrelated to the labs. Option 1 also removes **every** container whose image name contains `open-liberty`, `websphere-liberty` or `liberty-`. Option 2 deletes `./wlp` relative to the folder you run the script from, so always run it from `LAB_HOME`.

Manual alternative:

```bash
cd "$LAB_HOME"
podman rm -f server-info-app
podman rmi liberty-server-info:1.0
./wlp/bin/server stop mylibertyserver 2>/dev/null
rm -rf wlp lab2 lab-repo
```

To remove everything, including the downloaded files, delete the whole lab folder. **Double-check the path first, because this cannot be undone:**

```bash
echo "$LAB_HOME"
rm -rf "$LAB_HOME"
```

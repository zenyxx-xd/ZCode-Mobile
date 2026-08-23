<div align="center">
  <h1>🚀 ZCode Mobile</h1>

  <p>
    <strong>A high-performance, native-accelerated, full-screen GUI for ZCode IDE on Android.</strong>
  </p>

  <p>
    <a href="README_ru.md">🇷🇺 Русский</a> | 
    <strong>🇬🇧 English</strong>
  </p>

  <p>
    <img alt="Version" src="https://img.shields.io/badge/version-1.0.0-blue.svg?cacheSeconds=2592000" />
    <img alt="Platform" src="https://img.shields.io/badge/platform-Termux%20X11-lightgrey" />
    <img alt="GPU" src="https://img.shields.io/badge/acceleration-Turnip%20%7C%20Zink-success" />
    <img alt="License" src="https://img.shields.io/badge/license-MIT-green" />
  </p>
</div>

---

## ⚡ Quick Install

**Prerequisite:** Ensure you have the [Termux-X11 Android APK](https://github.com/termux/termux-x11/releases) installed on your device.

Copy and paste the following one-line command into your Termux terminal to install or update ZCode Mobile:

```bash
curl -sL https://raw.githubusercontent.com/zenyxx-xd/ZCode-Mobile/main/install.sh | bash
```

> **Note:** The installer automatically provisions the Debian subsystem, configures Turnip/Zink GPU acceleration drivers, and deploys the unified mobile launcher.

---

## 🌟 Key Features

* **🖥️ Full-Screen Kiosk Mode:** Strips away titlebars and window borders using Matchbox Window Manager for a clean, distraction-free IDE experience.
* **⚡ Native GPU Acceleration:** Configured with Mesa Turnip + Zink hardware drivers, multithreaded OpenGL dispatch (`MESA_GLTHREAD`), zero-copy rendering, and hardware-accelerated 2D canvas.
* **🔑 Integrated OAuth Login Helper:** Detects authorization state automatically. If unauthenticated, simply press `[A]` in the terminal to paste your callback URL or let it auto-detect from the Android clipboard.
* **🔄 Seamless Auto-Updates:** Includes a native `pkexec` bridge so in-app Electron updates (`Restart to update`) install and apply smoothly without manual intervention.
* **📱 Mobile-Optimized DPI (2.5x Scale):** Balanced scaling configured across Electron, GTK-3.0 dialogs, and X11 fonts for crisp readability on high-DPI smartphone displays.
* **🌐 Universal Browser Bridge:** Clicking web links and login buttons directly triggers the Android browser via Activity Manager integration.
* **🔄 Unified Storage Profile:** Credentials, extensions, and settings are shared seamlessly whether launching from the Termux host or inside PRoot Debian.

---

## 🚀 Usage & Commands

Once installed, simply run:

```bash
zcode
```

### Command-line Options

| Flag | Description |
| :--- | :--- |
| `zcode` | Launch ZCode IDE (Auto-selects optimal VirGL / Zink hardware acceleration) |
| `zcode --virgl` | Force VirGL Native Android GPU Acceleration (Optimized for Snapdragon 8 Elite / Adreno 8xx) |
| `zcode --zink` | Force Turnip + Zink Native Vulkan driver |
| `zcode --software` | Fallback mode using LLVMpipe CPU software rasterizer |
| `zcode --debug` | Run in foreground with verbose Electron logging |
| `zcode --full-delete` | Completely remove ZCode IDE and its configurations |
| `zcode --proot-reset` | Reset the Debian PRoot container |

---

## 📱 Requirements

* **Android OS:** Android 10 or newer (ARM64 / x86_64)
* **Termux App:** [F-Droid](https://f-droid.org/en/packages/com.termux/) or [GitHub Releases](https://github.com/termux/termux-app/releases)
* **Termux:X11 App:** [GitHub Releases](https://github.com/termux/termux-x11/releases)
* **Storage:** At least 2.5 GB free space for Debian rootfs and IDE packages

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

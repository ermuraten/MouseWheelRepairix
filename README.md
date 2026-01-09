# MouseWheelRepairix

<p align="center">
  <img src="MouseIcon.png" alt="MouseWheelRepairix Icon" width="128">
</p>

**Fix erratic mouse wheel scrolling on macOS** – A lightweight menu bar utility that debounces misbehaving scroll wheel events.

## 🎯 The Problem

Does your mouse scroll wheel sometimes:
- Jump in the wrong direction?
- Register multiple clicks for a single scroll?
- Behave erratically, especially when scrolling slowly?

This is often caused by a dirty or worn scroll wheel encoder. MouseWheelRepairix fixes this in software!

## ✨ Features

- 🖱️ **Debounce scroll events** – Filters out erratic double-triggers
- ⚙️ **Configurable timing** – 50ms, 100ms, 200ms presets or custom values
- 📊 **Measurement tool** – Analyze your wheel's behavior to find optimal settings
- 🚀 **Start at login** – Set it and forget it
- 🌙 **Menu bar app** – Stays out of your way

## 📥 Installation

1. Download the latest `.dmg` from [Releases](https://github.com/ermuraten/MouseWheelRepairix/releases)
2. Open the DMG and drag the app to Applications
3. Launch from Applications folder
4. Grant Accessibility permissions when prompted (required to intercept scroll events)

## 🔧 Usage

1. Click the mouse icon in your menu bar
2. Enable "Mouse Wheel Repair"
3. Choose a debounce time (start with 100ms)
4. Use "Measure Wheel Clicks" to fine-tune

### Finding the Right Debounce Time

1. Open the Measurement tool from the menu
2. Scroll slowly and watch the intervals
3. If you see erratic values below 50ms, those are ghost clicks
4. Set your debounce time just above those erratic values

## 🛠️ Building from Source

```bash
# Clone the repository
git clone https://github.com/ermuraten/MouseWheelRepairix.git
cd MouseWheelRepairix

# Build the app
./scripts/build-app.sh

# Or create a DMG
./scripts/build-dmg.sh
```

## 📋 Requirements

- macOS 11.0 (Big Sur) or later
- Accessibility permissions

## 📄 License

MIT License – Feel free to use, modify, and distribute.

---

<p align="center">
  <sub>Made with ❤️ for frustrated mouse owners</sub>
</p>

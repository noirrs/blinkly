# Blinkly 👀

**A macOS menu bar app for healthy eye habits with smart media control**

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.0+-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## ✨ Features

- **🎯 Eye Break Reminders**: 30-second break intervals (demo mode)
- **🎵 Smart Media Control**: Automatically pauses/resumes Spotify, Apple Music, browsers
- **📺 Multi-Screen Support**: Break overlays on all connected displays
- **🖱️ Cursor Tracking**: Floating countdown follows your mouse
- **👁️ Blink Reminders**: Configurable blink and posture reminders
- **📱 Menu Bar Only**: No dock icon, clean menu bar integration

## 🚀 Installation

### Option 1: Download DMG (Recommended)
1. Download `Blinkly-v1.0.2.dmg` from [Releases](../../releases/latest)
2. Open the DMG and drag Blinkly to Applications
3. Launch from Applications or Spotlight

### Option 2: Download ZIP
1. Download `Blinkly-v1.0.2.zip` from [Releases](../../releases/latest)
2. Extract and move `blinkly.app` to Applications
3. Right-click → Open (first time only for security)

## 🎮 Usage

1. **Launch**: Blinkly appears as a menu bar icon (👁️)
2. **Start Break**: Click "Start Break Now" or wait for auto-timer
3. **Settings**: Access via menu bar → "⚙️ Settings..."
4. **Break**: Full-screen overlay with countdown and smart media pause
5. **Resume**: Media automatically resumes after break

## ⚙️ Settings

- **Break Intervals**: Configure break frequency
- **Reminder Types**: Enable/disable blink and posture reminders
- **Media Control**: Automatic pause/resume settings
- **Display Options**: Multi-screen overlay preferences

## 🔧 Technical Details

- **Platform**: macOS 13.0+ (Apple Silicon & Intel)
- **Languages**: Swift, SwiftUI, AppKit
- **Media Integration**: AppleScript for Spotify, Apple Music, browsers
- **Architecture**: Async media detection, reactive state management

## 🛠️ Development

### Building from Source
```bash
git clone https://github.com/yourusername/blinkly.git
cd blinkly
open blinkly.xcodeproj
```

### Requirements
- Xcode 15.0+
- macOS 13.0+ deployment target
- Swift 5.0+

## 📝 Release Notes

### v1.0.2 (Latest)
- ✅ Fixed app launch crashes
- ✅ Eliminated unwanted window opening
- ✅ Removed dock item appearance
- ✅ Optimized break overlay performance (instant appearance)
- ✅ Async media detection (no UI blocking)
- ✅ Accurate media state tracking

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 💖 Support

If Blinkly helps your eye health, consider:
- ⭐ Starring the repository
- 🐛 Reporting bugs via Issues
- 💡 Suggesting features
- 🔄 Sharing with others

---

**Made with ❤️ for healthier screen time**

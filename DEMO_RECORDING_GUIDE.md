# Demo Recording Guide

**Date:** November 13, 2025  
**Feature:** Automated demo video and GIF generation for GitHub

---

## 🎯 Overview

Create professional demo videos and GIFs to showcase your Whisker test suite on GitHub. All scripts are fully automated and optimized for GitHub's requirements.

---

## 🚀 Quick Start

### The Easiest Way: Automated Demo Generation

```bash
# Record smoke tests and create GitHub-ready GIF
./generate_demo.sh

# That's it! You'll get:
# - High-quality MP4 video
# - Optimized GIF (< 10MB for GitHub)
# - README markdown snippet to copy/paste
```

---

## 📦 Available Scripts

### 1. `generate_demo.sh` - All-in-One Solution (Recommended)

**What it does:**
- Records Android emulator screen
- Runs your test suite automatically
- Creates optimized GIF for GitHub
- Generates README markdown

**Usage:**
```bash
# Default: smoke tests, headless mode
./generate_demo.sh

# RECOMMENDED: 10x speed for long tests
./generate_demo.sh --speed 10

# Record organized tests at 5x speed
./generate_demo.sh --suite organized --speed 5

# Show Maestro UI during recording
./generate_demo.sh --with-ui

# Custom recording time
./generate_demo.sh --time 120

# Full test suite at 10x speed (makes 20 min test = 2 min GIF!)
./generate_demo.sh --suite all --speed 10
```

**💡 Speed Feature (NEW!):**
- Use `--speed N` to speed up the GIF by Nx
- **Recommended: `--speed 10`** - Makes long tests watchable
- Benefits:
  - 3 minute test → 18 second GIF!
  - Dramatically smaller file size
  - More engaging for viewers
  - Shows full test flow quickly

**Output:**
```
demo_videos/
├── whisker_test_20251113_143022.mp4   # Full quality video
└── whisker_test_demo.gif               # GitHub-ready GIF
```

---

### 2. `record_screen.sh` - Simple Screen Recording

**What it does:**
- Records whatever is on the Android emulator
- No automatic test running
- Perfect for manual demonstrations

**Usage:**
```bash
# Start recording, then run tests manually
./record_screen.sh

# Record for 1 minute
./record_screen.sh --time 60

# Custom output file
./record_screen.sh --output my_demo.mp4
```

**When to use:**
- Manual test demonstrations
- Recording specific UI flows
- Creating custom walkthroughs

---

### 3. `video_to_gif.sh` - Video Conversion

**What it does:**
- Converts any video to optimized GIF
- Automatically checks GitHub size limits
- Suggests optimizations if too large

**Usage:**
```bash
# Convert with optimal defaults
./video_to_gif.sh my_video.mp4

# Speed up by 10x (RECOMMENDED for long tests!)
./video_to_gif.sh my_video.mp4 --speed 10

# Speed up by 5x with high quality
./video_to_gif.sh my_video.mp4 --speed 5 --fps 20 --width 720

# Custom settings for smaller size
./video_to_gif.sh my_video.mp4 --fps 10 --width 480 --colors 64

# Maximum quality
./video_to_gif.sh my_video.mp4 --fps 20 --width 720 --colors 256

# Combo: speed + compression for large files
./video_to_gif.sh my_video.mp4 --speed 10 --fps 12 --width 480 --colors 64

# Specify output file
./video_to_gif.sh my_video.mp4 --output demo.gif
```

**Optimization Guide:**

| Goal | Settings | Quality |
|------|----------|---------|
| 🏆 Best Overall | `--speed 10 --fps 15 --width 640` | ⭐⭐⭐⭐⭐ Excellent |
| 📦 Small File | `--speed 10 --fps 12 --width 480 --colors 64` | ⭐⭐⭐⭐ Very Good |
| 🎬 High Quality | `--speed 5 --fps 20 --width 720 --colors 256` | ⭐⭐⭐⭐⭐ Stunning |
| ⚡ Super Fast | `--speed 15 --fps 12 --width 540` | ⭐⭐⭐⭐ Great |
| 💾 Tiny Size | `--speed 10 --fps 8 --width 400 --colors 48` | ⭐⭐⭐ Acceptable |

**Speed Recommendations:**
- **--speed 5**: Balanced, easy to follow
- **--speed 10**: ⭐ RECOMMENDED - Fast but clear
- **--speed 15**: Very fast, comprehensive tests
- **--speed 20**: Extreme speed for long suites

---

### 4. `record_terminal.sh` - Terminal Session Recording

**What it does:**
- Records terminal output with asciinema
- Can convert to GIF
- Perfect for CLI demonstrations

**Usage:**
```bash
# Interactive recording (press Ctrl+D to stop)
./record_terminal.sh

# Auto-run a command
./record_terminal.sh ./run_all_tests.sh --suite smoke --headless
```

**Requirements:**
```bash
brew install asciinema agg
```

---

## 🎬 Complete Workflows

### Workflow 1: Quick Demo for GitHub

```bash
# 1. Record automated tests
./generate_demo.sh

# 2. Copy the markdown snippet it generates
# 3. Paste into README.md
# 4. Commit and push

git add demo_videos/whisker_test_demo.gif
git commit -m "Add test demo GIF"
git push
```

**Result:** Professional demo on your GitHub README in minutes!

---

### Workflow 2: Manual UI Demonstration

```bash
# 1. Start recording
./record_screen.sh --time 60

# 2. Manually navigate and test the app
#    (you have 60 seconds)

# 3. Convert to GIF
./video_to_gif.sh demo_videos/recording_*.mp4

# 4. Add to README
```

---

### Workflow 3: Multiple Test Suite Demos

```bash
#!/bin/bash
# record_all_suites.sh

for suite in smoke organized registration; do
    echo "Recording $suite tests..."
    ./generate_demo.sh --suite $suite
    
    # Rename the GIF
    mv demo_videos/whisker_test_demo.gif \
       demo_videos/${suite}_test_demo.gif
    
    sleep 5  # Pause between recordings
done

echo "✅ All demos recorded!"
```

**Result:**
```
demo_videos/
├── smoke_test_demo.gif
├── organized_test_demo.gif
└── registration_test_demo.gif
```

---

## 📋 GitHub README Examples

### Basic Demo

```markdown
## 🎬 Automated Testing

![Whisker Tests](demo_videos/whisker_test_demo.gif)

*Our comprehensive test suite automatically validates all features*
```

### Multiple Demos Table

```markdown
## 🎬 Test Demonstrations

| Test Suite | Status | Demo |
|------------|--------|------|
| Smoke Tests (5 min) | ✅ Passing | ![Smoke](demo_videos/smoke_test_demo.gif) |
| Full Suite (20 min) | ✅ Passing | ![Full](demo_videos/full_test_demo.gif) |
| Registration Flow | ✅ Passing | ![Register](demo_videos/register_demo.gif) |
```

### Detailed Section

```markdown
## 🎬 See It In Action

### Automated Testing Demo

![Whisker Automated Tests](demo_videos/whisker_test_demo.gif)

**What you're seeing:**
- ✅ Automated user registration with random credentials
- ✅ Complete UI navigation testing (Profile, Pets, Shop, Devices, Insights)
- ✅ Login/logout flow validation
- ✅ Screenshot capture at every step
- ✅ Detailed HTML report generation

**Test Suite Stats:**
- 🎯 15+ automated tests
- ⏱️ ~20 minutes total runtime
- 📊 100% success rate
- 🤖 Fully automated with CI/CD

[View Full Test Documentation](COMPLETE_TEST_SUITE.md)
```

---

## 🛠️ Installation & Setup

### Required (Already Have)

- Android Studio + SDK
- Maestro
- Test suite working

### Recommended for GIF Creation

```bash
# ffmpeg (video processing)
brew install ffmpeg

# gifsicle (GIF optimization)
brew install gifsicle
```

### Optional for Terminal Recording

```bash
# asciinema (terminal recording)
brew install asciinema

# agg (terminal to GIF)
brew install agg
```

---

## 🎯 Best Practices

### Recording Quality

**✅ DO:**
- Record in landscape mode
- Keep demos under 60 seconds
- Show successful test runs
- Include test summary/results
- Test on clean emulator state

**❌ DON'T:**
- Show long waiting periods
- Include failed tests (unless demonstrating error handling)
- Record at native resolution (too large)
- Forget to optimize GIFs

### GitHub Optimization

**File Size Limits:**
- GitHub: 10MB for GIFs
- Most browsers: 10-20MB comfortable
- Mobile-friendly: < 5MB

**Recommended Settings:**
- **FPS:** 12-15 (smooth enough, not wasteful)
- **Width:** 540-640px (readable, not huge)
- **Colors:** 100-128 (good quality, reasonable size)
- **Duration:** 30-60s (attention span)

### Demo Content

**Show:**
1. Test execution starting
2. Key test steps (2-3 examples)
3. Test completion
4. Summary/results

**Skip:**
- Long test setup
- Repetitive tests
- Error stack traces
- Debugging output

---

## 🐛 Troubleshooting

### "No device/emulator detected"

```bash
# Check device
adb devices

# Restart ADB
adb kill-server && adb start-server

# Start emulator first
# Android Studio → Device Manager → Start
```

### "GIF too large"

```bash
# Option 1: More aggressive compression
./video_to_gif.sh video.mp4 --fps 10 --width 480 --colors 64

# Option 2: Trim video first
ffmpeg -i video.mp4 -t 30 -c copy trimmed.mp4
./video_to_gif.sh trimmed.mp4

# Option 3: Split into multiple GIFs
ffmpeg -i video.mp4 -t 30 -c copy part1.mp4
ffmpeg -i video.mp4 -ss 30 -t 30 -c copy part2.mp4
```

### "ffmpeg not found"

```bash
# Install ffmpeg
brew install ffmpeg

# Verify installation
ffmpeg -version
```

### "Recording stopped early"

```bash
# Check device storage
adb shell df -h /sdcard

# Clear space if needed
adb shell rm /sdcard/*.mp4
```

### "Can't pull video from device"

```bash
# Check file exists
adb shell ls -lh /sdcard/*.mp4

# Try manual pull
adb pull /sdcard/screenrecord.mp4 ./

# Check ADB connection
adb kill-server && adb start-server
adb devices
```

---

## 📊 Example Output

After running `./generate_demo.sh`, you'll see:

```
╔═══════════════════════════════════════════════════════════════╗
║          🎬 WHISKER TEST DEMO GENERATOR 🎬                    ║
╚═══════════════════════════════════════════════════════════════╝

📱 Device found: emulator-5554

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📹 Starting screen recording (180s max)...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🧪 Running smoke tests...

... tests run ...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⏳ Waiting for recording to finish...
📥 Downloading video from device...
✅ Video saved: demo_videos/whisker_test_20251113_143022.mp4
   File size: 12M
   Duration: 85s

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎨 Converting to GIF for GitHub...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚡ Optimizing GIF size...
✅ GIF created: demo_videos/whisker_test_demo.gif
   File size: 8.2M

✅ GIF is 8MB - Perfect for GitHub!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📁 Files created:
   📹 Video: demo_videos/whisker_test_20251113_143022.mp4 (12M)
   🎨 GIF:   demo_videos/whisker_test_demo.gif (8.2M)

📋 Add to README.md:

## 🎬 Tests in Action

![Whisker smoke Tests](demo_videos/whisker_test_demo.gif)

*Automated smoke tests - Status: PASSED*

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎉 Ready to showcase your tests on GitHub!
```

---

## 📞 Support

- **Demo Directory**: `demo_videos/README.md`
- **Scripts**: `generate_demo.sh`, `record_screen.sh`, `video_to_gif.sh`, `record_terminal.sh`
- **GitHub**: github.com/Channarith/WhiskerTestCIPipeline
- **Contact**: cvanthin@hotmail.com

---

**Ready to create your first demo?** Run `./generate_demo.sh` now! 🎬


# iPhone as macOS Trackpad

This project aims to let you use your iPhone as a fully-featured trackpad for your Mac, supporting native gestures and low latency.

## Project Roadmap & To-Do

### 1. macOS App Setup
- [x] Create a new macOS App project in Xcode (Swift, SwiftUI or Storyboard)
- [x] Save the project in this folder (`mac_track`)
- [ ] Set up basic app structure (AppDelegate, main window, etc.)

### 2. Networking: Receive Gesture Data
- [ ] Add a TCP/UDP/WebSocket server to the macOS app
- [ ] Define a protocol for gesture/touch data (e.g., JSON or binary)
- [ ] Parse incoming data and map to gesture events

### 3. Event Injection: Simulate Trackpad Gestures
- [ ] Research and select APIs for injecting mouse/trackpad/gesture events (CoreGraphics, IOKit, or private APIs)
- [ ] Implement code to inject mouse movement, clicks, and multi-finger gestures
- [ ] Test event injection for accuracy and latency

### 4. iPhone Side: Send Gesture Data
- [ ] Create a simple iPhone web app (HTML/JS) or native app to capture touch/gesture data
- [ ] Implement networking to send data to the Mac app
- [ ] Support multi-touch and gesture recognition (swipe, pinch, etc.)

### 5. Security & Polish
- [ ] Restrict network connections to local network only
- [ ] (Optional) Add authentication or pairing
- [ ] Polish UI/UX for both Mac and iPhone sides

### 6. Documentation & Testing
- [ ] Write setup and usage instructions
- [ ] Test all gestures and refine as needed
- [ ] Document known issues and limitations

---

## How to Use This Checklist
- Tackle each section in order, or work on them in parallel as needed.
- Check off items as you complete them.
- Return to this file to track progress and next steps.

## Notes
- For full gesture support, you may need to use private or lower-level macOS APIs.
- Security is important: avoid exposing your Mac to the wider internet.
- Contributions and suggestions are welcome!

# Context Cam - Moondream iOS Starter

A simple iOS starter project for integrating [Moondream](https://moondream.ai) AI vision with real-time camera capture and context detection.

## What It Does

Captures images from your camera, sends them to Moondream AI for analysis, and uses direct AI queries to detect specific contexts in real-time.

![Context Cam Demo](context_cam_example.gif)

## Quick Start

1. **Get a Moondream API key** at [moondream.ai](https://moondream.ai)

2. **Add your API key** in `Info.plist`:
   ```xml
   <key>MOONDREAM_API_KEY</key>
   <string>YOUR_API_KEY_HERE</string>
   ```

3. **Build and run** the project in Xcode

## How It Works

1. **Camera** captures an image using AVFoundation
2. **Images** are automatically resized to 192x192 and compressed for fast API calls  
3. **Moondream** analyzes the image and returns a description
4. **Context queries** ask Moondream specific yes/no questions like "Is the person petting a dog?"
5. **Sequential capture** - only takes the next image after receiving the API response


## Key Files

- **`CameraCaptureView.swift`** - AVFoundation camera implementation
- **`MoondreamService.swift`** - API integration with Moondream
- **`ContextManager.swift`** - Query-response context detection system
- **`ContentView.swift`** - Main UI

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Moondream API key

## License

MIT License - feel free to use this as a starting point for your own projects!

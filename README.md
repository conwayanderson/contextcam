# Context Cam - Moondream iOS Starter

A simple iOS starter project for integrating [Moondream](https://moondream.ai) AI vision with real-time camera capture.

## What It Does

Captures images from your camera, sends them to Moondream AI for analysis, and includes a basic keyword detection to test having the app respond to certain detected contexts.

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
4. **Keyword detection** (basic example) looks for simple gestures like "thumbs up"
5. **Sequential capture** - only takes the next image after receiving the API response

## Basic Keyword Actions (Starting Point)

The app includes a simple keyword detection system that recognizes:
- Thumbs up gestures
- Peace signs
- Pointing
- Waving

Recommend looking into more advanced approaches. Just meant for simple testing.

## Key Files

- **`CameraCaptureView.swift`** - AVFoundation camera implementation
- **`MoondreamService.swift`** - API integration with Moondream
- **`KeywordActionManager.swift`** - Basic keyword detection (customize this!)
- **`ContentView.swift`** - Main UI

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Moondream API key

## License

MIT License - feel free to use this as a starting point for your own projects!

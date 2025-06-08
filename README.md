# Magnetic-Particles
# MagneticParticles

## Description

MagneticParticles is an interactive particle system for iOS that uses **UIKit** and **Core Animation** to simulate hundreds of particles moving randomly, bouncing off screen edges, and clustering around a touch point with a "magnetic" attraction effect. Particles smoothly return to their original positions when the touch ends.

## Key Features

- Random motion with edge bouncing using velocity vectors
- "Magnetic" touch attraction with individual offsets per particle
- Smooth return interpolation back to original positions
- Configurable particle count, size range, and colors
- Lightweight, pure code implementation (no Storyboards) for easy integration

## Installation

1. Clone or download this repository:
    
    ```
    git clone https://github.com/yourusername/MagneticParticles.git
    ```
    
2. In your Xcode project:
    - Go to **File > Add Packages...**
    - Choose **Add Local...** and select the root folder of this repository.
    - Add the `MagneticParticles` package to your target.
3. Import and use in your code:
    
    ```
    import MagneticParticles
    
    // In your view controller:
    let magneticView = MagneticParticlesView(frame: view.bounds)
    view.addSubview(magneticView)
    ```
    

## Code Structure

```
MagneticParticles/
├── Package.swift              # Swift Package manifest
├── Sources/
│   └── MagneticParticles/
│       ├── MagneticParticlesView.swift
│       └── Particle.swift      # (or embedded in view file)
│
└── DemoApp/
    ├── AppDelegate.swift
    ├── SceneDelegate.swift
    ├── ViewController.swift
    ├── Info.plist
    └── Assets.xcassets
```

## Technologies Used

- Swift
- UIKit
- Core Animation (`CAShapeLayer`, `CADisplayLink`)
- Vector math and physics simulation

## Project Goal

The aim of this mini project is to demonstrate advanced touch-driven animations and physics-based interactions in a modular, reusable format. It serves as a foundation for creative prototypes, interactive backgrounds, and educational demos showcasing real-time particle systems in iOS.

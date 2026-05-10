# visionOS Target Setup Guide (Section 14.4)

This document provides step-by-step instructions for adding a visionOS framework target to the Xcode project.

## Prerequisites

- Xcode 16.1 or later with visionOS SDK installed
- CDMarkdownKit.xcodeproj open in Xcode

## Steps

### 1. Create a New visionOS Framework Target

1. In Xcode, select **File → New → Target**
2. In the dialog that appears, select the **visionOS** tab
3. Choose **Framework** as the template
4. Click **Next**

### 2. Configure Target Settings

1. Set **Product Name** to `CDMarkdownKit visionOS`
2. Set **Team** to your development team
3. Set **Deployment Target** to **visionOS 1.0**
4. Leave other settings at defaults
5. Click **Finish**

Xcode will create the target and a default stub file.

### 3. Remove Auto-Generated Files

1. In Xcode navigator, find the `CDMarkdownKit visionOS` group
2. Delete the auto-generated `.h` header file (e.g., `CDMarkdownKit_visionOS.h`)
3. Also delete any `Info.plist` or `module.modulemap` if present

### 4. Add Source Files to Build Phases

1. Select the **CDMarkdownKit visionOS** target in Xcode
2. Go to **Build Phases → Compile Sources**
3. Click the **+** button to add files
4. Select all Swift files from the `Source/` directory (the same files as the iOS target)
5. Ensure each file has a checkmark next to the visionOS target

Files to include:
- All `CD*.swift` files in Source/
- All extension files (`*+CDMarkdownKit.swift`)

### 5. Configure SwiftLint Build Phase

1. Still in Build Phases, click the **+** button and select **New Run Script Phase**
2. Name it `SwiftLint`
3. Set the script to:
```bash
export PATH="$PATH:/opt/homebrew/bin"
if which swiftlint >/dev/null; then
    cd "$SRCROOT" && swiftlint lint
else
    echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
fi
```
4. Ensure "Show environment variables in build log" is unchecked
5. Ensure "Run script only when installing" is unchecked

### 6. Create/Configure Scheme

1. Go to **Product → Scheme → Manage Schemes**
2. Look for `CDMarkdownKit visionOS` in the list
3. Ensure it has a checkmark next to "Shared" (so it's part of the project)
4. Click **Close**

### 7. Build and Verify

1. Select **Product → Scheme** and choose `CDMarkdownKit visionOS`
2. Select a visionOS simulator destination (e.g., "Apple Vision Pro")
3. Build in Debug: **Product → Build** (or Cmd+B)
4. Confirm build succeeds with no errors
5. Change to Release configuration and build again

## Build Settings

The visionOS target should inherit most build settings from the Xcode defaults. Ensure:

- **Swift Language Version**: Swift 5.0+
- **Deployment Target**: visionOS 1.0
- **Code Signing Identity**: Automatic
- **Framework Search Paths**: Inherit from project
- **Other Swift Flags**: None (unless customizing)

## Troubleshooting

**"Cannot find 'CDFont' in scope"**
- Ensure all Source files are added to the Compile Sources build phase

**"Build fails on SwiftLint phase"**
- SwiftLint may not be installed; the script should warn but not fail
- Verify `/opt/homebrew/bin/swiftlint` exists or install via Homebrew

**"Deployment target mismatch"**
- Verify target is set to visionOS 1.0, not iOS 1.0

**"Scheme not found"**
- Create the scheme manually: **File → New → Scheme** and select the visionOS target

## Notes

- This target is for Xcode IDE support; SPM (Package.swift) is the primary distribution method
- The visionOS target does not affect CocoaPods distribution
- visionOS simulators are available on macOS 15+ with Xcode 16.1+

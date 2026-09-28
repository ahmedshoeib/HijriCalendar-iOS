# Contributing

Issues and focused pull requests are welcome. Please include tests for changes to date math or selection behavior and exercise both UIKit and SwiftUI when changing the renderer.

Run the core tests:

```bash
swift test
```

Build the complete example projects:

```bash
xcodebuild \
  -project Examples/SwiftUIDemo/SwiftUIDemo.xcodeproj \
  -scheme SwiftUIDemo \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO \
  build

xcodebuild \
  -project Examples/UIKitDemo/UIKitDemo.xcodeproj \
  -scheme UIKitDemo \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

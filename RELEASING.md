# Releasing HijriCalendar

1. Confirm the public API and update `CHANGELOG.md`.
2. Run `swift test` on macOS.
3. Build both complete example projects for a generic iOS device.
4. Regenerate the README animation with `swift Scripts/make-demo-gif.swift` if the design changed.
5. Commit the release, push `main`, and verify CI passes.
6. Create an annotated semantic version tag such as `1.0.0` and push it.
7. Verify the package URL resolves in a clean Xcode project.
8. Submit the repository URL to the Swift Package Index if it is not discovered automatically.

Avoid force-moving a published version tag. Create a patch release instead.

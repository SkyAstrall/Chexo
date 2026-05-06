# Contributing to Chexo

Thanks for your interest in improving Chexo.

## Setup

1. **Requirements**: macOS 15.0+ (Sequoia), Xcode 16+, [XcodeGen](https://github.com/yonaskolb/XcodeGen) 2.43+
2. **Clone** the repo
3. **Generate** the Xcode project:

```bash
xcodegen generate
```

4. **Open** `Chexo.xcodeproj` in Xcode

The `.xcodeproj` is generated from `project.yml` and should never be edited directly. If you need to change build settings, targets, or schemes, edit `project.yml` and re-run `xcodegen generate`.

## Development

- **Language**: Swift 6.0 with strict concurrency (`SWIFT_STRICT_CONCURRENCY: complete`)
- **UI framework**: SwiftUI
- **Data layer**: SwiftData
- **Minimum deployment**: macOS 15.0

## Building & Testing

```bash
# Build
xcodebuild -project Chexo.xcodeproj -scheme Chexo -configuration Debug build

# Run tests
xcodebuild -project Chexo.xcodeproj -scheme Chexo -only-testing:ChexoTests test
```

All tests must pass before submitting a PR. CI runs both build and test on every push.

## Pull Requests

- Create a branch from `main`
- Keep changes focused — one concern per PR
- Add tests for new model logic
- Ensure `xcodegen generate` + build + test all pass
- Open a PR against `main` with a clear description of what changed and why

## Code Style

- No `try!` in production code — use `do/catch` with meaningful error handling
- Prefer Swift concurrency (`async/await`, `Task`) over `DispatchQueue`
- No force unwraps outside of tests
- Minimal comments — code should be self-documenting
- No print/debug statements in committed code

# libcapstone-spm

Swift Package Manager support for the vendored
[Capstone](https://github.com/capstone-engine/capstone) static library.

## Features

- Builds Capstone from source inside SwiftPM
- No Homebrew or system-wide Capstone install required
- Apple platform coverage: macOS, Mac Catalyst, iOS, iOS Simulator, tvOS,
  tvOS Simulator, watchOS, watchOS Simulator, visionOS, visionOS Simulator
- Bundles the upstream Capstone architecture decoders included in the vendored
  source tree

## Install

```swift
.package(url: "https://github.com/Lakr233/libcapstone-spm.git", from: "1.0.0")
```

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "Capstone", package: "libcapstone-spm"),
    ]
)
```

## Usage

```swift
import Capstone

var handle: OpaquePointer?
let error = cs_open(CS_ARCH_ARM64, CS_MODE_LITTLE_ENDIAN, &handle)
guard error == CS_ERR_OK, let handle else {
    fatalError("cs_open failed: \(error)")
}

defer {
    var mutableHandle: OpaquePointer? = handle
    cs_close(&mutableHandle)
}
```

## Local Validation

```bash
./Script/test.sh
```

## License

This wrapper package vendors Capstone and follows the upstream Capstone license.

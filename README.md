# libcapstone-spm

Swift Package Manager support for the vendored
[Capstone](https://github.com/capstone-engine/capstone) disassembly engine,
with a Swift-friendly wrapper API.

## Features

- Builds Capstone v6 from source inside SwiftPM — no Homebrew or system-wide install required
- Swift wrapper with automatic memory management (no manual `cs_free`/`cs_close`)
- Full access to instruction detail: operands, registers, groups, condition codes
- All 25 CPU architectures supported (AArch64, ARM, x86, MIPS, RISC-V, PowerPC, …)
- Apple platform coverage: macOS, Mac Catalyst, iOS, tvOS, watchOS, visionOS (device + simulator)

## Install

```swift
.package(url: "https://github.com/Lakr233/libcapstone-spm.git", from: "0.1.0")
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

### Swift API

```swift
import Capstone

let disassembler = try Disassembler(arch: CS_ARCH_AARCH64, mode: CS_MODE_LITTLE_ENDIAN)
disassembler.detail = true

let code: [UInt8] = [0x00, 0x00, 0x80, 0xD2, 0xC0, 0x03, 0x5F, 0xD6]
let instructions = disassembler.disassemble(code: code, address: 0x1000)

for insn in instructions {
    print(insn) // 0x1000: mov x0, #0
                 // 0x1004: ret
}

// access operand detail (requires detail = true)
if let detail = instructions[0].aarch64 {
    for op in detail.operands {
        switch op.type {
        case AARCH64_OP_REG:
            let name = disassembler.registerName(UInt32(op.reg.rawValue))
            print("  reg: \(name ?? "?")")
        case AARCH64_OP_IMM:
            print("  imm: \(op.imm)")
        default:
            break
        }
    }
}
```

### Raw C API

The underlying C API is also available via `CoreCapstone` (re-exported automatically):

```swift
import Capstone

var handle: csh = 0
let err = cs_open(CS_ARCH_AARCH64, CS_MODE_LITTLE_ENDIAN, &handle)
defer { cs_close(&handle) }
```

## Package Structure

| Target | Language | Description |
|---|---|---|
| `CoreCapstone` | C | Vendored Capstone v6 static library compiled from source |
| `Capstone` | Swift | Public API — `Disassembler`, `Instruction`, `CapstoneError` |

Only `Capstone` is exported as a library product. `CoreCapstone` is an internal
dependency and its symbols are re-exported through `Capstone`.

## Local Validation

```bash
./Script/test.sh
```

## License

This wrapper package vendors Capstone and follows the upstream Capstone license.

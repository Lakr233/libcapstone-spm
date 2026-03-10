import XCTest
import Capstone

final class CapstoneTests: XCTestCase {
    func testARM64Disassembly() {
        var handle: csh = 0
        let error = cs_open(CS_ARCH_AARCH64, cs_mode(rawValue: CS_MODE_LITTLE_ENDIAN.rawValue), &handle)

        XCTAssertEqual(error, CS_ERR_OK)
        guard error == CS_ERR_OK else { return }

        defer {
            cs_close(&handle)
        }

        let code: [UInt8] = [0x00, 0x00, 0x00, 0x14]
        var instructions: UnsafeMutablePointer<cs_insn>?

        let count = code.withUnsafeBufferPointer { bytes in
            cs_disasm(handle, bytes.baseAddress, bytes.count, 0x1000, 0, &instructions)
        }

        XCTAssertGreaterThan(count, 0)
        guard count > 0, let instructions else { return }

        defer {
            cs_free(instructions, count)
        }

        XCTAssertEqual(instructions.pointee.id, UInt32(AARCH64_INS_B.rawValue))
    }

    func testX86Disassembly() {
        var handle: csh = 0
        let error = cs_open(CS_ARCH_X86, cs_mode(rawValue: CS_MODE_64.rawValue), &handle)

        XCTAssertEqual(error, CS_ERR_OK)
        guard error == CS_ERR_OK else { return }

        defer {
            cs_close(&handle)
        }

        let code: [UInt8] = [0x90]
        var instructions: UnsafeMutablePointer<cs_insn>?

        let count = code.withUnsafeBufferPointer { bytes in
            cs_disasm(handle, bytes.baseAddress, bytes.count, 0x1000, 0, &instructions)
        }

        XCTAssertGreaterThan(count, 0)
        guard count > 0, let instructions else { return }

        defer {
            cs_free(instructions, count)
        }

        XCTAssertEqual(instructions.pointee.id, UInt32(X86_INS_NOP.rawValue))
    }
}

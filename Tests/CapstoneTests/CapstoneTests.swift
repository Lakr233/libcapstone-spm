import Capstone
import XCTest

final class CapstoneTests: XCTestCase {
    func testARM64Disassembly() throws {
        let dis = try Disassembler(arch: CS_ARCH_AARCH64, mode: CS_MODE_LITTLE_ENDIAN)
        let code: [UInt8] = [0x00, 0x00, 0x00, 0x14] // b #0
        let insns = dis.disassemble(code: code, address: 0x1000)

        XCTAssertEqual(insns.count, 1)
        XCTAssertEqual(insns[0].id, UInt32(AARCH64_INS_B.rawValue))
        XCTAssertEqual(insns[0].mnemonic, "b")
        XCTAssertEqual(insns[0].address, 0x1000)
        XCTAssertEqual(insns[0].size, 4)
    }

    func testX86Disassembly() throws {
        let dis = try Disassembler(arch: CS_ARCH_X86, mode: cs_mode(rawValue: CS_MODE_64.rawValue))
        let code: [UInt8] = [0x90] // nop
        let insns = dis.disassemble(code: code, address: 0x1000)

        XCTAssertEqual(insns.count, 1)
        XCTAssertEqual(insns[0].id, UInt32(X86_INS_NOP.rawValue))
        XCTAssertEqual(insns[0].mnemonic, "nop")
    }

    func testARM64Detail() throws {
        let dis = try Disassembler(arch: CS_ARCH_AARCH64, mode: CS_MODE_LITTLE_ENDIAN)
        dis.detail = true

        // mov x0, #0  -> 0xD2800000
        let code: [UInt8] = [0x00, 0x00, 0x80, 0xD2]
        let insns = dis.disassemble(code: code, address: 0)

        XCTAssertEqual(insns.count, 1)
        let insn = insns[0]
        XCTAssertNotNil(insn.aarch64)

        guard let detail = insn.aarch64 else { return }
        XCTAssertGreaterThan(detail.operands.count, 0)

        let regOp = detail.operands[0]
        XCTAssertEqual(regOp.type, AARCH64_OP_REG)
    }

    func testMultipleInstructions() throws {
        let dis = try Disassembler(arch: CS_ARCH_AARCH64, mode: CS_MODE_LITTLE_ENDIAN)
        // nop; nop; ret
        let code: [UInt8] = [
            0x1F, 0x20, 0x03, 0xD5, // nop
            0x1F, 0x20, 0x03, 0xD5, // nop
            0xC0, 0x03, 0x5F, 0xD6, // ret
        ]
        let insns = dis.disassemble(code: code, address: 0x1000)

        XCTAssertEqual(insns.count, 3)
        XCTAssertEqual(insns[0].mnemonic, "nop")
        XCTAssertEqual(insns[1].mnemonic, "nop")
        XCTAssertEqual(insns[2].mnemonic, "ret")
        XCTAssertEqual(insns[0].address, 0x1000)
        XCTAssertEqual(insns[1].address, 0x1004)
        XCTAssertEqual(insns[2].address, 0x1008)
    }

    func testInstructionDescription() throws {
        let dis = try Disassembler(arch: CS_ARCH_AARCH64, mode: CS_MODE_LITTLE_ENDIAN)
        let code: [UInt8] = [0xC0, 0x03, 0x5F, 0xD6] // ret
        let insns = dis.disassemble(code: code, address: 0x4000)

        XCTAssertEqual(insns.count, 1)
        XCTAssert(insns[0].description.contains("ret"))
        XCTAssert(insns[0].description.contains("0x4000"))
    }

    func testDisassembleWithCount() throws {
        let dis = try Disassembler(arch: CS_ARCH_AARCH64, mode: CS_MODE_LITTLE_ENDIAN)
        let code: [UInt8] = [
            0x1F, 0x20, 0x03, 0xD5, // nop
            0x1F, 0x20, 0x03, 0xD5, // nop
            0xC0, 0x03, 0x5F, 0xD6, // ret
        ]
        let insns = dis.disassemble(code: code, address: 0, count: 1)
        XCTAssertEqual(insns.count, 1)
    }

    func testSkipData() throws {
        let dis = try Disassembler(arch: CS_ARCH_AARCH64, mode: CS_MODE_LITTLE_ENDIAN)
        dis.skipData = true
        // 2 bytes of garbage + a valid nop
        let code: [UInt8] = [0xFF, 0xFF, 0x1F, 0x20, 0x03, 0xD5]
        let insns = dis.disassemble(code: code, address: 0)
        XCTAssertGreaterThan(insns.count, 0)
    }

    func testRegisterName() throws {
        let dis = try Disassembler(arch: CS_ARCH_AARCH64, mode: CS_MODE_LITTLE_ENDIAN)
        let name = dis.registerName(UInt32(AARCH64_REG_X0.rawValue))
        XCTAssertEqual(name, "x0")
    }

    func testInvalidArch() {
        XCTAssertThrowsError(try Disassembler(arch: CS_ARCH_MAX, mode: CS_MODE_LITTLE_ENDIAN))
    }

    func testEmptyCode() throws {
        let dis = try Disassembler(arch: CS_ARCH_AARCH64, mode: CS_MODE_LITTLE_ENDIAN)
        let insns = dis.disassemble(code: [UInt8](), address: 0)
        XCTAssertEqual(insns.count, 0)
    }

    func testDataDisassembly() throws {
        let dis = try Disassembler(arch: CS_ARCH_AARCH64, mode: CS_MODE_LITTLE_ENDIAN)
        dis.detail = true

        // adrp x0, #0x1000 -> 0x90000000 at address 0
        // but let's use a simpler well-known: add x0, x1, x2 -> 0x8B020020
        let code: [UInt8] = [0x20, 0x00, 0x02, 0x8B]
        let insns = dis.disassemble(code: code, address: 0)

        XCTAssertEqual(insns.count, 1)
        XCTAssertEqual(insns[0].bytes, code)
        XCTAssertNotNil(insns[0].aarch64)

        if let detail = insns[0].aarch64 {
            XCTAssertEqual(detail.operands.count, 3) // x0, x1, x2
            XCTAssertTrue(detail.operands.allSatisfy { $0.type == AARCH64_OP_REG })
        }
    }

    func testGroupsPopulated() throws {
        let dis = try Disassembler(arch: CS_ARCH_AARCH64, mode: CS_MODE_LITTLE_ENDIAN)
        dis.detail = true

        // b #0 (branch instruction, should be in JUMP group)
        let code: [UInt8] = [0x00, 0x00, 0x00, 0x14]
        let insns = dis.disassemble(code: code, address: 0)

        XCTAssertEqual(insns.count, 1)
        XCTAssertFalse(insns[0].groups.isEmpty)
        XCTAssertTrue(insns[0].groups.contains(UInt8(CS_GRP_JUMP.rawValue)))
    }
}

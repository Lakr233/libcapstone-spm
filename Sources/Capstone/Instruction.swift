import CoreCapstone
import Foundation

public struct Instruction: Sendable {
    public let id: UInt32
    public let address: UInt64
    public let size: UInt16
    public let bytes: [UInt8]
    public let mnemonic: String
    public let operandString: String
    public let isAlias: Bool

    public let regsRead: [UInt16]
    public let regsWritten: [UInt16]
    public let groups: [UInt8]

    public let aarch64: AArch64Detail?
    public let x86: X86Detail?

    init(_ raw: cs_insn, handle _: csh) {
        id = raw.id
        address = raw.address
        size = raw.size
        bytes = withUnsafeBytes(of: raw.bytes) { Array($0.prefix(Int(raw.size))) }
        mnemonic = withUnsafeBytes(of: raw.mnemonic) { buf in
            String(cString: buf.baseAddress!.assumingMemoryBound(to: CChar.self))
        }
        operandString = withUnsafeBytes(of: raw.op_str) { buf in
            String(cString: buf.baseAddress!.assumingMemoryBound(to: CChar.self))
        }
        isAlias = raw.is_alias

        if let detail = raw.detail {
            let d = detail.pointee
            regsRead = withUnsafeBytes(of: d.regs_read) { buf in
                let p = buf.baseAddress!.assumingMemoryBound(to: UInt16.self)
                return Array(UnsafeBufferPointer(start: p, count: Int(d.regs_read_count)))
            }
            regsWritten = withUnsafeBytes(of: d.regs_write) { buf in
                let p = buf.baseAddress!.assumingMemoryBound(to: UInt16.self)
                return Array(UnsafeBufferPointer(start: p, count: Int(d.regs_write_count)))
            }
            groups = withUnsafeBytes(of: d.groups) { buf in
                let p = buf.baseAddress!.assumingMemoryBound(to: UInt8.self)
                return Array(UnsafeBufferPointer(start: p, count: Int(d.groups_count)))
            }
            aarch64 = AArch64Detail(d.aarch64)
            x86 = X86Detail(d.x86)
        } else {
            regsRead = []
            regsWritten = []
            groups = []
            aarch64 = nil
            x86 = nil
        }
    }
}

extension Instruction: CustomStringConvertible {
    public var description: String {
        let addr = String(format: "0x%llx", address)
        if operandString.isEmpty {
            return "\(addr): \(mnemonic)"
        }
        return "\(addr): \(mnemonic) \(operandString)"
    }
}

// MARK: - AArch64 Detail

public struct AArch64Detail: Sendable {
    public let conditionCode: AArch64CC_CondCode
    public let updatesFlags: Bool
    public let postIndex: Bool
    public let operands: [AArch64Operand]

    init(_ raw: cs_aarch64) {
        conditionCode = raw.cc
        updatesFlags = raw.update_flags
        postIndex = raw.post_index
        operands = withUnsafeBytes(of: raw.operands) { buf in
            let p = buf.baseAddress!.assumingMemoryBound(to: cs_aarch64_op.self)
            return (0 ..< Int(raw.op_count)).map { AArch64Operand(p[$0]) }
        }
    }
}

public struct AArch64Operand: Sendable {
    public let type: aarch64_op_type
    public let access: cs_ac_type
    public let reg: aarch64_reg
    public let imm: Int64
    public let fp: Double
    public let mem: aarch64_op_mem

    init(_ raw: cs_aarch64_op) {
        type = raw.type
        access = raw.access
        reg = raw.reg
        imm = raw.imm
        fp = raw.fp
        mem = raw.mem
    }
}

// MARK: - X86 Detail

public struct X86Detail: Sendable {
    public let operands: [X86Operand]

    init(_ raw: cs_x86) {
        operands = withUnsafeBytes(of: raw.operands) { buf in
            let p = buf.baseAddress!.assumingMemoryBound(to: cs_x86_op.self)
            return (0 ..< Int(raw.op_count)).map { X86Operand(p[$0]) }
        }
    }
}

public struct X86Operand: Sendable {
    public let type: x86_op_type
    public let reg: x86_reg
    public let imm: Int64
    public let mem: x86_op_mem

    init(_ raw: cs_x86_op) {
        type = raw.type
        reg = raw.reg
        imm = raw.imm
        mem = raw.mem
    }
}

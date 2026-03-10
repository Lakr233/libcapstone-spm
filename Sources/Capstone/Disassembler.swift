@_exported import CoreCapstone
import Foundation

public final class Disassembler: @unchecked Sendable {
    private var handle: csh = 0

    public init(arch: cs_arch, mode: cs_mode) throws {
        let err = cs_open(arch, mode, &handle)
        guard err == CS_ERR_OK else {
            throw CapstoneError(err)
        }
    }

    deinit {
        if handle != 0 {
            cs_close(&handle)
        }
    }

    public var detail: Bool {
        get { _detail }
        set {
            _detail = newValue
            cs_option(handle, CS_OPT_DETAIL, newValue ? numericCast(CS_OPT_ON.rawValue) : numericCast(CS_OPT_OFF.rawValue))
        }
    }

    public var skipData: Bool {
        get { _skipData }
        set {
            _skipData = newValue
            cs_option(handle, CS_OPT_SKIPDATA, newValue ? numericCast(CS_OPT_ON.rawValue) : numericCast(CS_OPT_OFF.rawValue))
        }
    }

    private var _detail = false
    private var _skipData = false

    public func disassemble(code: some DataProtocol, address: UInt64 = 0, count: Int = 0) -> [Instruction] {
        let bytes = Array(code)
        return bytes.withUnsafeBufferPointer { buf in
            var insns: UnsafeMutablePointer<cs_insn>?
            let n = cs_disasm(handle, buf.baseAddress, buf.count, address, count, &insns)
            guard n > 0, let insns else { return [] }
            defer { cs_free(insns, n) }
            return (0 ..< n).map { i in
                Instruction(insns.advanced(by: i).pointee, handle: handle)
            }
        }
    }

    public func registerName(_ regId: UInt32) -> String? {
        guard let p = cs_reg_name(handle, regId) else { return nil }
        return String(cString: p)
    }

    public func instructionName(_ insnId: UInt32) -> String? {
        guard let p = cs_insn_name(handle, insnId) else { return nil }
        return String(cString: p)
    }

    public func groupName(_ groupId: UInt32) -> String? {
        guard let p = cs_group_name(handle, groupId) else { return nil }
        return String(cString: p)
    }
}

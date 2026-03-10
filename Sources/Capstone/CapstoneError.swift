import CoreCapstone
import Foundation

public struct CapstoneError: Error, CustomStringConvertible, Sendable {
    public let code: cs_err

    init(_ code: cs_err) {
        self.code = code
    }

    public var description: String {
        String(cString: cs_strerror(code))
    }
}

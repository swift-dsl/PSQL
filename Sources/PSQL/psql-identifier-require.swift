import Foundation

public enum PSQLIdentifierError: Error, LocalizedError, Sendable {
    case invalid(String)

    public var errorDescription: String? {
        switch self {
        case .invalid(let identifier):
            return "Invalid SQL identifier or path: \(identifier)"
        }
    }
}

extension PSQLScan.Ident {
    public static func requireValid(
        _ identifier: String
    ) throws {
        guard isValid(identifier) else {
            throw PSQLIdentifierError.invalid(identifier)
        }
    }
}

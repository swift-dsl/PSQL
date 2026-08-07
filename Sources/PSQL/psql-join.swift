import Foundation

// extension PSQL {
//     public enum JoinKind: String, Sendable { case inner = "INNER JOIN", left = "LEFT JOIN", right = "RIGHT JOIN" }

//     public struct Join: SQLRenderable {
//         public let kind: JoinKind
//         public let table: String
//         public let on: any SQLRenderable
//         public init(_ kind: JoinKind, _ table: String, on: any SQLRenderable) {
//             self.kind = kind; self.table = table; self.on = on
//         }
//         public func render(_ ctx: inout SQLRenderContext) -> String {
//             // "\(kind.rawValue) \"\(table)\" ON \(on.render(&ctx))"
//             "\(kind.rawValue) \(Ident.table(table).render(&ctx)) ON \(on.render(&ctx))"
//         }
//     }

//     public static func join(_ kind: JoinKind, table: Ident, on: any SQLRenderable) -> Join {
//         .init(kind, table.value, on: on)
//     }
// }

extension PSQL {
    public enum JoinKind: String, Sendable {
        case inner = "INNER JOIN"
        case left = "LEFT JOIN"
        case right = "RIGHT JOIN"
        case full = "FULL JOIN"
        case cross = "CROSS JOIN"
    }

    public struct Join: SQLRenderable {
        public let kind: JoinKind
        public let table: String
        public let source: (any SQLRenderable)?
        public let alias: Ident?
        public let aliasColumns: [Ident]
        public let lateral: Bool
        public let on: any SQLRenderable

        public init(
            _ kind: JoinKind,
            _ table: String,
            as alias: String? = nil,
            on: any SQLRenderable
        ) {
            self.kind = kind
            self.table = table
            self.source = nil
            self.alias = alias.map(Ident.alias)
            self.aliasColumns = []
            self.lateral = false
            self.on = on
        }

        public init(
            _ kind: JoinKind,
            source: any SQLRenderable,
            as alias: String,
            columns: [String] = [],
            lateral: Bool = false,
            on: any SQLRenderable
        ) {
            self.kind = kind
            self.table = ""
            self.source = source
            self.alias = .alias(alias)
            self.aliasColumns = columns.map(Ident.alias)
            self.lateral = lateral
            self.on = on
        }

        public func render(
            _ ctx: inout SQLRenderContext
        ) -> String {
            let renderedSource: String

            if let source {
                renderedSource =
                    "\(lateral ? "LATERAL " : "")\(source.render(&ctx))"
            } else {
                renderedSource = Ident.table(table).render(&ctx)
            }

            let renderedTarget: String

            if let alias {
                let renderedColumns: String

                if aliasColumns.isEmpty {
                    renderedColumns = ""
                } else {
                    renderedColumns = "("
                        + aliasColumns
                            .map { $0.render(&ctx) }
                            .joined(separator: ", ")
                        + ")"
                }

                renderedTarget =
                    "\(renderedSource) AS "
                    + "\(alias.render(&ctx))"
                    + renderedColumns
            } else {
                renderedTarget = renderedSource
            }

            if kind == .cross {
                return "\(kind.rawValue) \(renderedTarget)"
            }

            return """
            \(kind.rawValue) \(renderedTarget) \
            ON \(on.render(&ctx))
            """
        }
    }

    public static func join(
        _ kind: JoinKind,
        table: Ident,
        as alias: String? = nil,
        on: any SQLRenderable
    ) -> Join {
        .init(
            kind,
            table.value,
            as: alias,
            on: on
        )
    }

    public static func join(
        _ kind: JoinKind,
        source: any SQLRenderable,
        as alias: String,
        columns: [String] = [],
        lateral: Bool = false,
        on: any SQLRenderable
    ) -> Join {
        .init(
            kind,
            source: source,
            as: alias,
            columns: columns,
            lateral: lateral,
            on: on
        )
    }

    public static func crossJoin(
        table: Ident,
        as alias: String? = nil
    ) -> Join {
        .init(
            .cross,
            table.value,
            as: alias,
            on: PSQL.true()
        )
    }

    public static func crossJoin(
        source: any SQLRenderable,
        as alias: String,
        columns: [String] = [],
        lateral: Bool = false
    ) -> Join {
        .init(
            .cross,
            source: source,
            as: alias,
            columns: columns,
            lateral: lateral,
            on: PSQL.true()
        )
    }
}

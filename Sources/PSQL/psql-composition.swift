import Foundation

extension PSQL {
    public enum Keyword: String, SQLRenderable, Sendable {
        case currentUser = "CURRENT_USER"
        case currentRole = "CURRENT_ROLE"
        case currentSchema = "CURRENT_SCHEMA"
        case currentCatalog = "CURRENT_CATALOG"

        public func render(
            _ ctx: inout SQLRenderContext
        ) -> String {
            rawValue
        }
    }

    public struct StringLiteral: SQLRenderable {
        public let value: String

        public init(_ value: String) {
            self.value = value
        }

        public func render(
            _ ctx: inout SQLRenderContext
        ) -> String {
            "'\(value.replacingOccurrences(of: "'", with: "''"))'"
        }
    }

    public struct IntegerLiteral: SQLRenderable {
        public let value: Int

        public init(_ value: Int) {
            self.value = value
        }

        public func render(
            _ ctx: inout SQLRenderContext
        ) -> String {
            String(value)
        }
    }

    public static func string(
        _ value: String
    ) -> StringLiteral {
        .init(value)
    }

    public static func integer(
        _ value: Int
    ) -> IntegerLiteral {
        .init(value)
    }

    public enum BinaryOperator: String, Sendable {
        case concat = "||"
        case regexMatch = "~"
        case regexMatchInsensitive = "~*"
        case notRegexMatch = "!~"
        case notRegexMatchInsensitive = "!~*"
        case isDistinctFrom = "IS DISTINCT FROM"
        case isNotDistinctFrom = "IS NOT DISTINCT FROM"
    }

    public static func binary(
        _ left: any SQLRenderable,
        _ op: BinaryOperator,
        _ right: any SQLRenderable
    ) -> Op {
        .bin(
            left,
            op.rawValue,
            right
        )
    }

    public static func concat(
        _ left: any SQLRenderable,
        _ right: any SQLRenderable
    ) -> Op {
        binary(
            left,
            .concat,
            right
        )
    }

    public struct Aggregate: SQLRenderable {
        public let name: String
        public let arguments: [any SQLRenderable]
        public let distinct: Bool
        public let order: [any SQLRenderable]
        public let filter: (any SQLRenderable)?

        public init(
            _ name: String,
            _ arguments: [any SQLRenderable],
            distinct: Bool = false,
            orderBy order: [any SQLRenderable] = [],
            filter: (any SQLRenderable)? = nil
        ) {
            self.name = name
            self.arguments = arguments
            self.distinct = distinct
            self.order = order
            self.filter = filter
        }

        public func render(
            _ ctx: inout SQLRenderContext
        ) -> String {
            var body = arguments.joined(
                ", ",
                &ctx
            )

            if !order.isEmpty {
                body += " ORDER BY "
                    + order.joined(
                        ", ",
                        &ctx
                    )
            }

            var sql =
                "\(name)("
                + "\(distinct ? "DISTINCT " : "")"
                + "\(body))"

            if let filter {
                sql += " FILTER (WHERE \(filter.render(&ctx)))"
            }

            return sql
        }
    }

    public static func aggregate(
        _ name: String,
        _ arguments: [any SQLRenderable],
        distinct: Bool = false,
        orderBy order: [any SQLRenderable] = [],
        filter: (any SQLRenderable)? = nil
    ) -> Aggregate {
        .init(
            name,
            arguments,
            distinct: distinct,
            orderBy: order,
            filter: filter
        )
    }

    public struct Subquery: SQLRenderable {
        public let query: any SQLRenderable

        public init(
            _ query: any SQLRenderable
        ) {
            self.query = query
        }

        public func render(
            _ ctx: inout SQLRenderContext
        ) -> String {
            "(\(query.render(&ctx)))"
        }
    }

    public enum SetOperator: String, Sendable {
        case union = "UNION"
        case unionAll = "UNION ALL"
        case intersect = "INTERSECT"
        case intersectAll = "INTERSECT ALL"
        case except = "EXCEPT"
        case exceptAll = "EXCEPT ALL"
    }

    public struct CompoundQuery: SQLQuery {
        public let first: any SQLRenderable
        public let rest: [
            (
                SetOperator,
                any SQLRenderable
            )
        ]

        public init(
            _ first: any SQLRenderable,
            _ rest: [
                (
                    SetOperator,
                    any SQLRenderable
                )
            ]
        ) {
            self.first = first
            self.rest = rest
        }

        public func render(
            _ ctx: inout SQLRenderContext
        ) -> String {
            var sql = first.render(&ctx)

            for (op, query) in rest {
                sql += " \(op.rawValue) \(query.render(&ctx))"
            }

            return sql
        }

        public func build() -> RenderedSQL {
            var ctx = SQLRenderContext()

            return .init(
                render(&ctx),
                ctx.binds
            )
        }
    }

    public static func unionAll(
        _ first: any SQLRenderable,
        _ second: any SQLRenderable
    ) -> CompoundQuery {
        .init(
            first,
            [
                (
                    .unionAll,
                    second
                )
            ]
        )
    }

    public enum CTEMaterialization: Sendable {
        case unspecified
        case materialized
        case notMaterialized

        fileprivate var sql: String {
            switch self {
            case .unspecified:
                return ""

            case .materialized:
                return "MATERIALIZED "

            case .notMaterialized:
                return "NOT MATERIALIZED "
            }
        }
    }

    public struct CommonTableExpression: SQLRenderable {
        public let name: Ident
        public let columns: [Ident]
        public let query: any SQLRenderable
        public let recursive: Bool
        public let materialization: CTEMaterialization

        public init(
            _ name: String,
            columns: [String] = [],
            query: any SQLRenderable,
            recursive: Bool = false,
            materialization: CTEMaterialization = .unspecified
        ) {
            self.name = .alias(name)
            self.columns = columns.map(
                Ident.alias
            )
            self.query = query
            self.recursive = recursive
            self.materialization = materialization
        }

        public func render(
            _ ctx: inout SQLRenderContext
        ) -> String {
            let columnList: String

            if columns.isEmpty {
                columnList = ""
            } else {
                columnList =
                    " ("
                    + columns
                        .map {
                            $0.render(&ctx)
                        }
                        .joined(separator: ", ")
                    + ")"
            }

            return """
            \(name.render(&ctx))\(columnList) AS \
            \(materialization.sql)(\(query.render(&ctx)))
            """
        }
    }

    public static func cast(
        _ expression: any SQLRenderable,
        as type: PSQLType
    ) -> Cast {
        .init(
            expression,
            as: type
        )
    }

    public static func inValues<
        T: Encodable & Sendable
    >(
        _ expression: any SQLRenderable,
        _ values: [T]
    ) -> Op {
        .bin(
            expression,
            "IN",
            ParamsList(
                values.map {
                    $0 as any Encodable & Sendable
                }
            )
        )
    }
}

extension PSQL.Cast {
    public init(
        _ expression: any PSQL.SQLRenderable,
        as type: PSQLType
    ) {
        self.init(
            expression,
            String(
                type.sqlCast.dropFirst(2)
            )
        )
    }
}

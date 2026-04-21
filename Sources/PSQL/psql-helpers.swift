import Foundation

extension PSQL {
    @inline(__always)
    public static func jsonRow(
        alias: String = "t",
        as output: String = "json_row"
    ) -> As {
        return As(
            func_("row_to_json", [Ident.alias(alias)]),
            as: output
        )
    }

    @inline(__always)
    public static func jsonRow(
        table: String,
        as output: String = "json_row"
    ) -> As {
        return As(
            func_("row_to_json", [Ident.table(table)]),
            as: output
        )
    }
}

extension PSQL.Insert {
    public static func keyed(
        into table: String,
        values: [(String, any PSQL.SQLRenderable)]
    ) -> Self {
        let sorted = values.sorted { $0.0 < $1.0 }

        return Self
            .make(into: table, columns: sorted.map { $0.0 })
            .valuesExpr(sorted.map { $0.1 })
    }
}

extension PSQL.Update {
    public func setAllExpr(
        _ values: [(String, any PSQL.SQLRenderable)]
    ) -> Self {
        let sorted = values.sorted { $0.0 < $1.0 }

        return sorted.reduce(self) { current, entry in
            current.setExpr(entry.0, entry.1)
        }
    }
}

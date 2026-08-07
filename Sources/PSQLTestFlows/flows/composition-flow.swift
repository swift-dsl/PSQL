import PSQL
import TestFlows

extension PSQLFlowSuite {
    static var compositionFlow: TestFlow {
        TestFlow(
            "composition",
            tags: [
                "psql",
                "rendering",
                "composition",
                "regression",
            ]
        ) {
            Step("multiple CTEs share one bind context") {
                let first = PSQL.Select(
                    [
                        PSQL.Ident.column("a.id")
                    ],
                    from: "table_a",
                    as: "a"
                )
                .where(
                    PSQL.equals(
                        PSQL.Ident.column("a.value"),
                        PSQL.val("first")
                    )
                )

                let second = PSQL.Select(
                    [
                        PSQL.Ident.column("b.id")
                    ],
                    from: "table_b",
                    as: "b"
                )
                .where(
                    PSQL.equals(
                        PSQL.Ident.column("b.value"),
                        PSQL.val("second")
                    )
                )

                let rendered = PSQL.Select(
                    [
                        PSQL.Ident.column("first.id")
                    ],
                    from: "first"
                )
                .with(
                    "first",
                    as: first
                )
                .with(
                    "second",
                    as: second
                )
                .build()

                try Expect.contains(
                    rendered.sql,
                    "$1",
                    "composition.cte.first-bind"
                )

                try Expect.contains(
                    rendered.sql,
                    "$2",
                    "composition.cte.second-bind"
                )

                try Expect.equal(
                    rendered.binds.count,
                    2,
                    "composition.cte.bind-count"
                )
            }

            Step("ANY parenthesizes its array expression") {
                var context =
                    PSQL.SQLRenderContext()

                let expression = PSQL.any(
                    PSQL.Ident.column(
                        "row.id"
                    ),
                    PSQL.val(
                        [
                            1,
                            2,
                            3,
                        ]
                    )
                )

                let sql = expression.render(
                    &context
                )

                try Expect.equal(
                    sql,
                    "(\"row\".\"id\" = ANY ($1))",
                    "composition.any.sql"
                )

                try Expect.equal(
                    context.binds.count,
                    1,
                    "composition.any.bind-count"
                )
            }

            Step("array element renders indexed access") {
                var context =
                    PSQL.SQLRenderContext()

                let expression =
                    PSQL.arrayElement(
                        PSQL.Ident.column(
                            "i.indkey"
                        ),
                        PSQL.Ident.column(
                            "slot.subscript"
                        )
                    )

                try Expect.equal(
                    expression.render(
                        &context
                    ),
                    "\"i\".\"indkey\"[\"slot\".\"subscript\"]",
                    "composition.array-element.sql"
                )

                try Expect.equal(
                    context.binds.count,
                    0,
                    "composition.array-element.bind-count"
                )
            }

            Step("aggregate supports ordered arguments") {
                var context =
                    PSQL.SQLRenderContext()

                let expression =
                    PSQL.aggregate(
                        "pg_catalog.jsonb_agg",
                        [
                            PSQL.Ident.column(
                                "a.attname"
                            )
                        ],
                        orderBy: [
                            PSQL.asc(
                                .column(
                                    "a.attnum"
                                )
                            )
                        ]
                    )

                try Expect.equal(
                    expression.render(
                        &context
                    ),
                    "pg_catalog.jsonb_agg(\"a\".\"attname\" ORDER BY \"a\".\"attnum\" ASC)",
                    "composition.aggregate.order"
                )
            }

            Step("cross join supports lateral source") {
                let rendered = PSQL.Select(
                    [
                        PSQL.Ident.column(
                            "slot.generate_series"
                        )
                    ],
                    from:
                        "pg_catalog.pg_class",
                    as: "c"
                )
                .join(
                    PSQL.crossJoin(
                        source: PSQL.func_(
                            "pg_catalog.generate_series",
                            [
                                PSQL.integer(1),
                                PSQL.integer(3),
                            ]
                        ),
                        as: "slot",
                        lateral: true
                    )
                )
                .build()

                try Expect.contains(
                    rendered.sql,
                    """
                    CROSS JOIN LATERAL \
                    pg_catalog.generate_series(1, 3) \
                    AS "slot"
                    """,
                    "composition.lateral-cross-join"
                )
            }

            Step("FROM function supports explicit column alias") {
                let rendered = PSQL.Select(
                    [
                        PSQL.Ident.column(
                            "slot.subscript"
                        )
                    ],
                    from: PSQL.func_(
                        "pg_catalog.generate_subscripts",
                        [
                            PSQL.Ident.column(
                                "source.values"
                            ),
                            PSQL.integer(1),
                        ]
                    ),
                    as: "slot",
                    columns: [
                        "subscript"
                    ]
                )
                .build()

                try Expect.contains(
                    rendered.sql,
                    """
                    pg_catalog.generate_subscripts("source"."values", 1) \
                    AS "slot"("subscript")
                    """,
                    "composition.function-source.column-alias"
                )

                try Expect.contains(
                    rendered.sql,
                    """
                    SELECT "slot"."subscript"
                    """,
                    "composition.function-source.column-reference"
                )
            }

            Step("UNION ALL shares one bind context") {
                let first = PSQL.Select(
                    [
                        PSQL.val("first")
                    ],
                    from: "table_a"
                )

                let second = PSQL.Select(
                    [
                        PSQL.val("second")
                    ],
                    from: "table_b"
                )

                let rendered =
                    PSQL.unionAll(
                        first,
                        second
                    )
                    .build()

                try Expect.contains(
                    rendered.sql,
                    "$1",
                    "composition.union.first-bind"
                )

                try Expect.contains(
                    rendered.sql,
                    "$2",
                    "composition.union.second-bind"
                )

                try Expect.contains(
                    rendered.sql,
                    "UNION ALL",
                    "composition.union.operator"
                )

                try Expect.equal(
                    rendered.binds.count,
                    2,
                    "composition.union.bind-count"
                )
            }
        }
    }
}

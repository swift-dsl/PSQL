import TestFlows

enum PSQLFlowSuite:
    TestFlowRegistry
{
    static let title = "PSQL"

    static let flows: [TestFlow] = [
        compositionFlow,
    ]
}

import TestFlows

@main
enum PSQLTestFlowsMain {
    static func main() async {
        await TestFlowCLI.run(
            suite: PSQLFlowSuite.self
        )
    }
}

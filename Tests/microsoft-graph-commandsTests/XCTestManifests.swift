import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(microsoft_graph_commandsTests.allTests),
    ]
}
#endif

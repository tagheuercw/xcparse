import XCTest
import class Foundation.Bundle
@testable import testUtility
import XCParseCore

final class xcparseTests: XCTestCase {
    lazy var xcparseProcess: Process  = {
        let fooBinary = productsDirectory.appendingPathComponent("xcparse")
        let process = Process()
        process.executableURL = fooBinary
        return process
    }()

    /// Returns path to the built products directory.
    var productsDirectory: URL {
        #if os(macOS)
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        fatalError("couldn't find the products directory")
        #else
        return Bundle.main.bundleURL
        #endif
    }

    lazy var temporaryOutputDirectoryURL:URL  = {
        // Setup a temp test folder that can be used as a sandbox
        let tempDirectoryURL = FileManager.default.temporaryDirectory
        let temporaryOutputDirectoryName = ProcessInfo().globallyUniqueString
        let temporaryOutputDirectoryURL =
            tempDirectoryURL.appendingPathComponent(temporaryOutputDirectoryName)
        return temporaryOutputDirectoryURL
    }()

    static var allTests = [
        ("testScreenshots", testScreenshots),
        ("testDivideByTestPlanConfig",testDivideByTestPlanConfig),
        ("testDivideByIdentifier",testDivideByIdentifier),
        ("testDivideByOS",testDivideByOS),
        ("testDivideByModel",testDivideByModel),
        ("testDivideByLanguage",testDivideByLanguage),
        ("testDivideByRegion",testDivideByRegion),
        ("testDivideByTest",testDivideByTest),
        ("testGetTestsWithFailure",testGetTestsWithFailure),
        ("testScreenshotsHEIC", testScreenshotsHEIC),
        ("testScreenshotsMissingInput", testScreenshotsMissingInput),
        ("testGetCodeCoverage",testGetCodeCoverage),
        ("testCodeCoverageMissingInput",testCodeCoverageMissingInput),
        ("testGetLogs",testGetLogs),
        ("testLogsMissingInput",testLogsMissingInput),
        ("testDivideAttachmentsWithUTIFlags",testDivideAttachmentsWithUTIFlags),
        ("testAttachmentsHEIC",testAttachmentsHEIC),
        ("testAttachmentsMissingInput",testAttachmentsMissingInput),
        ("testPerfomanceMetrics",testPerformanceMetricsCategorySearch),
        ("testPerformanceMetricsSearchAlongTheRoad",testPerformanceMetricsSearchAlongTheRoad),
        ("testPerformanceMetricsUsualSearch",testPerformanceMetricsUsualSearch),
    ]

    func runAndWaitForXCParseProcess() throws  {
        try xcparseProcess.run()
        xcparseProcess.waitUntilExit()
    }

    override func tearDown() {
        if FileManager.default.fileExists(atPath: temporaryOutputDirectoryURL.path) {
            try? FileManager.default.removeItem(at: temporaryOutputDirectoryURL)
        }
        super.tearDown()
    }

    // MARK: - Metrics -

    func testPerformanceMetricsCategorySearch() throws {
        let file = try Resource(name: "testMetrics", type: "xcresult")
        let xcresultPath = file.url.path

        var xcresult = XCResult(path: xcresultPath)
        guard let invocationRecord = xcresult.invocationRecord else { return }

        guard let action = invocationRecord.actions.filter({ $0.actionResult.testsRef != nil }).first else { return }

        guard let testPlanRunSummaries: ActionTestPlanRunSummaries = action.actionResult.testsRef!.modelFromReference(withXCResult: xcresult) else { return }

        let testableSummaries = testPlanRunSummaries.summaries[0].testableSummaries

        let testSummaries = testableSummaries[0].flattenedTestSummaryMap(withXCResult: xcresult).map({ $0.testSummary })
        let categorySearch = testSummaries.filter {
            guard let testName = $0.name else {
                return false
            }

            return testName == "testCategorySearch()"
        }

        for testSummary in categorySearch {
            for metric in testSummary.performanceMetrics {
                let perfMetricMeasurements = metric.measurements

                switch metric.metricType {
                case .ClockMonotonicTime:
                    XCTAssertEqual(perfMetricMeasurements, [6.109e-06, 6.273000000000001e-06, 6.314e-06, 4.633e-06, 6.15e-06])
                    break
                case .CPUCycles:
                    XCTAssertEqual(perfMetricMeasurements, [1965.018, 2366.559, 2923.601, 2114.557, 3463.443])
                    break
                case .CPUInstructionsRetired:
                    XCTAssertEqual(perfMetricMeasurements, [3262.079, 3518.519, 3657.059, 3185.146, 4164.798])
                    break
                case .CPUTime:
                    XCTAssertEqual(perfMetricMeasurements, [0.001053659, 0.00140999, 0.0016860430000000001, 0.0012279090000000001, 0.002028352])
                    break
                case .DiskLogicalWrites:
                    XCTAssertEqual(perfMetricMeasurements, [0.0, 0.0, 49.152, 0.0, 0.0])
                    break
                case .MemoryPhysical:
                    XCTAssertEqual(perfMetricMeasurements, [32.768, 81.92, 98.304, 32.768, 32.768])
                    break
                case .MemoryPhysicalPeak:
                    XCTAssertEqual(perfMetricMeasurements, [0.0, 0.0, 0.0, 0.0, 0.0])
                    break
                default:
                    break
                }
            }
        }
    }

    func testPerformanceMetricsSearchAlongTheRoad() throws {
        let file = try Resource(name: "testMetrics", type: "xcresult")
        let xcresultPath = file.url.path

        var xcresult = XCResult(path: xcresultPath)
        guard let invocationRecord = xcresult.invocationRecord else { return }

        guard let action = invocationRecord.actions.filter({ $0.actionResult.testsRef != nil }).first else { return }

        guard let testPlanRunSummaries: ActionTestPlanRunSummaries = action.actionResult.testsRef!.modelFromReference(withXCResult: xcresult) else { return }

        let testableSummaries = testPlanRunSummaries.summaries[0].testableSummaries

        let testSummaries = testableSummaries[0].flattenedTestSummaryMap(withXCResult: xcresult).map({ $0.testSummary })
        let categorySearch = testSummaries.filter {
            guard let testName = $0.name else {
                return false
            }

            return testName == "testSearchAlongTheRoad()"
        }

        for testSummary in categorySearch {
            for metric in testSummary.performanceMetrics {
                let perfMetricMeasurements = metric.measurements

                switch metric.metricType {
                case .MemoryPhysical:
                    XCTAssertEqual(perfMetricMeasurements, [0.0, 16.384, 0.0, 0.0, 0.0])
                    break
                case .MemoryPhysicalPeak:
                    XCTAssertEqual(perfMetricMeasurements, [0.0, 0.0, 0.0, 0.0, 0.0])
                    break
                default:
                    break
                }
            }
        }
    }

    func testPerformanceMetricsUsualSearch() throws {
        let file = try Resource(name: "testMetrics", type: "xcresult")
        let xcresultPath = file.url.path

        var xcresult = XCResult(path: xcresultPath)
        guard let invocationRecord = xcresult.invocationRecord else { return }

        guard let action = invocationRecord.actions.filter({ $0.actionResult.testsRef != nil }).first else { return }

        guard let testPlanRunSummaries: ActionTestPlanRunSummaries = action.actionResult.testsRef!.modelFromReference(withXCResult: xcresult) else { return }

        let testableSummaries = testPlanRunSummaries.summaries[0].testableSummaries

        let testSummaries = testableSummaries[0].flattenedTestSummaryMap(withXCResult: xcresult).map({ $0.testSummary })
        let categorySearch = testSummaries.filter {
            guard let testName = $0.name else {
                return false
            }

            return testName == "testUsualSearch()"
        }

        for testSummary in categorySearch {
            for metric in testSummary.performanceMetrics {
                let perfMetricMeasurements = metric.measurements

                switch metric.metricType {
                case .MemoryPhysical:
                    XCTAssertEqual(perfMetricMeasurements, [0.0, 16.384, 147.456, 32.768, 65.536])
                    break
                case .MemoryPhysicalPeak:
                    XCTAssertEqual(perfMetricMeasurements, [0.0, 0.0, 0.0, 0.0, 0.0])
                    break
                default:
                    break
                }
            }
        }
    }

    // MARK: - Command - Screenshots

    func testScreenshots() throws {

        // Some of the APIs that we use below are available in macOS 10.13 and above.
        guard #available(macOS 10.13, *) else {
            return
        }

        let file = try Resource(name: "testSuccess", type: "xcresult")
        xcparseProcess.arguments = ["screenshots",file.url.path,temporaryOutputDirectoryURL.path]

        try runAndWaitForXCParseProcess()

        // check for the files
        let fileUrls = FileManager.default.listFiles(path: temporaryOutputDirectoryURL.path)

        XCTAssertTrue(fileUrls.count ==  6)
        XCTAssertTrue(fileUrls.filter{$0.path.contains("MyAutomation_darkMapView")}.count == 3)
        XCTAssertTrue(fileUrls.filter{$0.path.contains("MyAutomation_todayWidget")}.count == 3)
    }

    func testDivideByTestPlanConfig() throws {
        // Some of the APIs that we use below are available in macOS 10.13 and above.
        guard #available(macOS 10.13, *) else {
            return
        }

        let file = try Resource(name: "testSuccess", type: "xcresult")
        xcparseProcess.arguments = ["screenshots","--test-plan-config",file.url.path,temporaryOutputDirectoryURL.path]

        try runAndWaitForXCParseProcess()

        // We have three configurations ko, en, de
        //  check for files under ko
        var fileUrls = FileManager.default.listFiles(path: temporaryOutputDirectoryURL.appendingPathComponent("ko").path)
        XCTAssertTrue(fileUrls.count == 2)
        XCTAssertTrue(fileUrls.filter{$0.path.contains("MyAutomation_darkMapView")}.count == 1)
        XCTAssertTrue(fileUrls.filter{$0.path.contains("MyAutomation_todayWidget")}.count == 1)
        // check for files under en
        fileUrls = FileManager.default.listFiles(path: temporaryOutputDirectoryURL.appendingPathComponent("en").path)
        XCTAssertTrue(fileUrls.count == 2)
        XCTAssertTrue(fileUrls.filter{$0.path.contains("MyAutomation_darkMapView")}.count == 1)
        XCTAssertTrue(fileUrls.filter{$0.path.contains("MyAutomation_todayWidget")}.count == 1)
        // check for files under de
        fileUrls = FileManager.default.listFiles(path: temporaryOutputDirectoryURL.appendingPathComponent("de").path)
        XCTAssertTrue(fileUrls.count == 2)
        XCTAssertTrue(fileUrls.filter{$0.path.contains("MyAutomation_darkMapView")}.count == 1)
        XCTAssertTrue(fileUrls.filter{$0.path.contains("MyAutomation_todayWidget")}.count == 1)

    }

    func testDivideByIdentifier() throws {
        // Some of the APIs that we use below are available in macOS 10.13 and above.
        guard #available(macOS 10.13, *) else {
            return
        }

        let file = try Resource(name: "testSuccess", type: "xcresult")
        xcparseProcess.arguments = ["screenshots","--identifier",file.url.path,temporaryOutputDirectoryURL.path]

        try runAndWaitForXCParseProcess()

        // check for the files. The device identifier in xcresult is BFB8C9E3-0E55-4E20-B332-091631DF4F90 for simulator
        // so we append "BFB8C9E3-0E55-4E20-B332-091631DF4F90" to temporary directory

        let fileUrls = FileManager.default.listFiles(path: temporaryOutputDirectoryURL.appendingPathComponent("BFB8C9E3-0E55-4E20-B332-091631DF4F90").path)

        XCTAssertTrue(fileUrls.count ==  6)
        XCTAssertTrue(fileUrls.filter{$0.path.contains("MyAutomation_darkMapView")}.count == 3)
        XCTAssertTrue(fileUrls.filter{$0.path.contains("MyAutomation_todayWidget")}.count == 3)
    }

    func testDivideByOS() throws {
        // Some of the APIs that we use below are available in macOS 10.13 and above.
        guard #available(macOS 10.13, *) else {
            return
        }

        let file = try Resource(name: "testSuccess", type: "xcresult")
        xcparseProcess.arguments = ["screenshots","--os",file.url.path,temporaryOutputDirectoryURL.path]

        try runAndWaitForXCParseProcess()

        // check for the files. The os in xcresult is 13.5 for simulator so we append
        // "13.5" to temporary directory

        let fileUrls = FileManager.default.listFiles(path: temporaryOutputDirectoryURL.appendingPathComponent("13.5").path)

        XCTAssertTrue(fileUrls.count ==  6)
        XCTAssertTrue(fileUrls.filter{$0.path.contains("MyAutomation_darkMapView")}.count == 3)
        XCTAssertTrue(fileUrls.filter{$0.path.contains("MyAutomation_todayWidget")}.count == 3)
    }

    func testDivideByModel() throws {
        // Some of the APIs that we use below are available in macOS 10.13 and above.
        guard #available(macOS 10.13, *) else {
            return
        }

        let file = try Resource(name: "testSuccess", type: "xcresult")
        xcparseProcess.arguments = ["screenshots","--model",file.url.path,temporaryOutputDirectoryURL.path]

        try runAndWaitForXCParseProcess()

        // check for the files. The model in xcresult is iPhone 11 for simulator so we append
        // "iPhone 11" to temporary directory

        let fileUrls = FileManager.default.listFiles(path: temporaryOutputDirectoryURL.appendingPathComponent("iPhone 11").path)

        XCTAssertTrue(fileUrls.count ==  6)
        XCTAssertTrue(fileUrls.filter{$0.path.contains("MyAutomation_darkMapView")}.count == 3)
        XCTAssertTrue(fileUrls.filter{$0.path.contains("MyAutomation_todayWidget")}.count == 3)
    }

    func testDivideByLanguage() throws {
        // Some of the APIs that we use below are available in macOS 10.13 and above.
        guard #available(macOS 10.13, *) else {
            return
        }

        let file = try Resource(name: "testSuccess", type: "xcresult")
        xcparseProcess.arguments = ["screenshots","--language",file.url.path,temporaryOutputDirectoryURL.path]

        try runAndWaitForXCParseProcess()

        // We have three languages ko, en, de
        //  check for files under ko
        var fileUrls = FileManager.default.listFiles(path: temporaryOutputDirectoryURL.appendingPathComponent("ko").path)
        XCTAssertTrue(fileUrls.count == 2)
        XCTAssertTrue(fileUrls.filter{$0.path.contains("MyAutomation_darkMapView")}.count == 1)
        XCTAssertTrue(fileUrls.filter{$0.path.contains("MyAutomation_todayWidget")}.count == 1)
        // check for files under en
        fileUrls = FileManager.default.listFiles(path: temporaryOutputDirectoryURL.appendingPathComponent("en").path)
        XCTAssertTrue(fileUrls.count == 2)
        XCTAssertTrue(fileUrls.filter{$0.path.contains("MyAutomation_darkMapView")}.count == 1)
        XCTAssertTrue(fileUrls.filter{$0.path.contains("MyAutomation_todayWidget")}.count == 1)
        // check for files under de
        fileUrls = FileManager.default.listFiles(path: temporaryOutputDirectoryURL.appendingPathComponent("de").path)
        XCTAssertTrue(fileUrls.count == 2)
        XCTAssertTrue(fileUrls.filter{$0.path.contains("MyAutomation_darkMapView")}.count == 1)
        XCTAssertTrue(fileUrls.filter{$0.path.contains("MyAutomation_todayWidget")}.count == 1)
    }

    func testDivideByRegion() throws {
        // Some of the APIs that we use below are available in macOS 10.13 and above.
        guard #available(macOS 10.13, *) else {
            return
        }

        let file = try Resource(name: "testSuccess", type: "xcresult")
        xcparseProcess.arguments = ["screenshots","--region",file.url.path,temporaryOutputDirectoryURL.path]

        try runAndWaitForXCParseProcess()

        // We have three regions US, KR, DE
        //  check for files under KR
        var fileUrls = FileManager.default.listFiles(path: temporaryOutputDirectoryURL.appendingPathComponent("KR").path)
        XCTAssertTrue(fileUrls.count == 2)
        XCTAssertTrue(fileUrls.filter{$0.path.contains("MyAutomation_darkMapView")}.count == 1)
        XCTAssertTrue(fileUrls.filter{$0.path.contains("MyAutomation_todayWidget")}.count == 1)
        // check for files under US
        fileUrls = FileManager.default.listFiles(path: temporaryOutputDirectoryURL.appendingPathComponent("US").path)
        XCTAssertTrue(fileUrls.count == 2)
        XCTAssertTrue(fileUrls.filter{$0.path.contains("MyAutomation_darkMapView")}.count == 1)
        XCTAssertTrue(fileUrls.filter{$0.path.contains("MyAutomation_todayWidget")}.count == 1)
        // check for files under DE
        fileUrls = FileManager.default.listFiles(path: temporaryOutputDirectoryURL.appendingPathComponent("DE").path)
        XCTAssertTrue(fileUrls.count == 2)
        XCTAssertTrue(fileUrls.filter{$0.path.contains("MyAutomation_darkMapView")}.count == 1)
        XCTAssertTrue(fileUrls.filter{$0.path.contains("MyAutomation_todayWidget")}.count == 1)
    }

    func testDivideByTest() throws {
        guard #available(macOS 10.13, *) else {
            return
        }

        let file = try Resource(name: "testSuccess", type: "xcresult")
        xcparseProcess.arguments = ["screenshots","--test",file.url.path,temporaryOutputDirectoryURL.path]

        try runAndWaitForXCParseProcess()

        // There are two tests testTodayWidgetScreenshot() and testMainViewScreenshot() under bitrise_screenshot_automationUITests
        //  check for files under KR
        var fileUrls = FileManager.default.listFiles(path: temporaryOutputDirectoryURL.appendingPathComponent("bitrise_screenshot_automationUITests").appendingPathComponent("testTodayWidgetScreenshot()").path)
        XCTAssertTrue(fileUrls.count == 3)
        XCTAssertTrue(fileUrls.filter{$0.path.contains("MyAutomation_todayWidget")}.count == 3)
        // check for files under US
        fileUrls = FileManager.default.listFiles(path: temporaryOutputDirectoryURL.appendingPathComponent("bitrise_screenshot_automationUITests").appendingPathComponent("testMainViewScreenshot()").path)
        XCTAssertTrue(fileUrls.count == 3)
        XCTAssertTrue(fileUrls.filter{$0.path.contains("MyAutomation_darkMapView")}.count == 3)

    }

    func testGetTestsWithFailure() throws {
        guard #available(macOS 10.13, *) else {
            return
        }

        let file = try Resource(name: "testFailure", type: "xcresult")
        xcparseProcess.arguments = ["screenshots",file.url.path,temporaryOutputDirectoryURL.path,"--test-status", "Failure"]

        try runAndWaitForXCParseProcess()
        let fileUrls = FileManager.default.listFiles(path: temporaryOutputDirectoryURL.path)
        XCTAssertTrue(fileUrls.filter{$0.path.contains("Screenshot")}.count == 12)
    }

    func testScreenshotsHEIC() throws {
        guard #available(macOS 10.13, *) else {
            return
        }

        let file = try Resource(name: "testHEIC", type: "xcresult")
        xcparseProcess.arguments = ["screenshots", file.url.path, temporaryOutputDirectoryURL.path]

        try runAndWaitForXCParseProcess()
        let fileURLs = FileManager.default.listFiles(path: temporaryOutputDirectoryURL.path)
        let heicURLs = fileURLs.filter { $0.pathExtension == "heic" }
        XCTAssertTrue(heicURLs.count == 18)
    }

    func testScreenshotsMissingInput() throws {
        guard #available(macOS 10.13, *) else {
            return
        }

        xcparseProcess.arguments = ["screenshots", "/tmp", temporaryOutputDirectoryURL.path]

        let pipe = Pipe()
        xcparseProcess.standardError = pipe

        try runAndWaitForXCParseProcess()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)

        XCTAssertEqual(output, "Error: “/tmp” does not appear to be an xcresult\n")
    }

    // MARK: - Command - Code Coverage

    func testGetCodeCoverage() throws {
        guard #available(macOS 10.13, *) else {
            return
        }

        let file = try Resource(name: "testSuccess", type: "xcresult")
        xcparseProcess.arguments = ["codecov",file.url.path,temporaryOutputDirectoryURL.path]

        try runAndWaitForXCParseProcess()
        var fileUrls = FileManager.default.listFiles(path: temporaryOutputDirectoryURL.path)
        XCTAssertTrue(fileUrls.filter{$0.path.contains("action.xccovreport")}.count == 1)
        fileUrls = FileManager.default.listFiles(path: temporaryOutputDirectoryURL.appendingPathComponent("action.xccovarchive").path)
        XCTAssertTrue(fileUrls.count == 3)
        XCTAssertTrue(fileUrls.filter{$0.path.contains("Coverage")}.count == 1)
        XCTAssertTrue(fileUrls.filter{$0.path.contains("Index")}.count == 1)
        XCTAssertTrue(fileUrls.filter{$0.path.contains("Metadata.plist")}.count == 1)

    }

    func testCodeCoverageMissingInput() throws {
        guard #available(macOS 10.13, *) else {
            return
        }

        xcparseProcess.arguments = ["codecov", "/tmp", temporaryOutputDirectoryURL.path]

        let pipe = Pipe()
        xcparseProcess.standardError = pipe

        try runAndWaitForXCParseProcess()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)

        XCTAssertEqual(output, "Error: “/tmp” does not appear to be an xcresult\n")
    }

    // MARK: - Command - Logs

    func testGetLogs() throws {
        guard #available(macOS 10.13, *) else {
            return
        }

        let file = try Resource(name: "testSuccess", type: "xcresult")
        xcparseProcess.arguments = ["logs",file.url.path,temporaryOutputDirectoryURL.path]

        try runAndWaitForXCParseProcess()
        var fileUrls = FileManager.default.listFiles(path: temporaryOutputDirectoryURL.appendingPathComponent("1_Test").path)
        XCTAssertTrue(fileUrls.filter{$0.path.contains("action.txt")}.count == 1)
        XCTAssertTrue(fileUrls.filter{$0.path.contains("build.txt")}.count == 1)
        fileUrls = FileManager.default.listFiles(path: temporaryOutputDirectoryURL.appendingPathComponent("1_Test").appendingPathComponent("Diagnostics").path)
        XCTAssertTrue(fileUrls.count > 0)
    }

    func testLogsMissingInput() throws {
        guard #available(macOS 10.13, *) else {
            return
        }

        xcparseProcess.arguments = ["logs", "/tmp", temporaryOutputDirectoryURL.path]

        let pipe = Pipe()
        xcparseProcess.standardError = pipe

        try runAndWaitForXCParseProcess()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)

        XCTAssertEqual(output, "Error: “/tmp” does not appear to be an xcresult\n")
    }

    // MARK: - Command - Attachments

    func testDivideAttachmentsWithUTIFlags() throws {
        guard #available(macOS 10.13, *) else {
            return
        }

        let file = try Resource(name: "testSuccess", type: "xcresult")
        xcparseProcess.arguments = ["attachments",file.url.path,temporaryOutputDirectoryURL.path,"--uti", "public.plain-text","public.image"]

        try runAndWaitForXCParseProcess()
        let fileUrls = FileManager.default.listFiles(path: temporaryOutputDirectoryURL.path)
        XCTAssertTrue(fileUrls.filter{$0.path.contains("MyAutomation_todayWidget")}.count == 3)
        XCTAssertTrue(fileUrls.filter{$0.path.contains("MyAutomation_darkMapView")}.count == 3)
    }

    func testAttachmentsHEIC() throws {
        guard #available(macOS 10.13, *) else {
            return
        }

        let file = try Resource(name: "testHEIC", type: "xcresult")
        xcparseProcess.arguments = ["attachments", file.url.path, temporaryOutputDirectoryURL.path]

        try runAndWaitForXCParseProcess()
        let fileURLs = FileManager.default.listFiles(path: temporaryOutputDirectoryURL.path)
        let heicURLs = fileURLs.filter { $0.pathExtension == "heic" }
        XCTAssertTrue(heicURLs.count == 18)
    }

    func testAttachmentsMissingInput() throws {
        guard #available(macOS 10.13, *) else {
            return
        }

        xcparseProcess.arguments = ["attachments", "/tmp", temporaryOutputDirectoryURL.path]

        let pipe = Pipe()
        xcparseProcess.standardError = pipe

        try runAndWaitForXCParseProcess()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)

        XCTAssertEqual(output, "Error: “/tmp” does not appear to be an xcresult\n")
    }
}

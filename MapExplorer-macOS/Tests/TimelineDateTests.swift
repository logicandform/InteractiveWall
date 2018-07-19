//  Copyright © 2018 JABT. All rights reserved.

import XCTest


@testable import MapExplorer_macOS
class TimelineDateTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }


    // MARK: Standard Format, Same Start/End

    func testStandardSingleDate() {
        let dateRange = TimelineRange("October 19, 2019")
        let expectedDay = CGFloat(19.0/31.0)
        let expectedMonth = 9
        let expectedYear = 2019
        if let startDay = dateRange.startDate.day, let endDay = dateRange.endDate.day, let startMonth = dateRange.startDate.month, let endMonth = dateRange.endDate.month, let startYear = dateRange.startDate.year, let endYear = dateRange.endDate.year {
            XCTAssert(startDay.isEqual(to: expectedDay))
            XCTAssert(endDay.isEqual(to: expectedDay))
            XCTAssert(startMonth == expectedMonth)
            XCTAssert(endMonth == expectedMonth)
            XCTAssert(startYear == expectedYear)
            XCTAssert(endYear == expectedYear)
            return
        }
        XCTAssert(false)
    }


    // MARK: Standard Format, Different Start/End

    func testDifferentStartEnd() {
        let dateRange = TimelineRange("October 19, 2019 - December 1, 2125")
        let expectedStartDay = CGFloat(19.0/31.0)
        let expectedEndDay = CGFloat(1.0/31.0)
        let expectedStartMonth = 9
        let expectedEndMonth = 11
        let expectedStartYear = 2019
        let expectedEndYear = 2125
        if let startDay = dateRange.startDate.day, let endDay = dateRange.endDate.day, let startMonth = dateRange.startDate.month, let endMonth = dateRange.endDate.month, let startYear = dateRange.startDate.year, let endYear = dateRange.endDate.year {
            XCTAssert(startDay == expectedStartDay)
            XCTAssert(endDay == expectedEndDay)
            XCTAssert(startMonth == expectedStartMonth)
            XCTAssert(endMonth == expectedEndMonth)
            XCTAssert(startYear == expectedStartYear)
            XCTAssert(endYear == expectedEndYear)
            return
        }
        XCTAssert(false)
    }


    // MARK: Different Date Components Missing

    func testSingleYearListed() {
        let dateRange = TimelineRange("February 7-14, 1958")
        let expectedMonth = 1
        let expectedStartDay = CGFloat(7.0/31.0)
        let expectedEndDay = CGFloat(14.0/31.0)
        let expectedYear = 1958
        if let startDay = dateRange.startDate.day, let endDay = dateRange.endDate.day, let startMonth = dateRange.startDate.month, let endMonth = dateRange.endDate.month, let startYear = dateRange.startDate.year, let endYear = dateRange.endDate.year {
            XCTAssert(startDay == expectedStartDay)
            XCTAssert(endDay == expectedEndDay)
            XCTAssert(startMonth == expectedMonth)
            XCTAssert(endMonth == expectedMonth)
            XCTAssert(startYear == expectedYear)
            XCTAssert(endYear == expectedYear)
            return
        }
        XCTAssert(false)
    }


    // MARK: Abbreviated Month Test

    func testAbbreviatedMonths() {
        let dateRange = TimelineRange("Apr. 25 - Jun. 13, 1784")
        let expectedStartDay = CGFloat(25.0/31.0)
        let expectedEndDay = CGFloat(13.0/31.0)
        let expectedStartMonth = 3
        let expectedEndMonth = 5
        let expectedYear = 1784
        if let startDay = dateRange.startDate.day, let endDay = dateRange.endDate.day, let startMonth = dateRange.startDate.month, let endMonth = dateRange.endDate.month, let startYear = dateRange.startDate.year, let endYear = dateRange.endDate.year {
            XCTAssert(startDay == expectedStartDay)
            XCTAssert(endDay == expectedEndDay)
            XCTAssert(startMonth == expectedStartMonth)
            XCTAssert(endMonth == expectedEndMonth)
            XCTAssert(startYear == expectedYear)
            XCTAssert(endYear == expectedYear)
            return
        }
        XCTAssert(false)
    }


    // MARK: Numerical Date Test

    func testOneNumericalDate() {
        let dateRange = TimelineRange("30-12-1932")
        let expectedDay = CGFloat(30.0/31.0)
        let expectedMonth = 11
        let expectedYear = 1932
        if let startDay = dateRange.startDate.day, let endDay = dateRange.endDate.day, let startMonth = dateRange.startDate.month, let endMonth = dateRange.endDate.month, let startYear = dateRange.startDate.year, let endYear = dateRange.endDate.year {
            XCTAssert(startDay == expectedDay)
            XCTAssert(endDay == expectedDay)
            XCTAssert(startMonth == expectedMonth)
            XCTAssert(endMonth == expectedMonth)
            XCTAssert(startYear == expectedYear)
            XCTAssert(endYear == expectedYear)
            return
        }
        XCTAssert(false)
    }

    func testTwoNumericalDates() {
        let dateRange = TimelineRange("30.12.1932-6.05.1968")
        let expectedStartDay = CGFloat(30.0/31.0)
        let expectedEndDay = CGFloat(6.0/31.0)
        let expectedStartMonth = 11
        let expectedEndMonth = 4
        let expectedStartYear = 1932
        let expectedEndYear = 1968
        if let startDay = dateRange.startDate.day, let endDay = dateRange.endDate.day, let startMonth = dateRange.startDate.month, let endMonth = dateRange.endDate.month, let startYear = dateRange.startDate.year, let endYear = dateRange.endDate.year {
            XCTAssert(startDay == expectedStartDay)
            XCTAssert(endDay == expectedEndDay)
            XCTAssert(startMonth == expectedStartMonth)
            XCTAssert(endMonth == expectedEndMonth)
            XCTAssert(startYear == expectedStartYear)
            XCTAssert(endYear == expectedEndYear)
            return
        }
        XCTAssert(false)
    }
}

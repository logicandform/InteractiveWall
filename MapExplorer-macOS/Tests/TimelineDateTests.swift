//  Copyright © 2018 JABT. All rights reserved.

import XCTest


@testable import MapExplorer_macOS
class TimelineDateTests: XCTestCase {

    // MARK: Standard Format, Same Start/End

    func testStandardSingleDate() {
        guard let dateRange = TimelineRange("October 19, 2019") else {
            XCTAssert(false)
            return
        }

        let expectedDay = CGFloat(18.0/30.0)
        let expectedMonth = 9
        let expectedYear = 2019
        XCTAssert(dateRange.startDate.day.isEqual(to: expectedDay))
        XCTAssert(dateRange.endDate.day.isEqual(to: expectedDay))
        XCTAssert(dateRange.startDate.month == expectedMonth)
        XCTAssert(dateRange.endDate.month == expectedMonth)
        XCTAssert(dateRange.startDate.year == expectedYear)
        XCTAssert(dateRange.endDate.year == expectedYear)
    }

    func testStandardSingleDateTwo() {
        guard let dateRange = TimelineRange("August 19th, 1976") else {
            XCTAssert(false)
            return
        }

        let expectedDay = CGFloat(18.0/30.0)
        let expectedMonth = 7
        let expectedYear = 1976
        XCTAssert(dateRange.startDate.day.isEqual(to: expectedDay))
        XCTAssert(dateRange.endDate.day.isEqual(to: expectedDay))
        XCTAssert(dateRange.startDate.month == expectedMonth)
        XCTAssert(dateRange.endDate.month == expectedMonth)
        XCTAssert(dateRange.startDate.year == expectedYear)
        XCTAssert(dateRange.endDate.year == expectedYear)
    }

    func testStandardSingleDateThree() {
        guard let dateRange = TimelineRange("11th May, 2010") else {
            XCTAssert(false)
            return
        }

        let expectedDay = CGFloat(10.0/30.0)
        let expectedMonth = 4
        let expectedYear = 2010
        XCTAssert(dateRange.startDate.day.isEqual(to: expectedDay))
        XCTAssert(dateRange.endDate.day.isEqual(to: expectedDay))
        XCTAssert(dateRange.startDate.month == expectedMonth)
        XCTAssert(dateRange.endDate.month == expectedMonth)
        XCTAssert(dateRange.startDate.year == expectedYear)
        XCTAssert(dateRange.endDate.year == expectedYear)
    }


    // MARK: Standard Format, Different Start/End

    func testDifferentStartEnd() {
        guard let dateRange = TimelineRange("January 31, 2019 - December 1, 2125") else {
            XCTAssert(false)
            return
        }

        let expectedStartDay = CGFloat(30.0/30.0)
        let expectedEndDay = CGFloat(0.0/30.0)
        let expectedStartMonth = 0
        let expectedEndMonth = 11
        let expectedStartYear = 2019
        let expectedEndYear = 2125
        XCTAssert(dateRange.startDate.day == expectedStartDay)
        XCTAssert(dateRange.endDate.day == expectedEndDay)
        XCTAssert(dateRange.startDate.month == expectedStartMonth)
        XCTAssert(dateRange.endDate.month == expectedEndMonth)
        XCTAssert(dateRange.startDate.year == expectedStartYear)
        XCTAssert(dateRange.endDate.year == expectedEndYear)
    }

    func testDifferentStartEndTwo() {
        guard let dateRange = TimelineRange("June 28th, 2019 - March 1st, 2125") else {
            XCTAssert(false)
            return
        }

        let expectedStartDay = CGFloat(27.0/30.0)
        let expectedEndDay = CGFloat(0.0/30.0)
        let expectedStartMonth = 5
        let expectedEndMonth = 2
        let expectedStartYear = 2019
        let expectedEndYear = 2125
        XCTAssert(dateRange.startDate.day == expectedStartDay)
        XCTAssert(dateRange.endDate.day == expectedEndDay)
        XCTAssert(dateRange.startDate.month == expectedStartMonth)
        XCTAssert(dateRange.endDate.month == expectedEndMonth)
        XCTAssert(dateRange.startDate.year == expectedStartYear)
        XCTAssert(dateRange.endDate.year == expectedEndYear)
    }

    func testDifferentStartEndThree() {
        guard let dateRange = TimelineRange("1st January, 2019 - 2nd February, 2125") else {
            XCTAssert(false)
            return
        }

        let expectedStartDay = CGFloat(0.0/30.0)
        let expectedEndDay = CGFloat(1.0/30.0)
        let expectedStartMonth = 0
        let expectedEndMonth = 1
        let expectedStartYear = 2019
        let expectedEndYear = 2125
        XCTAssert(dateRange.startDate.day == expectedStartDay)
        XCTAssert(dateRange.endDate.day == expectedEndDay)
        XCTAssert(dateRange.startDate.month == expectedStartMonth)
        XCTAssert(dateRange.endDate.month == expectedEndMonth)
        XCTAssert(dateRange.startDate.year == expectedStartYear)
        XCTAssert(dateRange.endDate.year == expectedEndYear)
    }


    // MARK: Different Date Components Missing

    func testSingleYearListed() {
        guard let dateRange = TimelineRange("February 7-14, 1958") else {
            XCTAssert(false)
            return
        }

        let expectedMonth = 1
        let expectedStartDay = CGFloat(6.0/30.0)
        let expectedEndDay = CGFloat(13.0/30.0)
        let expectedYear = 1958
        XCTAssert(dateRange.startDate.day == expectedStartDay)
        XCTAssert(dateRange.endDate.day == expectedEndDay)
        XCTAssert(dateRange.startDate.month == expectedMonth)
        XCTAssert(dateRange.endDate.month == expectedMonth)
        XCTAssert(dateRange.startDate.year == expectedYear)
        XCTAssert(dateRange.endDate.year == expectedYear)
    }


    // MARK: Abbreviated Month Test

    func testAbbreviatedMonths() {
        guard let dateRange = TimelineRange("Apr. 25 - Jun. 13, 1784") else {
            XCTAssert(false)
            return
        }

        let expectedStartDay = CGFloat(24.0/30.0)
        let expectedEndDay = CGFloat(12.0/30.0)
        let expectedStartMonth = 3
        let expectedEndMonth = 5
        let expectedYear = 1784
        XCTAssert(dateRange.startDate.day == expectedStartDay)
        XCTAssert(dateRange.endDate.day == expectedEndDay)
        XCTAssert(dateRange.startDate.month == expectedStartMonth)
        XCTAssert(dateRange.endDate.month == expectedEndMonth)
        XCTAssert(dateRange.startDate.year == expectedYear)
        XCTAssert(dateRange.endDate.year == expectedYear)
    }


    // MARK: Numerical Date Test

    func testOneNumericalDate() {
        guard let dateRange = TimelineRange("30-12-1932") else {
            XCTAssert(false)
            return
        }

        let expectedDay = CGFloat(29.0/30.0)
        let expectedMonth = 11
        let expectedYear = 1932
        XCTAssert(dateRange.startDate.day == expectedDay)
        XCTAssert(dateRange.endDate.day == expectedDay)
        XCTAssert(dateRange.startDate.month == expectedMonth)
        XCTAssert(dateRange.endDate.month == expectedMonth)
        XCTAssert(dateRange.startDate.year == expectedYear)
        XCTAssert(dateRange.endDate.year == expectedYear)
    }

    func testTwoNumericalDates() {
        guard let dateRange = TimelineRange("30.12.1932-6.05.1968") else {
            XCTAssert(false)
            return
        }

        let expectedStartDay = CGFloat(29.0/30.0)
        let expectedEndDay = CGFloat(5.0/30.0)
        let expectedStartMonth = 11
        let expectedEndMonth = 4
        let expectedStartYear = 1932
        let expectedEndYear = 1968
        XCTAssert(dateRange.startDate.day == expectedStartDay)
        XCTAssert(dateRange.endDate.day == expectedEndDay)
        XCTAssert(dateRange.startDate.month == expectedStartMonth)
        XCTAssert(dateRange.endDate.month == expectedEndMonth)
        XCTAssert(dateRange.startDate.year == expectedStartYear)
        XCTAssert(dateRange.endDate.year == expectedEndYear)
    }

    func testNumericalDateTwo() {
        guard let dateRange = TimelineRange("30/12/1932") else {
            XCTAssert(false)
            return
        }

        let expectedDay = CGFloat(29.0/30.0)
        let expectedMonth = 11
        let expectedYear = 1932
        XCTAssert(dateRange.startDate.day == expectedDay)
        XCTAssert(dateRange.endDate.day == expectedDay)
        XCTAssert(dateRange.startDate.month == expectedMonth)
        XCTAssert(dateRange.endDate.month == expectedMonth)
        XCTAssert(dateRange.startDate.year == expectedYear)
        XCTAssert(dateRange.endDate.year == expectedYear)
    }

    func testTwoNumericalDatesTwo() {
        guard let dateRange = TimelineRange("30/12/1932-6/05/1968") else {
            XCTAssert(false)
            return
        }

        let expectedStartDay = CGFloat(29.0/30.0)
        let expectedEndDay = CGFloat(5.0/30.0)
        let expectedStartMonth = 11
        let expectedEndMonth = 4
        let expectedStartYear = 1932
        let expectedEndYear = 1968
        XCTAssert(dateRange.startDate.day == expectedStartDay)
        XCTAssert(dateRange.endDate.day == expectedEndDay)
        XCTAssert(dateRange.startDate.month == expectedStartMonth)
        XCTAssert(dateRange.endDate.month == expectedEndMonth)
        XCTAssert(dateRange.startDate.year == expectedStartYear)
        XCTAssert(dateRange.endDate.year == expectedEndYear)
    }

    func testNoInput() {
        if TimelineRange("") == nil {
            XCTAssert(true)
        } else {
        XCTAssert(false)
        }
    }
}

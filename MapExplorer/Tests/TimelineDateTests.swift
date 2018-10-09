//  Copyright © 2018 JABT. All rights reserved.

import XCTest


@testable import MapExplorer_macOS
class RecordDateTests: XCTestCase {

    // MARK: Standard Format, Same Start/End

    func testStandardSingleDate() {
        guard let dateRange = DateRange(from: "October 19, 2019") else {
            XCTAssert(false)
            return
        }

        let expectedDay = CGFloat(19.0/31.0)
        let expectedMonth = 9
        let expectedYear = 2019
        XCTAssert(dateRange.startDate.day.isEqual(to: expectedDay))
        XCTAssert(dateRange.startDate.month == expectedMonth)
        XCTAssert(dateRange.startDate.year == expectedYear)
        XCTAssert(dateRange.endDate == nil)
        XCTAssert(Int(dateRange.startDate.day * 31) == 19)
        XCTAssert(dateRange.description == "Oct 19, 2019")
    }

    func testStandardSingleDateTwo() {
        guard let dateRange = DateRange(from: "August 19th, 1976") else {
            XCTAssert(false)
            return
        }

        let expectedDay = CGFloat(19.0/31.0)
        let expectedMonth = 7
        let expectedYear = 1976
        XCTAssert(dateRange.startDate.day.isEqual(to: expectedDay))
        XCTAssert(dateRange.startDate.month == expectedMonth)
        XCTAssert(dateRange.startDate.year == expectedYear)
        XCTAssert(dateRange.endDate == nil)
        XCTAssert(Int(dateRange.startDate.day * 31) == 19)
        XCTAssert(dateRange.description == "Aug 19, 1976")
    }

    func testStandardSingleDateThree() {
        guard let dateRange = DateRange(from: "11th May, 2010") else {
            XCTAssert(false)
            return
        }

        let expectedDay = CGFloat(11.0/31.0)
        let expectedMonth = 4
        let expectedYear = 2010
        XCTAssert(dateRange.startDate.day.isEqual(to: expectedDay))
        XCTAssert(dateRange.startDate.month == expectedMonth)
        XCTAssert(dateRange.startDate.year == expectedYear)
        XCTAssert(dateRange.endDate == nil)
        XCTAssert(Int(dateRange.startDate.day * 31) == 11)
        XCTAssert(dateRange.description == "May 11, 2010")
    }


    // MARK: Standard Format, Different Start/End

    func testDifferentStartEnd() {
        guard let dateRange = DateRange(from: "January 31, 2019 - December 1, 2125") else {
            XCTAssert(false)
            return
        }

        let expectedStartDay = CGFloat(31.0/31.0)
        let expectedEndDay = CGFloat(1.0/31.0)
        let expectedStartMonth = 0
        let expectedEndMonth = 11
        let expectedStartYear = 2019
        let expectedEndYear = 2125
        XCTAssert(dateRange.startDate.day == expectedStartDay)
        XCTAssert(dateRange.endDate?.day == expectedEndDay)
        XCTAssert(dateRange.startDate.month == expectedStartMonth)
        XCTAssert(dateRange.endDate?.month == expectedEndMonth)
        XCTAssert(dateRange.startDate.year == expectedStartYear)
        XCTAssert(dateRange.endDate?.year == expectedEndYear)
        XCTAssert(Int(dateRange.startDate.day * 31) == 31)
        if let endDate = dateRange.endDate {
            XCTAssert(Int(endDate.day * 31) == 1)
        } else {
            XCTAssert(false)
        }
        XCTAssert(dateRange.description == "Jan 31, 2019 - Dec 1, 2125")
    }

    func testDifferentStartEndTwo() {
        guard let dateRange = DateRange(from: "June 28th, 2019 - March 1st, 2125") else {
            XCTAssert(false)
            return
        }

        let expectedStartDay = CGFloat(28.0/31.0)
        let expectedEndDay = CGFloat(1.0/31.0)
        let expectedStartMonth = 5
        let expectedEndMonth = 2
        let expectedStartYear = 2019
        let expectedEndYear = 2125
        XCTAssert(dateRange.startDate.day == expectedStartDay)
        XCTAssert(dateRange.endDate?.day == expectedEndDay)
        XCTAssert(dateRange.startDate.month == expectedStartMonth)
        XCTAssert(dateRange.endDate?.month == expectedEndMonth)
        XCTAssert(dateRange.startDate.year == expectedStartYear)
        XCTAssert(dateRange.endDate?.year == expectedEndYear)
        XCTAssert(Int(dateRange.startDate.day * 31) == 28)
        if let endDate = dateRange.endDate {
            XCTAssert(Int(endDate.day * 31) == 1)
        } else {
            XCTAssert(false)
        }
        XCTAssert(dateRange.description == "June 28, 2019 - March 1, 2125")
    }

    func testDifferentStartEndThree() {
        guard let dateRange = DateRange(from: "1st January, 2019 - 2nd February, 2125") else {
            XCTAssert(false)
            return
        }

        let expectedStartDay = CGFloat(1.0/31.0)
        let expectedEndDay = CGFloat(2.0/31.0)
        let expectedStartMonth = 0
        let expectedEndMonth = 1
        let expectedStartYear = 2019
        let expectedEndYear = 2125
        XCTAssert(dateRange.startDate.day == expectedStartDay)
        XCTAssert(dateRange.endDate?.day == expectedEndDay)
        XCTAssert(dateRange.startDate.month == expectedStartMonth)
        XCTAssert(dateRange.endDate?.month == expectedEndMonth)
        XCTAssert(dateRange.startDate.year == expectedStartYear)
        XCTAssert(dateRange.endDate?.year == expectedEndYear)
        XCTAssert(Int(dateRange.startDate.day * 31) == 1)
        if let endDate = dateRange.endDate {
            XCTAssert(Int(endDate.day * 31) == 2)
        } else {
            XCTAssert(false)
        }
        XCTAssert(dateRange.description == "Jan 1, 2019 - Feb 2, 2125")
    }


    // MARK: Different Date Components Missing

    func testSingleYearListed() {
        guard let dateRange = DateRange(from: "February 7-14, 1958") else {
            XCTAssert(false)
            return
        }

        let expectedMonth = 1
        let expectedStartDay = CGFloat(7.0/31.0)
        let expectedEndDay = CGFloat(14.0/31.0)
        let expectedYear = 1958
        XCTAssert(dateRange.startDate.day == expectedStartDay)
        XCTAssert(dateRange.endDate?.day == expectedEndDay)
        XCTAssert(dateRange.startDate.month == expectedMonth)
        XCTAssert(dateRange.endDate?.month == expectedMonth)
        XCTAssert(dateRange.startDate.year == expectedYear)
        XCTAssert(dateRange.endDate?.year == expectedYear)
        XCTAssert(Int(dateRange.startDate.day * 31) == 7)
        if let endDate = dateRange.endDate {
            XCTAssert(Int(endDate.day * 31) == 14)
        } else {
            XCTAssert(false)
        }
        XCTAssert(dateRange.description == "Feb 7, 1958 - Feb 14, 1958")
    }


    // MARK: Abbreviated Month Test

    func testAbbreviatedMonths() {
        guard let dateRange = DateRange(from: "Apr. 25 - Jun. 13, 1784") else {
            XCTAssert(false)
            return
        }

        let expectedStartDay = CGFloat(25.0/31.0)
        let expectedEndDay = CGFloat(13.0/31.0)
        let expectedStartMonth = 3
        let expectedEndMonth = 5
        let expectedYear = 1784
        XCTAssert(dateRange.startDate.day == expectedStartDay)
        XCTAssert(dateRange.endDate?.day == expectedEndDay)
        XCTAssert(dateRange.startDate.month == expectedStartMonth)
        XCTAssert(dateRange.endDate?.month == expectedEndMonth)
        XCTAssert(dateRange.startDate.year == expectedYear)
        XCTAssert(dateRange.endDate?.year == expectedYear)
        XCTAssert(Int(dateRange.startDate.day * 31) == 25)
        if let endDate = dateRange.endDate {
            XCTAssert(Int(endDate.day * 31) == 13)
        } else {
            XCTAssert(false)
        }
        XCTAssert(dateRange.description == "April 25, 1784 - June 13, 1784")
    }


    // MARK: Numerical Date Test

    func testOneNumericalDate() {
        guard let dateRange = DateRange(from: "30-12-1932") else {
            XCTAssert(false)
            return
        }

        let expectedDay = CGFloat(30.0/31.0)
        let expectedMonth = 11
        let expectedYear = 1932
        XCTAssert(dateRange.startDate.day == expectedDay)
        XCTAssert(dateRange.startDate.month == expectedMonth)
        XCTAssert(dateRange.startDate.year == expectedYear)
        XCTAssert(Int(dateRange.startDate.day * 31) == 30)
        XCTAssert(dateRange.endDate == nil)
        XCTAssert(dateRange.description == "Dec 30, 1932")
    }

    func testTwoNumericalDates() {
        guard let dateRange = DateRange(from: "30.12.1932-6.05.1968") else {
            XCTAssert(false)
            return
        }

        let expectedStartDay = CGFloat(30.0/31.0)
        let expectedEndDay = CGFloat(6.0/31.0)
        let expectedStartMonth = 11
        let expectedEndMonth = 4
        let expectedStartYear = 1932
        let expectedEndYear = 1968
        XCTAssert(dateRange.startDate.day == expectedStartDay)
        XCTAssert(dateRange.endDate?.day == expectedEndDay)
        XCTAssert(dateRange.startDate.month == expectedStartMonth)
        XCTAssert(dateRange.endDate?.month == expectedEndMonth)
        XCTAssert(dateRange.startDate.year == expectedStartYear)
        XCTAssert(dateRange.endDate?.year == expectedEndYear)
        XCTAssert(Int(dateRange.startDate.day * 31) == 30)
        if let endDate = dateRange.endDate {
            XCTAssert(Int(endDate.day * 31) == 6)
        } else {
            XCTAssert(false)
        }
        XCTAssert(dateRange.description == "Dec 30, 1932 - May 6, 1968")
    }

    func testNumericalDateTwo() {
        guard let dateRange = DateRange(from: "30/12/1932") else {
            XCTAssert(false)
            return
        }

        let expectedDay = CGFloat(30.0/31.0)
        let expectedMonth = 11
        let expectedYear = 1932
        XCTAssert(dateRange.startDate.day == expectedDay)
        XCTAssert(dateRange.startDate.month == expectedMonth)
        XCTAssert(dateRange.startDate.year == expectedYear)
        XCTAssert(Int(dateRange.startDate.day * 31) == 30)
        XCTAssert(dateRange.endDate == nil)
        XCTAssert(dateRange.description == "Dec 30, 1932")
    }

    func testTwoNumericalDatesTwo() {
        guard let dateRange = DateRange(from: "30/12/1932-6/05/1968") else {
            XCTAssert(false)
            return
        }

        let expectedStartDay = CGFloat(30.0/31.0)
        let expectedEndDay = CGFloat(6.0/31.0)
        let expectedStartMonth = 11
        let expectedEndMonth = 4
        let expectedStartYear = 1932
        let expectedEndYear = 1968
        XCTAssert(dateRange.startDate.day == expectedStartDay)
        XCTAssert(dateRange.endDate?.day == expectedEndDay)
        XCTAssert(dateRange.startDate.month == expectedStartMonth)
        XCTAssert(dateRange.endDate?.month == expectedEndMonth)
        XCTAssert(dateRange.startDate.year == expectedStartYear)
        XCTAssert(dateRange.endDate?.year == expectedEndYear)
        XCTAssert(Int(dateRange.startDate.day * 31) == 30)
        if let endDate = dateRange.endDate {
            XCTAssert(Int(endDate.day * 31) == 6)
        } else {
            XCTAssert(false)
        }
        XCTAssert(dateRange.description == "Dec 30, 1932 - May 6, 1968")
    }

    func testNoInput() {
        if DateRange(from: "") == nil {
            XCTAssert(true)
        } else {
            XCTAssert(false)
        }
    }

    func testDayCalculation() {
        let max = 31.0
        let range = 1...31

        for num in range {
            let storedDay = Double(num) / max
            XCTAssert(num == Int(storedDay * max))
        }
    }
}

//
//  DepozaUITests.swift
//  DepozaUITests
//
//  Created by Igor Dorovskikh on 9/15/16.
//  Copyright © 2016 Ivan Magda. All rights reserved.
//

import XCTest

class DepozaUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testAddingNewExpense() {
        
        let app = XCUIApplication()
        app.buttons["add_button"].tap()
        
        let tablesQuery = app.tables
        tablesQuery.textFields["enter_amount"].tap()
        tablesQuery.textFields["enter_amount"].typeText("100")
        
        tablesQuery.staticTexts["Clothes"].tap()
        
        tablesQuery.textFields["enter_description"].tap()
        tablesQuery.textFields["enter_description"].typeText("t-shirt")
        app.navigationBars["Add Expense"].buttons["Done"].tap()
        
        let actual = tablesQuery.staticTexts["total_expenses_amount"].label
        XCTAssert(actual == "100")
    }
    
}

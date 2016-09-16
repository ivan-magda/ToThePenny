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
                continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["isUITesting"]
        app.launch()

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

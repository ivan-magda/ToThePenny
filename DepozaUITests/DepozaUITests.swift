//
//  DepozaUITests.swift
//  DepozaUITests
//
//  Created by Igor Dorovskikh on 9/15/16.
//  Copyright © 2016 Ivan Magda. All rights reserved.
//

import XCTest

class DepozaUITests: XCTestCase {
    let app = XCUIApplication()
    let clothes_expene = "t-shirt"
    let price = "100"
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false
        app.launchArguments = ["isUITesting"]
        app.launch()

    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testAddingNewExpense() {
        
        //let app = XCUIApplication()
        app.buttons["add_button"].tap()
        
        let tablesQuery = app.tables
        tablesQuery.textFields["enter_amount"].tap()
        tablesQuery.textFields["enter_amount"].typeText(price)
        
        tablesQuery.staticTexts["Clothes"].tap()
        
        let descriptionField = tablesQuery.textFields["enter_description"]
        
        waitAndTap(element: descriptionField, time: 2.0)
        descriptionField.typeText(clothes_expene)
        
        app.navigationBars["Add Expense"].buttons["Done"].tap()
        
        let actual = tablesQuery.staticTexts["total_expenses_amount"].label
        XCTAssert(actual == "100")
    }
    
    func testDeleteExpense() {
      testAddingNewExpense()
        
        let tablesQuery = app.tables
        let expense_cell = tablesQuery.cells["\(clothes_expene), \(price)"]

        waitAndTap(element: expense_cell, time: 3.0)
        
        let trashButton = app.navigationBars["Expense"].buttons["Trash"]
        trashButton.tap()
        
        let deleteButton = app.alerts["Delete transaction?"].buttons["Delete"]
        deleteButton.tap()
        
        let actual = tablesQuery.staticTexts["total_expenses_amount"].label
        
        XCTAssert(actual == "0")
    }
    
    func waitAndTap(element: XCUIElement, time: Double){
        let exists = NSPredicate(format: "exists == true")
        expectation(for: exists, evaluatedWith:element, handler: nil)
        element.tap()
        waitForExpectations(timeout: time, handler: nil)
    }
}

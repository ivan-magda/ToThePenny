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
        
        waitForElementToAppear(format: "isHittable == true", element: descriptionField, time: 2.0)
        
        descriptionField.tap()
        descriptionField.typeText(clothes_expene)
        
        app.navigationBars["Add Expense"].buttons["Done"].tap()
        
        let actual = tablesQuery.staticTexts["total_expenses_amount"].label
        XCTAssert(actual == "100")
    }
    
    func testDeleteExpense() {
        testAddingNewExpense()
        
        let tablesQuery = app.tables
        let expense_cell = tablesQuery.cells["cell_0"].staticTexts[clothes_expene]
        
        waitForElementToAppear(format: "isHittable == true", element: expense_cell, time: 3.0)
        
        expense_cell.tap()
        
        let trashButton = app.navigationBars["Expense"].buttons["Trash"]
        trashButton.tap()
        
        let deleteButton = app.alerts["Delete transaction?"].buttons["Delete"]
        deleteButton.tap()
        
        let total_ammount = tablesQuery.staticTexts["total_expenses_amount"]
        let actual = total_ammount.label
        
        waitForElementToAppear(format: "isEnabled == true", element: total_ammount, time: 3.0)
        
        print(actual)
        XCTAssert(actual == "0")
        
        waitForElementToAppear(format: "self.count = 1", element: tablesQuery, time: 3.0)
        
        
        XCTAssertEqual(tablesQuery.cells.count, 0 , "found instead: \(tablesQuery.cells.debugDescription)")
        
    }
    
    func waitForElementToAppear(format: String, element: AnyObject, time: Double){
        let exists = NSPredicate(format: format)
        expectation(for: exists, evaluatedWith:element, handler: nil)
        waitForExpectations(timeout: time, handler: nil)
    }
}

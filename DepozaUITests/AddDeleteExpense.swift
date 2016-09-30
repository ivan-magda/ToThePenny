//
//  DepozaUITests.swift
//  DepozaUITests
//
//  Created by Igor Dorovskikh on 9/15/16.
//  Copyright © 2016 Ivan Magda. All rights reserved.
//

import XCTest

class AddDeleteExpense: BaseTest {
    
    override func setUp() {
        super.setUp()
        
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testAddingNewExpense() {
        
        addNewExpense()
        
    }
    
    func testDeleteExpense() {
        addNewExpense()
        
        let expenses = ExpensesScreen()
        expenses.tapOnExpenseCell()
        
        let expenseScreen = ExpenseScreen()
        expenseScreen.tapOnTrashButton()
        expenseScreen.tapOnDeleteButton()
        
        let actual = expenses.totalExpenseAmount()
        
        XCTAssert(actual == "0", "Toral amount is \(actual)")
        
        print(actual)
        let table = expenses.tablesQuery()
        waitForElementToAppear(format: "self.count = 1", element: table, time: 3.0)
        
        XCTAssertEqual(table.cells.count, 0 , "found instead: \(table.cells.debugDescription)")
        
    }
    
}

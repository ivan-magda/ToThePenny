//
//  DepozaUITests.swift
//  DepozaUITests
//
//  Created by Igor Dorovskikh on 9/15/16.
//  Copyright © 2016 Ivan Magda. All rights reserved.
//

import XCTest

class DepozaUITests: BaseTest {
    
    override func setUp() {
        super.setUp()
        
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testAddingNewExpense() {
        
        let expenses = ExpensesScreen()
        expenses.tapOnAddExpenseButton()
        let addExpense = AddExpense()
        addExpense.typeAmount(amount: "100")
        addExpense.selectClothesCategory()
        addExpense.typeExpesneDescription(description: "t-shirt")
        addExpense.tapOnDoneButton()
    
        let actual = expenses.totalExpenseAmount()
        
        XCTAssert(actual == "100", "Toral amount is \(actual)")
    }
    
    func testDeleteExpense() {
        testAddingNewExpense()
        
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

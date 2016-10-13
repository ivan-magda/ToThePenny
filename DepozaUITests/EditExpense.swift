//
//  EditExpense.swift
//  Depoza
//
//  Created by Igor Dorovskikh on 9/28/16.
//  Copyright © 2016 Ivan Magda. All rights reserved.
//

import XCTest

class EditExpense: BaseTest {
    
    override func setUp() {
        super.setUp()
        
    }
    
    override func tearDown() {
        super.tearDown()
}
    
    
    func testEditDate(){
        
        let (day, month) = getFutureDate(daysFromToday: 20)
        print ("\(day) \(month)")
        
        addNewExpense()
        
        let expenses = ExpensesScreen()
        
        expenses.tapOnExpenseCell()
        
        let expenseDetailScreen = ExpenseScreen()
        expenseDetailScreen.tapOnEditButton()
        expenseDetailScreen.tapOnDateCell()
        expenseDetailScreen.selectDate(month: month, day: day)
        expenseDetailScreen.tapOnDoneButton()
        
        
        XCTAssert(expenseDetailScreen.getDateFromCell().contains("\(day) \(month)"), "found instead: \(expenseDetailScreen.getDateFromCell())")

   }
}

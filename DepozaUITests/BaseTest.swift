//
//  BaseTest.swift
//  Depoza
//
//  Created by Igor Dorovskikh on 9/23/16.
//  Copyright © 2016 Ivan Magda. All rights reserved.
//

import XCTest

class BaseTest : XCTestCase {
    
    let app = XCUIApplication()
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app.launchArguments = ["isUITesting"]
        app.launch()
        
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func waitForElementToAppear(format: String, element: AnyObject, time: Double){
        let exists = NSPredicate(format: format)
        expectation(for: exists, evaluatedWith:element, handler: nil)
        waitForExpectations(timeout: time, handler: nil)
        
    }
    
    func addNewExpense(){
        let expenses = ExpensesScreen()
        expenses.tapOnAddExpenseButton()
        let addExpense = AddExpense()
        addExpense.typeAmount(amount: "100")
        addExpense.selectClothesCategory()
        addExpense.typeExpesneDescription(description: "t-shirt")
        addExpense.tapOnDoneButton()
        
        waitForElementToAppear(format: "isHittable = true", element: expenses.expense_cell as AnyObject, time: 3.0)
        let actual = expenses.totalExpenseAmount()
        
        XCTAssert(actual == "100", "Toral amount is \(actual)")
    }
    
    func getFutureDate(daysFromToday: Int) -> (day : String, month : String){
        var components = DateComponents()
        components.setValue(daysFromToday, for: .day)
        
        let today = NSDate()
        let futureDate = NSCalendar.current.date(byAdding: components, to: today as Date)
        let futureDay = NSCalendar.current.component(.day, from: futureDate!)
        let futureDayString = String(futureDay)
        let futureMonth = NSCalendar.current.component( .month, from: futureDate!)
        
        let dateFormat = DateFormatter()
        let futureMonthString = dateFormat.shortMonthSymbols[futureMonth as Int - 1]
    
        return(futureDayString, futureMonthString )
    }
    
}

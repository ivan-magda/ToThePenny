//
//  AddExpense.swift
//  Depoza
//
//  Created by Igor Dorovskikh on 9/26/16.
//  Copyright © 2016 Ivan Magda. All rights reserved.
//

import XCTest

class AddExpense : BaseScreen {
    private let enterAmountField = XCUIApplication().tables.textFields["enter_amount"]
    private let clothesCategory = XCUIApplication().tables.staticTexts["Clothes"]
    private let descriptionField = XCUIApplication().tables.textFields["enter_description"]
    private let doneButton =  XCUIApplication().navigationBars["Add Expense"].buttons["Done"]
    
    override init(){
        enterAmountField.waitToExist()
    }
    
    func typeAmount(amount : String){
        type(string: amount, field: enterAmountField )
    }
    
    func selectClothesCategory(){
        tap(element: clothesCategory)
    }
    
    func typeExpesneDescription(description : String){
        if descriptionField.isVisible() {
            type(string: description, field:descriptionField)
        }
    }
    
    func tapOnDoneButton(){
        tap(element: doneButton)
    }
}


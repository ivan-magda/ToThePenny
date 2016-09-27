//
//  ExpenseScreen.swift
//  Depoza
//
//  Created by Igor Dorovskikh on 9/26/16.
//  Copyright © 2016 Ivan Magda. All rights reserved.
//






import XCTest

class ExpenseScreen : BaseScreen {
    private let trashButton = XCUIApplication().navigationBars["Expense"].buttons["Trash"]

    private let deleteButton = XCUIApplication().alerts["Delete transaction?"].buttons["Delete"]

    
    override init() {
        trashButton.waitToExist()
    }
    
    func tapOnTrashButton(){
        tap(element: trashButton)
    }
    
    func tapOnDeleteButton(){
        tap(element: deleteButton)
    }
    
}

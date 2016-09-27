//
//  BaseScreen.swift
//  Depoza
//
//  Created by Igor Dorovskikh on 9/23/16.
//  Copyright © 2016 Ivan Magda. All rights reserved.
//

import XCTest

class BaseScreen {
    
    func tablesQuery() -> XCUIElementQuery{
        return XCUIApplication().tables
    }

    
    func tap(element: XCUIElement){
            element.tap()
    }
    
    func type(string : String, field : XCUIElement){
        tap(element: field)
        field.typeText(string)
        
    }
}

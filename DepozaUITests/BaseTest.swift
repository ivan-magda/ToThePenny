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
    
}

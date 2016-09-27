//
//  XCUIElementExtension.swift
//  Tinder
//
//  Created by Igor Dorovskikh on 6/16/16.
//  Copyright © 2013 - 2016 Tinder, Inc., ALL RIGHTS RESERVED
//

import XCTest

private let defaultTimeoutInSeconds = 60.0

extension XCUIElement {
    func waitToExist() -> XCUIElement {
        let doesElementExist: () -> Bool = {
            return self.exists
        }
        waitFor(expression: doesElementExist, failureMessage: "Timed out waiting for element to exist.")
        return self
    }
    
    
    func isVisible() -> Bool {
        guard self.exists && !self.frame.isEmpty else { return false }
        return XCUIApplication().windows.element(boundBy: 0).frame.contains(self.frame)
    }

    
    private func waitFor(expression: () -> Bool, failureMessage: String) {
        let startTime = NSDate.timeIntervalSinceReferenceDate
        
        while !expression() {
            if NSDate.timeIntervalSinceReferenceDate - startTime > defaultTimeoutInSeconds {
                NSException(name: NSExceptionName(rawValue: "Timeout"), reason: failureMessage, userInfo: nil).raise()
            }
            CFRunLoopRunInMode(CFRunLoopMode.defaultMode, 0.1, true)
        }
    }
}

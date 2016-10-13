//: [Previous](@previous)

import Foundation
class BaseScreen {
    
    func exists(element: String) -> String{
        return element
    }

}
class HomeScreen : BaseScreen {
    
    private let add_button = "add_button"
    
    private let total_expenses = "total_expenses_amount"
    
    override init(){
        super.init()
        print (self.exists(element: total_expenses))
        print (self.exists(element: add_button))
    }
    
    
    func addNewExpense(){
        add_button //tap()
    }
}

var homeScreen = HomeScreen()

homeScreen.addNewExpense()


//: [Next](@next)

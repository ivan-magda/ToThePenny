//: [Previous](@previous)

import Foundation

var number: Int?

print (number)

let userEnteredText = "3"

let userEnteredInteger = Int(userEnteredText)

if let catAge = userEnteredInteger {
    
    print (catAge * 7)
    
} else {
    
    print (userEnteredText)
    
}

var date = "9 November 2016, 17:55"
var dateFormatter = DateFormatter()
dateFormatter.dateFormat = "dd MMM yyy, hh:mm"
let custom  = dateFormatter.date(from: date)



date.contains("9 Nov")


var components = DateComponents()
components.setValue(1, for: .month)

let today = NSDate()
var futureDate = NSCalendar.current.date(byAdding: components, to: today as Date)
var futureDay = NSCalendar.current.component(.day, from: futureDate!)
var futureMonth = NSCalendar.current.component( .month, from: futureDate!)

let dateFormat = DateFormatter()
let futureMonthString = dateFormat.shortMonthSymbols[futureMonth as Int - 1]




dateFormat.string(from: today as Date)


//let date =  NSDate()
//let calendar = NSCalendar.current
//var hour = calendar.component(.hour,from: NSDate() as Date)
//

//let expirationDate = Calendar.current.date(byAdding: components, to: date, options: [])

//: [Next](@next)

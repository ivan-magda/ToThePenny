//: [Previous](@previous)

import Foundation

let age = 13

// Greater than or equal to

if age >= 18 {
    
    print ("You can play!")
    
} else {
    
    print ("You're too young")
    
}

// Check username

let name = "igor"

if name == "igor" {
    
    print ("Hi " + name + "! You can play")
    
} else {
    
    print ("Sorry, " + name + ", you can't play")
    
}

// 2 If Statements With And

if name == "igor" && age >= 18 {
    
    print("you can play")
    
} else if name == "igor" {
    
    print("Sorry Igor, you need to get older")
    
}

// 2 If Statements With Or

if name == "igor" || name == "kirsten" {
    
    print ("Welcome " + name)
    
}

// Booleans With If Statements

let isMale = true

if isMale {
    
    print("You're male!")
    
}


//: [Next](@next)

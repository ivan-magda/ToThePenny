//: [Previous](@previous)

import Foundation

let array = [8, 4, 8 , 1]

for number in array {
    
    print(number)
    
}

// Create an array with 4 names of friends/family print "Hi there --- !"

let familyMembers = ["Igor", "Kirsten", "Tommy", "Alex"]

for familyMember in familyMembers {
    
    print ("Hi there " + familyMember + "!")
    
}

var numbers = [7, 2, 9, 4, 1]

for (index, value) in numbers.enumerated() {
    
    numbers[index] += 1
    
}

print (numbers)


//: [Next](@next)

//: [Previous](@previous)

import Foundation

// Array

var array = [35, 36, 5, 2]

print (array[0])

print (array.count)

array.append(1)

array.remove(at: 1)

array.sort()

print (array)


var myArray = [3.87, 7.1, 8.9]

myArray.remove(at: 1)

myArray.append(myArray[0] * myArray[1])

let mixArray = ["Igor", 35, true] as Any // Added "as Any" for Swift 3.0

//create empty array of Strings only
let stringArray = [String]()



// Dictionary

var dictionary = ["shirt": "$12", "coffee": "$1.5"]

print (dictionary["shirt"])

print (dictionary.count)

dictionary["pen"] = "$3"

dictionary.removeValue(forKey: "shirt")

print (dictionary)

//use Decinal if you want precise value

var gameCharacters = [String: Decimal]()

gameCharacters["ghost"] = 8.7

print(gameCharacters)




//: [Next](@next)

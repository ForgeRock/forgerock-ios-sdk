import UIKit

var greeting = "Hello, playground"


class Singleton {
    static let shared = Singleton()
    
    var data = 3
}

Singleton.shared.data = 5

print(Singleton.shared.data)

let foo = Singleton.shared
foo.data = 6

print(foo.data)
print(Singleton.shared.data)



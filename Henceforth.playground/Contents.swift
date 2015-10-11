
import XCPlayground
import Forthwith
import Life

//:# The Game of Life
//:## *In Swift Forthwith*

//: First, we create a empty `Stack` of Forthwith's `Cell`s
let s = Stack<Cell>()

//s .. "Start" .. dot .. cr .. printWorld .. 30 .. 0 .. loopCnt(simulate)

// Okay kinda cool, now lets make it work with Cocoa

let rect = NSRect(x: 0, y: 0, width: 300, height: 161)
let l = LifeView(frame: rect)
let simulateView = { $0 .. updateWorld .. l .. rect .. LifeView.setNeedsDisplayInRect .. UInt32(100000) .. usleep }

//: Looping this way lets the playground figure out we want to display all the values.
for _ in 0..<30 {
    s .. simulateView
    l
}


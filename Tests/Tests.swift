//
//  Tests.swift
//  ForthwithTests
//
//  Created by Andrew Snow on 10/3/15.
//  Copyright © 2015 Andrew Snow. All rights reserved.
//

import XCTest
@testable import Forthwith

class ForthwithTests: XCTestCase {
    
    let s = Stack<Cell>()
    
    override func setUp() {
        super.setUp()
        s .. dropAll
    }
    
    func testFibonacci() {
        // Calculate the 92nd fibonacci number.
        s .. 92 .. fib
        let fib92 = 7540113804746346429
        XCTAssert(s.pop(Int) == fib92)
    }
    
    func testString() {
        // Tests applying methods.
        s .. "This is my super test string. It is really great, isn't it?"
        s .. ddup .. "This"
        s .. String.hasPrefix .. swap
        s .. ddup .. "?" .. String.hasSuffix .. swap
        s .. ddup .. "Shall not be found." .. String.containsString .. swap
        s .. drop
        s .. printStack
    }
    
    func testControlFlow() {
        let t = Stack<Cell>()
        // An alternative way of handling control flow is to punt it to the user...
        t .. true .. { if $0 { print("WE REJECT THE NULL HYPOTHESIS!") } else { print("More study is needed.") } } as (Bool) -> ()

        t .. true .. `if`({$0 .. true}, `else`: {$0 .. false})
        t .. `while` {
            print("This executes once.")
            return $0 .. 0 .. 10 .. 0 .. false
            } .. loop {
                $0 .. 1 .. (+) .. ddup .. dot .. cr
        }
    }
    
    func testStars() {
        typealias       Word = (Stack<Cell>) -> () // Define it locally because of ambiguities with Swift.Word
        let star      = { $0 .. 42 .. emit }
        let stars     = { $0 .. 0 .. loop(star) .. cr }
        let square    = { $0 .. ddup .. 0 .. loop { $0 .. ddup .. stars } .. drop }
        let triangle  = { $0 .. 1 .. loopCnt { $0 .. stars } }
        let tower     = { $0 .. ddup .. triangle .. square }
        s .. cr .. 6 .. tower
        
        // Compare with Forth:
        // : STAR	            42 EMIT ;
        // : STARS              0 DO STAR LOOP CR ;
        // : SQUARE             DUP 0 DO DUP STARS LOOP DROP ;
        // : TRIANGLE           1 DO I STARS LOOP ;
        // : TOWER ( n -- )     DUP TRIANGLE SQUARE ;
        // CR 6 TOWER
    }
    
    func testBasics() {
        s .. 5 .. 4 .. (+) .. printStack
        let p = s .. 5
        func adder(a: Int, _ b: Int) -> Int { return a + b }
        func doubler(a: Double) -> Double { return 2*a }
        p .. 3.1415
        p .. printStack
        p.push(doubler)
        p .. printStack
        p .. 0.1 .. 0.2 .. 0.3 .. fma as ((Double, Double, Double) -> Double) .. printStack
    }
    
    func testLife() {
        let pattern = [
            ["_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_"],
            ["_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_"],
            ["_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_"],
            ["_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_"],
            ["_", "_", "_", "_", "_", "_", "_", "X", "_", "_", "_", "X", "_", "_", "_", "_", "_", "_", "_", "_"],
            ["_", "_", "_", "_", "_", "_", "_", "X", "_", "X", "_", "X", "_", "_", "_", "_", "_", "_", "_", "_"],
            ["_", "_", "_", "_", "_", "_", "_", "X", "_", "_", "_", "X", "_", "_", "_", "_", "_", "_", "_", "_"],
            ["_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_"],
            ["_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_"],
            ["_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_"],
            ["_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_"]
        ]
        
        let width = 20
        let hight = 11
        //var world = Array(count: hight, repeatedValue: Array(count: width, repeatedValue: Critter.Dead))
        
        var world = pattern.map { $0.map { Critter(s: $0) } }
        
        var (x, y) = (0, 0)
        func setX(i: Int) { x = abs(i % width) }
        func setY(i: Int) { y = abs(i % hight) }
        func getCritter() -> Critter { return world[y][x] }
        
        // Updates happen atomically.
        var newWorld = world
        func setCritter(c: Critter)  { newWorld[y][x] = c }
        func saveWorld() { world = newWorld }
        
        // Encapsulate iteration across our `world`.
        //
        // `uponWorld` consumes two `Words` from the stack,
        // the first is applied with (x, y) for each critter,
        // the second is applied for each row.
        let uponCritter = { $0 .. ddup .. execute }
        let uponCol = { $0 .. setX .. uponCritter }
        let uponRow = { $0 .. setY .. width .. 0 .. loopCnt(uponCol) .. over .. execute }
        let uponWorld = { $0 .. hight .. 0 .. loopCnt(uponRow) .. drop2 }
        
        // Printing
        let printCritter = { $0 .. " " .. getCritter() .. dot .. dot }
        let printRow = { $0 .. cr }
        let printWorld = { $0 .. tick(printRow) .. tick(printCritter) .. uponWorld .. cr }
        
        // Factor out adjusting coordinates
        let p1 = { $0 .. 1 .. (+) }
        let m1 = { $0 .. 1 .. (-) }
        let updateX = { $0 .. x .. swap .. execute .. setX }
        let updateY = { $0 .. y .. swap .. execute .. setY }
        
        // Apply `Word` to each neighbor of the starting critter & finally return to starting location.
        let neighbors = [
            { $0 .. tick(p1) .. updateY .. uponCritter },
            { $0 .. tick(p1) .. updateX .. uponCritter },
            { $0 .. tick(m1) .. updateY .. uponCritter },
            { $0 .. tick(m1) .. updateY .. uponCritter },
            { $0 .. tick(m1) .. updateX .. uponCritter },
            { $0 .. tick(m1) .. updateX .. uponCritter },
            { $0 .. tick(p1) .. updateY .. uponCritter },
            { $0 .. tick(p1) .. updateY .. uponCritter },
            { $0 .. tick(m1) .. updateY .. tick(p1) .. updateX .. drop }
        ]
        let uponneighbors = { $0 .. 9 .. 0 .. loopCnt { $0 .. neighbors[$0.pop(Int)] } }
        
        // Count living neighbors.
        let critterEq = ((==) as (Critter, Critter) -> Bool) // Using just (==) will make the compiler assume we wanted (Int, Int) -> Bool
        let countLiving = { $0 .. getCritter() .. Critter.Alive .. critterEq .. `if`({ $0 .. swap .. 1 .. (+) .. swap }) }
        let countLivingneighbors = { $0 .. 0 .. tick(countLiving) .. uponneighbors }
        
        // Update critters according to the number of living neighbors.
        let grow = { $0 .. setCritter(.Alive) }
        let die = { $0 .. setCritter(.Dead) }
        let growOrDie = { $0 .. 3 .. (==) .. `if`(grow, `else`: die) }
        let updateCritterState = { $0 .. ddup .. 2 .. (!=) .. `if`(growOrDie, `else`: {$0 .. drop}) }
        
        // Update critters.
        let updateCritter = { $0 .. countLivingneighbors .. updateCritterState }
        let doNothing: Forthwith.Word = { $0 }
        let updateWorld = { $0 .. tick(doNothing) .. tick(updateCritter) .. uponWorld .. saveWorld }
        
        // A simualtion is a round of updating and printing.
        let simulate = { $0 .. dot .. cr .. updateWorld .. printWorld }
        
        s .. printWorld .. 35 .. 0 .. loopCnt(updateWorld)

        let endWorld = "[[_, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _], [_, _, _, _, _, _, X, _, _, _, _, _, X, _, _, _, _, _, _, _], [_, _, _, _, _, X, _, X, _, _, _, X, _, X, _, _, _, _, _, _], [_, _, _, _, _, X, _, X, _, _, _, X, _, X, _, _, _, _, _, _], [_, _, _, _, _, _, X, _, _, _, _, _, X, _, _, _, _, _, _, _], [_, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _], [_, _, _, _, _, _, X, _, _, _, _, _, X, _, _, _, _, _, _, _], [_, _, _, _, _, X, _, X, _, _, _, X, _, X, _, _, _, _, _, _], [_, _, _, _, _, X, _, X, _, _, _, X, _, X, _, _, _, _, _, _], [_, _, _, _, _, _, X, _, _, _, _, _, X, _, _, _, _, _, _, _], [_, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _]]"
        XCTAssert(String(world) == endWorld)
    }
    
}
enum Critter { case Alive; case Dead } // Naming another type `Cell` seemed needlessly confusing.

extension Critter: CustomStringConvertible { var description: String { return self == .Alive ? "X" : "_" } }
extension Critter { init(s: String) { self = s == "X" ? .Alive : .Dead } }
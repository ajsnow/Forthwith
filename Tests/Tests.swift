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
                $0 .. 1 .. ((+) as (Int, Int) -> Int) .. ddup .. dot
        }
    }
    
    func testStars() {
        typealias       Word = (Stack<Cell>) -> () // Define it locally because of ambiguities with Swift.Word
        let star      = { $0 .. 42 .. emit }
        let stars     = { $0 .. 0 .. loop(star) .. cr }
        let square    = { $0 .. ddup .. 0 .. loop { $0 .. ddup .. stars } .. drop }
        let triangle  = { $0 .. 1 .. loop { $0 .. $1 .. stars } }
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
        s .. 5 .. 4 .. ((+) as (Int, Int) -> Int) .. printStack
        let p = s .. 5
        func adder(a: Int, _ b: Int) -> Int { return a + b }
        func doubler(a: Double) -> Double { return 2*a }
        p .. 3.1415
        p .. printStack
        p.push(Cell(item: doubler))
        p .. printStack
        p .. 0.1 .. 0.2 .. 0.3 .. fma as ((Double, Double, Double) -> Double) .. printStack
    }
    
}



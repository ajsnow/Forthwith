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
        
        p .. 0 .. IF(drop, ELSE: dup) .. printStack
    }
    
}

//
//  Words.swift
//  SwiftlyForth
//
//  Created by Andrew Snow on 10/6/15.
//  Copyright © 2015 Andrew Snow. All rights reserved.
//

// MARK: - Stack Manipulation Words

func drop<T>(s: Stack<T>) { s.drop() }

func dropAll<T>(s: Stack<T>) { s.removeAll() }

func dup<T>(s: Stack<T>) { s .. s.peek() }

func swap<T>(s: Stack<T>) { let (b, a) = (s.pop(), s.pop()); s .. b .. a }

func over<T>(s: Stack<T>) { let (b, a) = (s.pop(), s.pop()); s .. a .. b .. a }

func rot<T>(s: Stack<T>) { let (c, b, a) = (s.pop(), s.pop(), s.pop()); s .. b .. c .. a }

func rightRot<T>(s: Stack<T>) { let (c, b, a) = (s.pop(), s.pop(), s.pop()); s .. c .. a .. b }

func nip<T>(s: Stack<T>) { s .. swap .. drop }

func tuck<T>(s: Stack<T>) { s .. swap .. over }

// MARK: - Debug Words

func depth(s: Stack<Cell>) { s .. s.depth }

// Needed for two reasons:
// 1. The compiler special cases `print`, telling us it's not a keyword.
// 2. Its optional arguments mess up our normal composition word.
//    `.forEach(print)` has the same problems.
func printStack<T>(s: Stack<T>) { print(s) }

// MARK: - Fun/Test Words

func fib(s: Stack<Cell>) {
    s .. 0 .. 1 .. rot
    guard case .i(var i) = s.pop() else { fatalError("Wrong type: expected Int") }
    for ; i != 0; i-- {
        s .. over .. ((+) as (Int, Int) -> Int) .. swap
    }
    s .. drop
}
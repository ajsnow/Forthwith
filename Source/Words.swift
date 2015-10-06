//
//  Words.swift
//  Forthwith
//
//  Created by Andrew Snow on 10/6/15.
//  Copyright © 2015 Andrew Snow. All rights reserved.
//

// MARK: - Stack Manipulation

func drop<T>(s: Stack<T>) { s.drop() }

func dropAll<T>(s: Stack<T>) { s.removeAll() }

func dup<T>(s: Stack<T>) { s .. s.peek() }

func swap<T>(s: Stack<T>) { let (b, a) = (s.pop(), s.pop()); s .. b .. a }

func over<T>(s: Stack<T>) { let (b, a) = (s.pop(), s.pop()); s .. a .. b .. a }

func rot<T>(s: Stack<T>) { let (c, b, a) = (s.pop(), s.pop(), s.pop()); s .. b .. c .. a }

func rightRot<T>(s: Stack<T>) { let (c, b, a) = (s.pop(), s.pop(), s.pop()); s .. c .. a .. b }

func nip<T>(s: Stack<T>) { s .. swap .. drop }

func tuck<T>(s: Stack<T>) { s .. swap .. over }

// MARK: - Control Flow

// We'd prefer the curried function to take an Int (or Bool) instead of the Stack,
// (and therefore return a Word instead of null) but we haven't figured out a way
// to signal that it should then execute the resulting function as a Word instead
// of the 'MoreMagic' way, which fails since the next item on the stack isn't 
// itself a stack.
func IF(ifSide: Word, ELSE elseSide: Word)(s: Stack<Cell>) {
    s .. (s.pop(Int) != 0 ? ifSide : elseSide)
}

func WHILE(body: Word)(s: Stack<Cell>) {
    while s.pop(Int) != 0 {
        s .. body
    }
}

// MARK: - Words, Words, Words

/// Tick encloses a function (or `Word`) in a `Cell` so that it can be pushed onto the `Stack`.
/// N.B. we have not yet developed a way to execute functions once they're on the stack.
func tick<A, B>(fn: A -> B) -> Cell { return Cell(item: fn) }

// MARK: - Debug

func depth(s: Stack<Cell>) { s .. s.depth }

// Needed for two reasons:
// 1. The compiler special cases `print`, telling us it's not a keyword.
// 2. Its optional arguments mess up our normal composition word.
//    `.forEach(print)` has the same problems.
func printStack<T>(s: Stack<T>) { print(s) }

// MARK: - Fun/Test

func fib(s: Stack<Cell>) {
    s .. 0 .. 1 .. rot .. dup .. WHILE {
        $0 .. rightRot .. over .. ((+) as (Int, Int) -> Int) .. swap .. rot .. 1 .. ((-) as (Int, Int) -> Int) .. dup
    }
    s .. drop .. drop
}
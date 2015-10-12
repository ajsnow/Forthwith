//
//  Words.swift
//  Forthwith
//
//  Created by Andrew Snow on 10/6/15.
//  Copyright © 2015 Andrew Snow. All rights reserved.
//

// MARK: - Stack Manipulation

public func drop<T>(s: Stack<T>) { s.drop() }

public func drop2<T>(s: Stack<T>) { s.drop(); s.drop() }

public func dropAll<T>(s: Stack<T>) { s.removeAll() }

public func dup<T>(s: Stack<T>) { s .. s.peek() }

public func dup2<T>(s: Stack<T>) { let (b, a) = (s.pop(), s.pop()); s .. b .. a .. b .. a }

public func swap<T>(s: Stack<T>) { let (b, a) = (s.pop(), s.pop()); s .. b .. a }

public func over<T>(s: Stack<T>) { let (b, a) = (s.pop(), s.pop()); s .. a .. b .. a }

public func rot<T>(s: Stack<T>) { let (c, b, a) = (s.pop(), s.pop(), s.pop()); s .. b .. c .. a }

public func rightRot<T>(s: Stack<T>) { let (c, b, a) = (s.pop(), s.pop(), s.pop()); s .. c .. a .. b }

public func nip<T>(s: Stack<T>) { s .. swap .. drop }

public func tuck<T>(s: Stack<T>) { s .. swap .. over }

// FIXME: Workaround: The compiler cannot figure out which `dup` to call.
public let ddup = { $0 .. (dup as (Stack<Cell>)->() ) }
public let ddup2 = { $0 .. (dup2 as (Stack<Cell>)->() ) }

// MARK: - Control Flow

// We'd prefer the curried function to take an Int (or Bool) instead of the Stack,
// (and therefore return a Word instead of null) but we haven't figured out a way
// to signal that it should then execute the resulting function as a Word instead
// of the 'MoreMagic' way, which fails since the next item on the stack isn't 
// itself a stack.
//
// I think we could do soemthing more interesting still: we have if, else, then as
// words and overload `..` to be right-associative with them and higher priority,
// but that seems like too much work for now.

/// If `if` then `then` else `else`. :)
public func `if`(then: Word, `else`: Word? = nil)(s: Stack<Cell>) {
    if s.pop(Bool) {
        s .. then
    } else if let `else` = `else` {
        s .. `else`
    }
    // Nil coalescing doesn't seem to work for optional closures,
    // so my preferred way of writting this doesn't currently work:
    // s .. (s.pop(Bool) ? then : `else` ?? { _ in } as Word)
}

/// While checks the top of the stack for a `Bool`, if true, it executes the body,
/// and then checks the top again, if false, it jumps over the body. This is similar
/// to Forth's `begin` ... `while` ... `repeat` but there is no seperate begin phase.
/// Therefore the the programmer will generally first push a `true`, and add the Bool's
/// setup/test/creation as the last part of the body.
/// Any body ending in `.. true` loops forever.
public func `while`(body: Word)(s: Stack<Cell>) -> Stack<Cell> {
    while s.pop(Bool) { s .. body }
    return s
}

/// Loop executes the `body` n times where n is the difference between the top two
/// `Int`s on the `Stack`. It behaves much like the Forth word `do?`, except that
/// it accepts its bounds in either order (i.e. it will never wrap around through
/// Int.max / Int.min).
public func loop(body: Word)(s: Stack<Cell>) -> Stack<Cell> {
    let i = s.pop(Int)
    let bound = s.pop(Int)
    let range = i.stride(to: bound, by: i < bound ? 1 : -1)
    for _ in range { s .. body }
    return s
}

// A version of `loop` that exposes the index as %1.
public func loopCnt(body: Word)(s: Stack<Cell>) -> Stack<Cell> {
    let i = s.pop(Int)
    let bound = s.pop(Int)
    let range = i.stride(to: bound, by: i < bound ? 1 : -1)
    for i in range { s .. i .. body }
    return s
}

// MARK: - Words, Words, Words

public func dot<T>(s: Stack<T>) { print(s.pop(), terminator: "") }

public let cr: Word   = { print(""); return $0 }
public let emit: Word = { print(UnicodeScalar($0.pop(Int)), terminator: ""); return $0 }

/// Tick encloses a function (or `Word`) in a `Cell` so that it can be pushed onto the `Stack`.
public func tick<A, B>(fn: A -> B)(s: Stack<Cell>) -> Stack<Cell> { s.push(fn); return s }

/// Execute takes a Word from the top of the `Stack` and applies it to the stack.
public let execute: Word = { let word = $0.pop(Word); return $0 .. word }

// We'd like to be able to store stack values back to variables, but 
// partial application of functions with 'inout' parameters is not allowed.
//public func store<T>(inout location: T)(newValue: T) -> () {
//    location = newValue
//}

// MARK: - Debug

/// While Stack<T> words must be defined with the usual function notation, `Word`
/// i.e. Stack<Cell> -> () may be defined in a compact (& thus more Forth-ish) way.
public let depth = { $0 .. $0.depth }

// Needed for two reasons:
// 1. The compiler special cases `print`, telling us it's not a keyword.
// 2. Its optional arguments mess up our normal composition word.
//    `.forEach(print)` has the same problems.
public func printStack<T>(s: Stack<T>) { print(s) }

// MARK: - Fun/Test

public func fib(s: Stack<Cell>) {
    s .. 0 .. 1 .. rot .. 0 .. loop { $0 .. over .. (+) .. swap } .. drop
}
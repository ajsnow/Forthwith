//
//  MoreMagic.swift
//  SwiftlyForth
//
//  Created by Andrew Snow on 10/6/15.
//  Copyright © 2015 Andrew Snow. All rights reserved.
//

// The switch was labeled in a most unhelpful way.
// It had two positions, and scrawled in pencil on
// the metal switch body were the words ‘magic' and
// ‘more magic'.

private typealias stopInterfaceHeaderComments = Void // Anyone know of a better way to stop it?

// Returning the result off of the stack is necessary so that the compiler
// knows when `B` is a function (and knows the type of its parameter(s)).
private func apply<A, B>(s: Stack<Cell>, fn: A -> B) -> (Stack<Cell>, B) {
    switch s.pop() {
    case .i(let arg):
        if let arg = arg as? A {
            return (s, fn(arg))
        } else {
            fatalError("Cell \"\(arg)\" has wrong type for function \"\(fn)\"")
        }
        
    case .ref(let arg):
        if let arg = arg as? A {
            return (s, fn(arg))
        } else {
            fatalError("Cell \"\(arg)\" has wrong type for function \"\(fn)\"")
        }
        
    }
}

// MARK: - Apply-Function-on-Stacked-Items
/// Apply `fn` upon the contents of `s`.
func ..<A, B>(s: Stack<Cell>, fn: A -> B) -> Stack<Cell> {
    let (s, result) = apply(s, fn: slurry(fn))
    return s .. result
}

func ..<A, B, C>(s: Stack<Cell>, fn: (A, B) -> C) -> Stack<Cell> {
    let (s, result) = apply(s, fn: slurry(fn))
    return s .. result
}

func ..<A, B, C, D>(s: Stack<Cell>, fn: (A, B, C) -> D) -> Stack<Cell> {
    let (s, result) = apply(s, fn: slurry(fn))
    return s .. result
}

func ..<A, B, C, D, E>(s: Stack<Cell>, fn: (A, B, C, D) -> E) -> Stack<Cell> {
    let (s, result) = apply(s, fn: slurry(fn))
    return s .. result
}

// etc.

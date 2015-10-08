//
//  Slurry.swift
//  Forthwith
//
//  Created by Andrew Snow on 10/6/15.
//  Copyright © 2015 Andrew Snow. All rights reserved.
//

/// Slurry - a singular curry of the first argument.
func slurry<A, B>(fn: A -> B) -> A -> B {
    return fn
}

func slurry<A, B, C>(fn: (A, B) -> C) -> A -> B -> C {
    return { a in { b in fn(a, b) } }
}

func slurry<A, B, C, D>(fn: (A, B, C) -> D) -> A -> (B, C) -> D {
    return { a in { (b, c) in fn(a, b, c) } }
}

func slurry<A, B, C, D, E>(fn: (A, B, C, D) -> E) -> A -> (B, C, D) -> E {
    return { a in { (b, c, d) in fn(a, b, c, d) } }
}

// etc.

/// RSlurry - a right, singular curry of the last argument.
///
/// This hack is required for the Apply-on-Stacked-Items version
/// of the Word-Composition-Operator, as a result of how function
/// types & reflection work in Swift.
func rslurry<A, Y>(fn: A -> Y) -> A -> Y {
    return fn
}

func rslurry<A, X, Y>(fn: (A, X) -> Y) -> X -> A -> Y {
    return { x in { a in fn(a, x) } }
}

func rslurry<A, B, X, Y>(fn: (A, B, X) -> Y) -> X -> (A, B) -> Y {
    return { x in { (a, b) in fn(a, b, x) } }
}

func rslurry<A, B, C, X, Y>(fn: (A, B, C, X) -> Y) -> X -> (A, B, C) -> Y {
    return { x in { (a, b, c) in fn(a, b, c, x) } }
}

func rslurry<A, B, C, D, X, Y>(fn: (A, B, C, D, X) -> Y) -> X -> (A, B, C, D) -> Y {
    return { x in { (a, b, c, d) in fn(a, b, c, d, x) } }
}

// etc.

/// Uncurry - does what it says on the tin.
///
/// We need this to make methods work with our Apply-on-Stacked-Items
/// Word-Composition-Operator. It turns a singly curried function,
/// like methods called from their type name (e.g. String.hasPrefix),
/// into uncurried versions of the same that we can then rslurry as needed.
func uncurry<A, B, C>(fn: (A) -> (B) -> C) -> (A, B) -> C {
    return { (a, b) in fn(a)(b) }
}
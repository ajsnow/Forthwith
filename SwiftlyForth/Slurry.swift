//
//  Slurry.swift
//  SwiftlyForth
//
//  Created by Andrew Snow on 10/6/15.
//  Copyright © 2015 Andrew Snow. All rights reserved.
//

/// Slurry - a singular curry of the first argument.
///
/// This hack is required for the Apply-on-Stacked-Items version
/// of the Word-Composition-Operator, as a result of how function
/// types & reflection work in Swift.
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

//
//  MoreMagic.swift
//  Forthwith
//
//  Created by Andrew Snow on 10/6/15.
//  Copyright © 2015 Andrew Snow. All rights reserved.
//

// The switch was labeled in a most unhelpful way.
// It had two positions, and scrawled in pencil on
// the metal switch body were the words ‘magic' and
// ‘more magic'.

// MARK: - Uncurry methods, and then Apply-Function-upon-Stacked-Items
/// Uncurry `fn`, then call the needed operator below.
func ..<A, B, C>(s: Stack<Cell>, fn: A -> B -> C) -> Stack<Cell> {
    return s .. uncurry(fn)
}

// MARK: - Apply-Function-upon-Stacked-Items
/// Apply `fn` upon the contents of `s`.
func ..<A, B>(s: Stack<Cell>, fn: A -> B) -> Stack<Cell> {
    return s .. rslurry(fn)(s.pop(A))
}

func ..<A, B, C>(s: Stack<Cell>, fn: (A, B) -> C) -> Stack<Cell> {
    return s .. rslurry(fn)(s.pop(B))
}

func ..<A, B, C, D>(s: Stack<Cell>, fn: (A, B, C) -> D) -> Stack<Cell> {
    return s .. rslurry(fn)(s.pop(C))
}

func ..<A, B, C, D, E>(s: Stack<Cell>, fn: (A, B, C, D) -> E) -> Stack<Cell> {
    return s .. rslurry(fn)(s.pop(D))
}

// etc.

// MARK: - Apply-Function-upon-Stacked-Items-(Int-Specialized)

// The Int Specialized versions are a nice feature because they help
// the compiler figure out `s .. 5 .. 4 .. (+)` means Int addition.

/// Apply `fn` upon the contents of `s`.
func ..<B>(s: Stack<Cell>, fn: Int -> B) -> Stack<Cell> {
    return s .. rslurry(fn)(s.pop(Int))
}

func ..<A, C>(s: Stack<Cell>, fn: (A, Int) -> C) -> Stack<Cell> {
    return s .. rslurry(fn)(s.pop(Int))
}

func ..<A, B, D>(s: Stack<Cell>, fn: (A, B, Int) -> D) -> Stack<Cell> {
    return s .. rslurry(fn)(s.pop(Int))
}

func ..<A, B, C, E>(s: Stack<Cell>, fn: (A, B, C, Int) -> E) -> Stack<Cell> {
    return s .. rslurry(fn)(s.pop(Int))
}
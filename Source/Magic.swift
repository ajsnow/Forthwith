//
//  Magic.swift
//  Forthwith
//
//  Created by Andrew Snow on 10/6/15.
//  Copyright © 2015 Andrew Snow. All rights reserved.
//

/// The type signature of a Forth function is:
///     Stack<Cell>->Stack<Cell>
/// We do not strickly need to return the stack as it is a class and
/// the higher-order function that composes our "Forth" `Word`s
/// can handle implicitly passing it along the chain. However, 
/// defining `Word` with the return value allows a user to define 
/// custom `Word`s with less boilerplate. Easy factoring is a major
/// plus to Forth's model and should be preserved where possible.
public typealias Word = Stack<Cell>->Stack<Cell>

/// This is the Word Composition Operator. It is our central
/// conceit and serves several purposes:
/// 1. We can push items onto the stack with it.
/// 2. We can apply `Word`s (explicit stack manipulation).
/// 3. We can apply unmodified functions whose arguments 
///    will be taken from the `Stack`. As you may imagine,
///    bad things happen if those arguments aren't correct.
///
/// Sadly, space is not avalible as our operator of word
/// composition.
infix operator .. { associativity left }

// MARK: - Apply Words

/// Apply a generic, returnless `word` onto a generic stack, `s`.
public func ..<T>(s: Stack<T>, word: Stack<T>->()) -> Stack<T> { word(s); return s }

/// Apply a returnless `word` on `s`. This non-generic version is needed to
/// help the compiler disambiguate between the two generic applies.
public func ..(s: Stack<Cell>, word: Stack<Cell>->()) -> Stack<Cell> { word(s); return s }

/// Apply `word` on `s`.
public func ..(s: Stack<Cell>, word: Word) -> Stack<Cell> { return word(s) }

// MARK: - Push Items

/// Push a `cell` onto `s`.
public func ..<T>(s: Stack<T>, cell: T) -> Stack<T> { s.push(cell); return s }

/// Push an `item` (anything) onto `s`.
public func ..<T>(s: Stack<Cell>, item: T) -> Stack<Cell> {
    if !(T.self is Void.Type) { // We'll never want to push Void. We need this to avoid pushing the return results of converted A -> Void functions.
        s.push(item)
    }
    return s
}

// MARK: - Helper Types

public typealias Cell = Any
//
//  Magic.swift
//  SwiftlyForth
//
//  Created by Andrew Snow on 10/6/15.
//  Copyright © 2015 Andrew Snow. All rights reserved.
//

/// The type signature of a Forth function is:
///     (Stack<Cell>) -> ()
/// We do not need to return the stack as it is a class and
/// the higher-order function that composes our "Forth" `Word`s
/// can handle implicitly passing it along the chain.
///
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

typealias Word = (Stack<Cell>)->()

/// Apply `word` on `s`.
func ..<T>(s: Stack<T>, word: (Stack<T>)->()) -> Stack<T> { word(s); return s }

/// Apply `word` on `s`. This non-generic version is needed to 
/// help the compiler disambiguate between the two generic applies.
func ..(s: Stack<Cell>, word: (Stack<Cell>)->()) -> Stack<Cell> { word(s); return s }

/// Push a `cell` onto `s`.
func ..<T>(s: Stack<T>, cell: T) -> Stack<T> { s.push(cell); return s }

/// Push an `item` (anything) onto `s`.
func ..<T>(s: Stack<Cell>, item: T) -> Stack<Cell> {
    s.push(Cell(item: item))
    return s
}

public enum Cell: CustomStringConvertible {
    
    case i(Int)
    case ref(AnyObject)
    
    init<T>(item: T) {
        switch item {
        case let item as Int:
            self = .i(item)

        case let item as AnyObject:
            self = .ref(item)

        default:
            self = .ref(BoxAny(item))
        }
    }
    
    // MARK: - CustomStringConvertible
    public var description: String {
        switch self {
        case .i(let i):
            return String(i)
        case .ref(let obj):
            return String(obj)
        }
    }
}


public final class BoxAny: CustomStringConvertible {
    
    let value: Any
    
    init(_ item: Any) { self.value = item }
    
    // MARK: - CustomStringConvertible
    public var description: String {
        return "Box[\(value)]"
    }
    
}

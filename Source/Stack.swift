//
//  Stack.swift
//  Forthwith
//
//  Created by Andrew Snow on 10/6/15.
//  Copyright © 2015 Andrew Snow. All rights reserved.
//

/// A simple, infinite last-in first-out `Stack` of `T`.
final class Stack<T>: StackProto, CustomStringConvertible {

    private var storage: [T] = []
    
    /// The number of items on the stack.
    var depth: Int { return storage.count }
    
    // Single-item functions
    /// Add the `item` to the top of the stack.
    func push(item: T) { storage.append(item) }
    
    /// Return the `item` on top of the stack.
    /// Requires: depth > 0
    func pop() -> T {
        //guard depth > 0 else { return nil }
        return storage.removeLast()
    }
    
    /// Remove the `item` on top of the stack.
    /// Requires: depth > 0
    func drop() { pop() }
    
    /// Remove the `item` on top of the stack without removal.
    /// Requires: depth > 0
    func peek() -> T { return storage.last! }
    
    /// Remove all elements.
    func removeAll() { storage = [] }
    
    // Multi-item variant functions
    //    func push(items: T...) { storage += items }
    //
    //    func pop(count: Int) -> [T] {
    //        let results = peek(count)
    //        pop(count)
    //        return results
    //    }
    //
    //    func drop(count: Int) {
    //        let end = storage.endIndex - count
    //        storage = Array(storage[storage.startIndex..<end])
    //    }
    //
    //    func peek(count: Int) -> [T] {
    //        let end = storage.endIndex
    //        let start = end - count
    //        return Array(storage[start..<end])
    //    }
    
    // MARK: - CustomStringConvertible
    var description: String { return "T\(storage)H" }
    
}

// This exits so that we can extend Stack(Proto)<Cell> with Cell specific things.
protocol StackProto {
    
    typealias Element
    
    /// The number of items on the stack.
    var depth: Int { get }
    
    // Single-item functions
    /// Add the `item` to the top of the stack.
    func push(item: Element)
    
    /// Return the `item` on top of the stack.
    /// Requires: depth > 0
    func pop() -> Element
    
    /// Remove the `item` on top of the stack.
    /// Requires: depth > 0
    func drop()
    
    /// Remove the `item` on top of the stack without removal.
    /// Requires: depth > 0
    func peek() -> Element
    
    /// Remove all elements.
    func removeAll()
}

extension StackProto where Element == Cell {
    
    func pop<A>(type: A.Type) -> A {
        let anyValue = pop()
        guard let value = anyValue as? A else { fatalError("Type error: expecting \(A.self); recieved \(anyValue.dynamicType)") }
        return value
    }
    
}

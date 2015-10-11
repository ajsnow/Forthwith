//
//  Life.swift
//  Forthwith
//
//  Created by Andrew Snow on 10/10/15.
//  Copyright © 2015 Andrew Snow. All rights reserved.
//

import Forthwith

// Conway's Game of Life
// In Forthwith Swift

let pattern = [
    ["_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_"],
    ["_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_"],
    ["_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_"],
    ["_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_"],
    ["_", "_", "_", "_", "_", "_", "_", "X", "_", "_", "_", "X", "_", "_", "_", "_", "_", "_", "_", "_"],
    ["_", "_", "_", "_", "_", "_", "_", "X", "_", "X", "_", "X", "_", "_", "_", "_", "_", "_", "_", "_"],
    ["_", "_", "_", "_", "_", "_", "_", "X", "_", "_", "_", "X", "_", "_", "_", "_", "_", "_", "_", "_"],
    ["_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_"],
    ["_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_"],
    ["_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_"],
    ["_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_", "_"]
]



//: Now we define our words, types, & variables.

enum Critter { case Alive; case Dead } // Naming another type `Cell` seemed needlessly confusing.

extension Critter: CustomStringConvertible { var description: String { return self == .Alive ? "X" : "_" } }
extension Critter { init(s: String) { self = s == "X" ? .Alive : .Dead } }

var world = pattern.map { $0.map { Critter(s: $0) } }
let width = world.first!.count
let height = world.count

var (x, y) = (0, 0)
func setX(i: Int) { x = abs(i % width) }
func setY(i: Int) { y = abs(i % height) }
func getCritter() -> Critter { return world[y][x] }

// Updates happen atomically.
var newWorld = world
func setCritter(c: Critter)  { newWorld[y][x] = c }
func saveWorld() { world = newWorld }

// Encapsulate iteration across our `world`.
//
// `uponWorld` consumes two `Words` from the stack,
// the first is applied with (x, y) for each critter,
// the second is applied for each row.
let uponCritter = { $0 .. ddup .. execute }
let uponCol = { $0 .. setX .. uponCritter }
let uponRow = { $0 .. setY .. width .. 0 .. loopCnt(uponCol) .. over .. execute }
let uponWorld = { $0 .. height .. 0 .. loopCnt(uponRow) .. drop2 }

// Printing
let printCritter = { $0 .. " " .. getCritter() .. dot .. dot }
let printRow = { $0 .. cr }
public let printWorld = { $0 .. tick(printRow) .. tick(printCritter) .. uponWorld .. cr }

// Factor out adjusting coordinates
let p1 = { $0 .. 1 .. (+) }
let m1 = { $0 .. 1 .. (-) }
let updateX = { $0 .. x .. swap .. execute .. setX }
let updateY = { $0 .. y .. swap .. execute .. setY }

// Apply `Word` to each neighbor of the starting critter & finally return to starting location.
let neighbors = [
    { $0 .. tick(p1) .. updateY .. uponCritter },
    { $0 .. tick(p1) .. updateX .. uponCritter },
    { $0 .. tick(m1) .. updateY .. uponCritter },
    { $0 .. tick(m1) .. updateY .. uponCritter },
    { $0 .. tick(m1) .. updateX .. uponCritter },
    { $0 .. tick(m1) .. updateX .. uponCritter },
    { $0 .. tick(p1) .. updateY .. uponCritter },
    { $0 .. tick(p1) .. updateY .. uponCritter },
    { $0 .. tick(m1) .. updateY .. tick(p1) .. updateX .. drop }
]
let uponNeighboors = { $0 .. 9 .. 0 .. loopCnt { $0 .. neighbors[$0.pop(Int)] } }

// Count living neighboors.
let critterEq = ((==) as (Critter, Critter) -> Bool) // Using just (==) will make the compiler assume we wanted (Int, Int) -> Bool
let countLiving = { $0 .. getCritter .. Critter.Alive .. critterEq .. `if`({ $0 .. swap .. 1 .. (+) .. swap }) }
let countLivingNeighboors = { $0 .. 0 .. tick(countLiving) .. uponNeighboors }

// Update critters according to the number of living neighboors.
let grow = { $0 .. setCritter(.Alive) }
let die = { $0 .. setCritter(.Dead) }
let growOrDie = { $0 .. 3 .. (==) .. `if`(grow, `else`: die) }
let updateCritterState = { $0 .. ddup .. 2 .. (!=) .. `if`(growOrDie, `else`: {$0 .. drop}) }

// Update critters.
let updateCritter = { $0 .. countLivingNeighboors .. updateCritterState }
let doNothing: Forthwith.Word = { $0 }
public let updateWorld = { $0 .. tick(doNothing) .. tick(updateCritter) .. uponWorld .. saveWorld }

// A simualtion is a round of updating and printing.
public let simulatePrint = { $0 .. dot .. cr .. updateWorld .. printWorld }


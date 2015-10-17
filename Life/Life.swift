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

let exampleWorld = [
    "____________________",
    "____________________",
    "____________________",
    "____________________",
    "_______X___X________",
    "_______X_X_X________",
    "_______X___X________",
    "____________________",
    "____________________",
    "____________________",
    "____________________"
]

func initWorld(pattern: [String]) -> [[Critter]] { return pattern.map { $0.characters.map { Critter(s: String($0)) } } }



//: Now we define our words, types, & variables.

enum Critter { case Alive; case Dead } // Naming another type `Cell` seemed needlessly confusing.

extension Critter: CustomStringConvertible { var description: String { return self == .Alive ? "X" : "_" } }
extension Critter { init(s: String) { self = s == "X" ? .Alive : .Dead } }

var world = initWorld(exampleWorld)
let width = world.first!.count
let height = world.count

// Setting external vars is a bit painful.
// Swift currently doesn't allow partially applied functions to contain inout parameters,
// thus we cannot create a generic, well-behaved set(&varname) to grap stuff off of the stack.
// We also cannot define another composition operator overload to handle `s .. 5 .. &intVar`
// as this currently crashes the compiler. :'(
// The inline closure `s .. 5 .. { intVar = $0 }` works, but is quite ugly, even by Forthwith standards.
// So we'll define some custom setters & array getters/setters:
var (x, y) = (0, 0)
func setX(i: Int) { x = abs(i % width) }
func setY(i: Int) { y = abs(i % height) }
func getCritter() -> Critter { return world[y][x] }

// We have two worlds & copy the completed world back at the end of each cycle.
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
let incX = { $0 .. x .. 1 .. (+) .. setX }
let decX = { $0 .. x .. 1 .. (-) .. setX }
let incY = { $0 .. y .. 1 .. (+) .. setY }
let decY = { $0 .. y .. 1 .. (-) .. setY }

// Apply `Word` to each neighbor of the starting critter & finally return to starting location.
let neighbors = [
    { $0 .. incY .. uponCritter },
    { $0 .. incX .. uponCritter },
    { $0 .. decY .. uponCritter },
    { $0 .. decY .. uponCritter },
    { $0 .. decX .. uponCritter },
    { $0 .. decX .. uponCritter },
    { $0 .. incY .. uponCritter },
    { $0 .. incY .. uponCritter },
    { $0 .. incX .. decY .. drop }
]
let uponNeighbors = { $0 .. 9 .. 0 .. loopCnt { $0 .. neighbors[$0.pop(Int)] } }

// Count living neighbors.
let critterEq = ((==) as (Critter, Critter) -> Bool) // Using just (==) will make the compiler assume we wanted (Int, Int) -> Bool
let countLiving = { $0 .. getCritter .. Critter.Alive .. critterEq .. `if`({ $0 .. swap .. 1 .. (+) .. swap }) }
let countLivingNeighbors = { $0 .. 0 .. tick(countLiving) .. uponNeighbors }

// Update a critter according to the number of living neighbors.
let grow = { $0 .. setCritter(.Alive) }
let die = { $0 .. setCritter(.Dead) }
let growOrDie = { $0 .. 3 .. (==) .. `if`(grow, `else`: die) }
let updateCritterState = { $0 .. ddup .. 2 .. (!=) .. `if`(growOrDie, `else`: {$0 .. drop}) }

// Update critters.
let updateCritter = { $0 .. countLivingNeighbors .. updateCritterState }
let doNothing: Forthwith.Word = { $0 }
public let updateWorld = { $0 .. tick(doNothing) .. tick(updateCritter) .. uponWorld .. saveWorld }

// A simulation is a round of updating and printing.
public let simulatePrint = { $0 .. dot .. cr .. updateWorld .. printWorld }


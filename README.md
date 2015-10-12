# $0 .. Swift .. Forthwith
## Or *On the Abuse of Higher-order Functions & Custom Operators*

Do you love the expressivity and speed of Swift, but long for the ability to express computation as untyped operations upon an implicitly passed stack?

No? Um... 😅 Well, the rest of this pitch was predicated on your giving a rather enthusiastic "Yes!" to that. So let's just pretend you did.

## Introduction to Forth

In [Forth](https://en.wikipedia.org/wiki/Forth_(programming_language), functions (known as "words") implicitly pass values to one another via a stack, using syntax resembling RPN.

```
1 2 3 * -
    [-5]
```
Words are constructed to build a vocabulary to describe the problem:

```
: fib 0 1 rot 0 ?do over + swap loop drop ;
10 fib
	[34]
```
Let's break down this example:

We want our `fib` word to take a number n, and to return the nth number from the Fibonacci sequence. So we enter `fib` with, say, `10` on the stack. We push the first two Fibonacci numbers, `0` & `1`, for later use. We're going to implement the iterative algorithm, so we need to setup a loop from 0 to our n (10), so we `rot` which moves our `10` from the 3rd position on the stack to the top yielding `0 1 10` and push `0`, this gives us `0 1 10 0`. Then `?do` takes the difference of the two numbers and will execute the words between it and `loop` that many times. Thus, `0 1` are left on the stack and we'll now execute the loop body 10 times. 

`over` takes the 2nd to top item and copies it to the top, making our stack `0 1 0`, `+` makes it `0 1` and `swap` makes it `1 0`.

If you work through the loop again, the stack would be `1 1`, then `2 1`, `3 2`, `5 3` etc. After 10 loops, it'd be `34 21`. The `21` is `drop`'d and our answer `34` is left on the stack. Fun, right?

## Thus, Forthwith

Let's look at how `fib` is implemented in Forthwith:

```
let fib = { $0 .. 0 .. 1 .. rot .. 0 .. loop { $0 .. over .. (+) .. swap } .. drop }
s .. 10 .. fib
    [34]
```

Neat, but the objection is already forming: *Sure it works for pushing `Int`s and using these custom functions explicitly built for it, but it's completely isolated from Swift & Cocoa!* 

O' ye of little faith.

```        
let drawLivingCritter = { $0 .. path .. createRect .. NSBezierPath.appendBezierPathWithOvalInRect }
let drawCritter = { $0 .. getCritter .. Critter.Alive .. critterEq .. `if`(drawLivingCritter) }
let drawWorld = { $0 .. tick(doNothing) .. tick(drawCritter) .. uponWorld }
        
s .. drawWorld .. path .. NSBezierPath.fill
```

The above snippet (as seen in `Life/LifeView.swift`) uses CGRects & a NSBezierPath to draw the view (/playground animation) below, in a UIView's drawRect method:

![Life](http://zippy.gfycat.com/OblongUnlinedGannet.gif)




So how did we bring this magic to Swift?

The big trick is obviously in `..` — our stack composition operator\*. It takes three basic forms:

1. Pushing items onto the stack
2. Executing stack-aware word upon the stack
3. Adapting & executing native Swift functions upon the stack

Our stack's element type is `Any` so pushing to it is simple. As is applying stack-aware words:
`func ..(s: Stack<Cell>, word: Word) -> Stack<Cell> { return word(s) }`

On the other hand, taking arbitrary Swift functions and methods is a bit more fun:

## Higher-order Functions are Fun

You have a stack of `Any`s that you can `.pop()` off one at a time. You have a function of the form `(Int, String, Double) -> String`. How do you get the needed parameters off of the top of the stack and then execute it?

As you may know, a Swift function can be called with a tuple of its parameters instead of the parameters themselves, and higher order function that takes `fn: A -> B` can infer `A` to be such a tuple of parameters for a multi-parameter function.

However, these facts are massive red herrings.

In fact, what we need to do is curry the function and recursively partially apply it until we get our result to push. We also need to reverse the argument list of the curried function, since we're taking from the *top* of the stack and, like in RPN, `10 7 -` needs to produce `3` not `-3`.

If you do this the obvious way, however, you'll instead get `10 Function` as your stack because the compiler thought `..` should push the resulting partially–applied function instead of applying it some more. So, instead of fully uncurrying it, you can uncurry just the last parameter (making our initial example `(Double) -> (Int, String) -> String`), apply that, and then recursively do all that again for `(Int, String) -> String` until you get your return value.

Ah, but there's still a problem: class, struct & enum members. These come as `T -> (A) -> B` where `T` is the type the member is defined on, so we can uncurry them into `(T, A) -> B` and then run them through the normal function handlers.

## An Annotated Example: Life

So the final thing we'd like to show is an example program that implements the Game of Life, to demonstrate what this can look like tackling not-single-line (save for in [APL](http://dfns.dyalog.com/c_life.htm)) problems:

```
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

// Count living neighbors.
let critterEq = ((==) as (Critter, Critter) -> Bool) // Using just (==) will make the compiler assume we wanted (Int, Int) -> Bool
let countLiving = { $0 .. getCritter .. Critter.Alive .. critterEq .. `if`({ $0 .. swap .. 1 .. (+) .. swap }) }
let countLivingNeighboors = { $0 .. 0 .. tick(countLiving) .. uponNeighboors }

// Update critters according to the number of living neighbors.
let grow = { $0 .. setCritter(.Alive) }
let die = { $0 .. setCritter(.Dead) }
let growOrDie = { $0 .. 3 .. (==) .. `if`(grow, `else`: die) }
let updateCritterState = { $0 .. ddup .. 2 .. (!=) .. `if`(growOrDie, `else`: {$0 .. drop}) }

// Update critters.
let updateCritter = { $0 .. countLivingNeighboors .. updateCritterState }
let doNothing: Forthwith.Word = { $0 }
public let updateWorld = { $0 .. tick(doNothing) .. tick(updateCritter) .. uponWorld .. saveWorld }

// A simulation is a round of updating and printing.
public let simulatePrint = { $0 .. dot .. cr .. updateWorld .. printWorld }
```


## License

You ought not use this in any context where licensing matters, but, for reference, Forthwith is released under the MIT license.

\*Sadly, whitespace was not available. But at least `..` has the nice properties of being easy to type, otherwise unused, and visually unobtrusive (relative to our other options, at least).
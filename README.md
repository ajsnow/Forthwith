# Forthwith Swift
## *On the Abuse of Higher-order Functions & Custom Operators*

Do you love the expressivity and speed of Swift, but long for the ability to express computation as untyped operations upon an implicitly passed stack?

No? Well, the rest of this pitch was predicated on your giving a rather enthusiastic "Yes!" to that. So let's just pretend you did.

## Introduction to Forth

In [Forth](https://en.wikipedia.org/wiki/Forth_(programming_language), functions (known as "words") implicitly pass values to one another via a stack, using syntax resembling [RPN](https://en.wikipedia.org/wiki/Reverse_Polish_notation).

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

We want our `fib` word to take a number `n`, and to return the nth number from the Fibonacci sequence. So we enter `fib` with, say, `10` on the stack. We push the first two Fibonacci numbers, `0` & `1`, for later use. We're going to implement the iterative algorithm, so we need to setup a loop from 0 to our n (10), so we `rot` which moves our `10` from the 3rd position on the stack to the top yielding `0 1 10` and push `0`, this gives us `0 1 10 0`. Then `?do` takes the difference of the two numbers on the top of the stack and executes the words between it and `loop` that many times. Thus, `0 1` are left on the stack while we execute the loop body 10 times. 

`over` takes the 2nd to top item and copies it to the top, making our stack `0 1 0`, `+` makes it `0 1` and `swap` makes it `1 0`.

If you work through the loop again, the stack would be `1 1`, then `2 1`, `3 2`, `5 3` etc. After 10 loops, it'd be `34 21`. The `21` is `drop`'d and our answer `34` is left on the stack. Fun, right?

## Introducing Forthwith

Let's look at how `fib` is implemented in Forthwith:

```
let fib = { $0 .. 0 .. 1 .. rot .. 0 .. loop { $0 .. over .. (+) .. swap } .. drop }
s .. 10 .. fib
    [34]
```
See the resemblance? Great!

That is a fragment of a valid Swift 2.0 program. Forthwith is not a Forth whose implementation happens to be written in Swift, it's (a small part of) a Forth, compilable by an unmodified `swiftc`. 

What we're doing is defining a closure named `fib` that implicitly accepts and returns a `Stack<Cell>`. Upon this stack, we can push values like `0` or apply words like `rot`. We also show off part of our control flow: `loop`, which is just a higher-order function that takes & returns a word with semantics similar to `?do ... loop` in Forth.

Neat, but the objection is already forming: *Sure it works for pushing `Int`s and using these custom functions explicitly built for it, but it's completely isolated from Swift & Cocoa!* 

O' ye of little faith:

```        
let drawLivingCritter = { $0 .. path .. createRect .. NSBezierPath.appendBezierPathWithOvalInRect }
let drawCritter = { $0 .. getCritter .. Critter.Alive .. critterEq .. `if`(drawLivingCritter) }
let drawWorld = { $0 .. tick(doNothing) .. tick(drawCritter) .. uponWorld }
        
s .. drawWorld .. path .. NSBezierPath.fill
```

The above snippet (as seen in `Life/LifeView.swift`) uses CGRects & a NSBezierPath to draw the view (/playground animation) below, in a UIView's drawRect method:

![Life](http://zippy.gfycat.com/ZigzagHonorableAegeancat.gif)

So how did we bring this magic to Swift?

As you may guess, the trick is in `..` — our stack composition operator. It has three distinct roles:

1. Pushing items onto the stack
2. Executing stack-aware word upon the stack
3. Adapting & executing native Swift functions upon the stack

Our stack's element type is (a typealias of) `Any` so pushing to it is simple. As is applying stack-aware words:
`func ..(s: Stack<Cell>, word: Word) -> Stack<Cell> { return word(s) }`

On the other hand, taking arbitrary Swift functions and methods is a bit more fun:

## Higher-order Functions for Fun and, uh, More Fun

We have a stack of `Any`s that you can `.pop()` off one at a time. We have a function of the form `(Int, String, Double) -> String`. How do we get the needed parameters off of the top of the stack and then execute it?

As you may know, a Swift function can be called with a tuple of its parameters instead of the parameters themselves, and higher order functions that takes `fn: A -> B` can infer `A` to be such a tuple of parameters for a multi-parameter function.

However, these facts are massive red herrings.

In fact, what we need to do is curry the function and recursively partially apply it until we get our result to push. We also need to reverse the argument list of the curried function, since we're taking from the *top* of the stack and, like in RPN, `10 7 -` needs to produce `3` not `-3`.

If we do this the obvious way, however, we'll instead get `10 Function` as our stack because the compiler thought `..` should push the resulting partially–applied function instead of applying it some more. So, instead of fully uncurrying it, we can uncurry just the last parameter (making our initial example `(Double) -> (Int, String) -> String`), apply that, and then recursively do all that again for `(Int, String) -> String` until you get your return value.

Ah, but there's still a problem: class, struct & enum members. These come as `T -> (A) -> B` where `T` is the type the member is defined on, so we can uncurry them into `(T, A) -> B` and then run them through the normal function handlers.

## Limitations

As you might guess, there are some limitations and caveats when misusing Swift's features so thoroughly. At present, the most annoying issue is that there is no way to write a generic assignment function (analog to Forth's store word) to set named variables or subscripts. Swift 2.0 does not allow partial application of functions with `inout` parameters and returning a closure over an `inout` does not currently maintain a mutable reference to the original variable. For this reason, setting external variables must be done via custom made functions (as seen in the example below).

Also, there are many differences from real Forths, including the lack of a (accessible) return stack and a fundamentally different memory model (mainly due to Swift's native class / struct distinction and the lack of easy references to value types).

## An Annotated Example: Life

So to demonstrate that one could, in theory, tackle slightly less trivial problems with Forthwith, we have implemented the Game of Life and a NSView subclass that can draw it.

Sure, it's not the APL one-liner, but we still think it's pretty swell. Take special note of the use of `tick` and `execute` to push words onto the stack for later execution, for example. This allows us to write higher-order words that encapsulate iteration over the world or a critter's neighbors (we call Life's cells Critters to avoid confusion with the Stack's Cells).

Note, that while we won't describe every Forthwith word used, they will have the same meaning as in Forth proper.

First our types, globals & accessors (see Limitations for why we have accessors):

```
enum Critter { case Alive; case Dead }
extension Critter: CustomStringConvertible { var description: String { return self == .Alive ? "X" : "_" } }

var world: [[Critter]] = initWorld(exampleWorld) // Supplied off screen as it's not relevant to our work.
let width = world.first!.count
let height = world.count

var (x, y) = (0, 0)
func setX(i: Int) { x = abs(i % width) }
func setY(i: Int) { y = abs(i % height) }
func getCritter() -> Critter { return world[y][x] }

// We have two worlds & copy the completed world back at the end of each cycle.
var newWorld = world
func setCritter(c: Critter)  { newWorld[y][x] = c }
func saveWorld() { world = newWorld }

```
Now with the setup done, we get to the meat of defining our vocabulary. Since we'll need to iterate over the world both for our simulation step and for printing, we'll abstract over that. The following words assume there are two words on the stack: the first is called at the end of each row (e.g. to print "\n"), the second is called for every column within a row (or put another way, with x and y set to the coordinates of each critter).

The words on the stack must be `dup`'d or `over`'d before being called since calling consumes them, and then `drop2`'d at the end since the word shouldn't leave them on the stack once it's finished. `ddup` is an alias to `dup` that helps the compiler know it's not the function of the same name that duplicates file descriptors and which, apparently, is always available in the Swift namespace. (`Forthwith.dup` being a bit long.)

```
let uponCritter = { $0 .. ddup .. execute }
let uponCol = { $0 .. setX .. uponCritter }
let uponRow = { $0 .. setY .. width .. 0 .. loopCnt(uponCol) .. over .. execute }
let uponWorld = { $0 .. height .. 0 .. loopCnt(uponRow) .. drop2 }
```
With that done, printing is pretty trivial. 

`tick(word)` is our equivalent to Forth's `'word` which pushes it onto the stack instead of executing it immediately. Similarly, `dot` prints the top item on the stack like `.`.

```
let printCritter = { $0 .. " " .. getCritter() .. dot .. dot }
let printRow = { $0 .. cr }
public let printWorld = { $0 .. tick(printRow) .. tick(printCritter) .. uponWorld .. cr }
```
Okay, now that we can print the world to the console, let's work on the simulation. The trivial algorithm is to count the neighbors of every cell, making the critter alive if the count is 3, not changed if 2 and dead otherwise.

First, we'll abstract moving the cell coordinates around. Then, we'll abstract over applying an arbitrary function to each neighbor. After that, we'll make a word that counts the living neighbors by accumulating the live ones. Finally, we'll implement the state update algo based on that count.

Let's see how that looks:

```
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

```
Great! Now we can update any critter, so let's update them all:

```
let updateCritter = { $0 .. countLivingNeighbors .. updateCritterState }
let doNothing: Forthwith.Word = { $0 }
public let updateWorld = { $0 .. tick(doNothing) .. tick(updateCritter) .. uponWorld .. saveWorld }
```
Finally, a simulation round should simulate and print. We'll do that 30 times, after printing the initial state.

```
let simulatePrint = { $0 .. dot .. cr .. updateWorld .. printWorld }
$0 .. printWorld .. 30 .. 0 .. loopCnt(simulatePrint)
```
Now, if we'd want to print to an NSView instead of to the console, we'd need to subclass NSView and override drawRect with something like this:

```
let s = Stack<Cell>()
let path = NSBezierPath()

let critSizeX = self.bounds.width / CGFloat(width)
let critSizeY = self.bounds.height / CGFloat(height)

func createRect() -> CGRect { return CGRect(x: CGFloat(x) * critSizeX, y: CGFloat(y) * critSizeY, width: critSizeX, height: critSizeY) }

let drawLivingCritter = { $0 .. path .. createRect .. NSBezierPath.appendBezierPathWithOvalInRect }
let drawCritter = { $0 .. getCritter .. Critter.Alive .. critterEq .. `if`(drawLivingCritter) }
let drawWorld = { $0 .. tick(doNothing) .. tick(drawCritter) .. uponWorld }
        
s .. drawWorld .. path .. NSBezierPath.fill
```
And change our simulate word to mark the View as NeedsDisplay:

```
let simulateView = { $0 .. updateWorld .. view .. rect .. LifeView.setNeedsDisplayInRect }
```


## License

You ought not use this in any context where licensing matters, but, for reference, Forthwith is released under the MIT license.
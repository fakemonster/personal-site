---
title: Algebraic data types, from a lay perspective
description: A vague description of the algebraic attitude.
---

# Algebraic data types from a lay perspective

I don't really like the term "algebraic data type". It makes it sound like "being algebraic" is a feature of _some_ types, when realistically it's more useful to say "it helps to think about your types algebraically". Any type can "be" algebraic! I think! If I was an expert, the title would be different.

It's certainly the case that plenty of (statically typed) languages allow for defining types algebraically. But when you look around online, most examples you'll see, including this very article, will have types that look pretty Haskell-y; those examples might even be full sections of code in a functional language. _It's succinct to express algebraic data types in most functional languages,_ but the expression of them is neither exclusive nor intrinsic to functional languages. You can, and should, use this thinking in virtually any programming language. You already do, though maybe you're not always 100% conscious of it.

---

Here's a type.

```elm
type Bool
  = False
  | True
```

Great!

In lots of languages, this could pass as an actual definition of the boolean type. In some languages' "core libraries", these three lines _actually exist_ (maybe it's just one or two lines). The "type" is `Bool`; the "variants" are `True` and `False`. To dig in:

- The "type" is the _name of the universe_ that both defines and limit all possible values that could exist. When I say "I have a `Bool`", I could instead say "I have a thing. It's either a `False` or a `True`". `Bool` saves me some time. A different type is a different universe<fn symbol="1"/>.
- A "variant" is one of the values from this universe that may turn up. Sometimes when I have a `Bool`, it's `True`, because `True` is a variant of `Bool`.

How many distinct values of `Bool` could possibly exist? Two: `False | True`. The **cardinality** of the type `Bool` is two. From here on out, when I say "the cardinality of type `X`," what I mean is "the number of distinct values of type `X` that could possibly exist". (When space is tight I'll actually say "cardof" instead of "cardinality of".) You'll see this term around; it comes from math, where "cardinality" is the number of elements in a set.

You could think of `Bool` as a set: `{False, True}`. `Int` is a set too: `{..., -3, -2, -1, 0, 1, 2, 3, ...}`. Every type is a set, in the sense that every type declares, or implies, every possible value of that type. The cardinality of a set is the number of elements it has; the cardinality of a type is the number of elements that _could be._

<fn symbol="1">
  When you really land on this way of thinking about types you can see why some people say dynamic languages like JavaScript "only have one type." Sure, there are various primitives that are distinct, but looking at any given (exposed) variable, at any given moment, it _could_ be a string, a number, null, undefined, an object, an array (which is of course an object), a function (which is of course an object)... There's "only one universe", so "only one type".
</fn>

## Addition


Now I'll give the moral away early: **algebraic data types are types where you control cardinality by combining other types.** If this feels too dense to parse right now that's fine; return when you're through and see if it resonates better.

So anyways, `Bool` is nice, but what if we need more than two values?

```elm
type Cool
  = SomeBool Bool
  | TrueWithStylePoints
```

We're new here, and we don't want to mess with `Bool`, so instead we'll make this new type called `Cool`. We might be afraid of strangers, but we can still be fun.

Before moving forward let's clarify the components of `type Thing = Word OtherWord`:

1. `type`: just a label to say "type incoming!"
1. `Thing`: the name of our type. This has no special meaning, beyond the life we breathe into it now.
1. `=`: the rest of this is the _definition_ of our type
1. `Word`: a "variant" called Word. This too has no special meaning, beyond the life we breathe into it now.
1. `OtherWord`: I like to think of this as "the type inside of the variant." This _does_ have special meaning! Somewhere else there must be a definition of `OtherWord`, because while `Word` is basically a label that we just invented here, `OtherWord` refers to an extant type. That's why we can say `type Cool = SomeBool Bool`. `Cool` and `SomeBool` are new names, but `Bool` refers to the type we defined earlier.

The above goes a little further to add a `|`, and another word. The two together _add a variant_ to the type. So what kinds of values can this type have? Well, it's either `SomeBool` with a `Bool` inside, or `TrueWithStylePoints`. Let's enumerate all the values that could possibly exist.

```elm
allVariants : List Cool
allVariants =
  [ SomeBool False
  , SomeBool True
  , TrueWithStylePoints
  ]
```

As you can see above, the variant `SomeBool` is effectively a "namespace" for `Bool`, which itself has two variants. And `TrueWithStylePoints` doesn't have any type inside of it, so that's just one variant: itself. Our cardinality is **the cardinality of `Bool` (2) + the cardinality of `TrueWithStylePoints` (1) = 3**.

When people say something is a "sum type", this is what they mean: It's a type whose cardinality has been established by _adding_ variants.

You don't have to add just one at a time! We could have done this:

```elm
type TooCool
  = SomeBool Bool
  | CoolBool Bool
```

If you don't want to list out all 4 variants of this type, I'll summarize by saying that it's "the cardinality of `Bool` within `SomeBool` (2) **plus** the cardinality of `Bool` within `CoolBool` (2)".

Most interesting sum types are "composite types"; to put that another way, they're types that have some subtypes (so far the only subtype we've seen is `Bool`, but any type can be a subtype of another type). Here are some mostly-composite sum types that you see all the time in the wild:

1. `type Maybe x = Nothing | Just x `<fn symbol="1"/>. There may be something there, or not! Its cardinality is "one (for when it's `Nothing`) **plus** cardof `x` (for when it's `Just`)."
1. `type Result x = Error String | Ok x`. Hopefully things work out, but if they don't, I'd like to get a message explaining what went wrong. Its cardinality is "cardof String (when it's `Error`) **plus** cardof `x` (when it's `Ok`)".
1. Floating point numbers: the IEEE 754 standard for floating points says that a floating point is either a "finite number", positive or negative "infinity", or a "NaN" (not a number). Sticking to the Elm syntax we've been using here, that could be something like `type FloatingPoint = Finite FiniteNumber | Infinity | NegInfinity | NotANumber`. Its cardinality is "cardof `FiniteNumber` **plus** 1 **plus** 1 **plus** 1".
1. Enums: straight up and down, this is the iconic sum type. `type Direction = Left | Right | Up | Down`. Not a composite type, but that's OK! There's no better way to represent variance than variants. The cardinality of this example is "Left (1) **plus** Right (1) **plus** Up (1) **plus** Down (1) = 4".

<fn symbol="1">
  `x` is a "type variable", meaning I haven't actually said exactly what type it is. In a program that'll eventually be replaced with a "concrete type". Some examples of `Maybe x` with concrete types are:

  1. `Maybe Bool` (with a cardinality of **1 + 2 = 3**)
  1. `Maybe String` (with a cardinality of **1 + cardof String**)
  1. `Maybe (Maybe Bool)` (with a cardinality of **1 + (1 + 2) = 4**).
</fn>

## Multiplication


Let's make some more types:

```elm
type PlayStyle
  = Glam
  | Aggressive

type RPS
  = Rock
  | Paper
  | Scissors
```

**NB:** I hope that the earlier use of `Bool` didn't mystify you too much; those were just names! _Because they both have a cardinality of two_, there's really nothing different between `PlayStyle` and `Bool` other than the names. (Most languages provide some standard library that makes booleans actually useful, to be fair! But 1. we could reimplement it for PlayStyle, and 2. with these examples, we aren't necessarily "in" a programming language, even if we're using the syntax of one.)

Without defining the rules just now, these types let us imagine a game of rock-paper-scissors, where maybe your play style has some effect. With what we've defined so far, we know there are two possible values of `PlayStyle`: `Glam` and `Aggressive`, and three possible values of `RPS`: `Rock`, `Paper`, and `Scissors`.

For fun, we _could_ make a sum type combining the two:

```elm
type PlayStyleOrRPS
  = SomePlayStyle PlayStyle
  | SomeRPS RPS
```

But that doesn't seem like a very useful thing to represent, to be honest. Some individual thing is _either_ a PlayStyle or an RPS? What could that even mean?

It would be more useful to try and represent the _coupling_ of a playstyle and the player's move:

```elm
type Play
  = Play PlayStyle RPS
```

Earlier we saw some variants that contained a value; this variant `Play` (the thing to the right of the equals sign, not to be confused with the _type_ `Play` on the left) contains two values: `PlayStyle` and `RPS`!

So what are _all_ of the values this type `Play` could represent?

```elm
allValues : List Play
allValues =
  [ Play Glam Rock
  , Play Glam Paper
  , Play Glam Scissors
  , Play Aggressive Rock
  , Play Aggressive Paper
  , Play Aggressive Scissors
  ]
```

Six! Six beautiful values. Now we can see where the term "product type" comes in; it's "the cardinality of the first type (2) **times** the cardinality of the second type (3)".

In non-FP languages, product types are really the rule of law. An object/struct/record/class-instance with fields is a product type: its cardinality is the product of the cardinalities of its fields.

```ts
interface Text {
  fontSize: number;
  content: string;
}
```

This could have values like `{ fontSize: 16, content: "hello!" }` or `{ fontSize: 15, content: "begone!" }`, so its cardinality is "cardof `number` **times** cardof `string`."

Some other product type examples:

1. Tuples like `(PlayStyle, RPS)`. This is effectively the same as the `Play` type we defined earlier, it just doesn't have any names (which is good or bad, depending on your opinion).
2. `type Round = Unstarted | OnePlayed Play | BothPlayed Play Play`. This is a type that uses both summing and product-ing: A given game round of RPS could be in the state where no one has moved, someone has moved a little early, or both players have moved. This type has some "depth", in that `Play` is a pretty complex subtype, but when we're calculating the cardinality there's really not much special about it. The cardinality of this type is "cardof `Unstarted` (1) **plus** cardof `Play` (6) **plus** (cardof `Play` (6) _times_ cardof `Play` (6))". That's **1 + 6 + 36**, for a grand total cardinality of **43**.



## Where sum types can save you

Honestly, you know when to use product types. Sometimes you just need a string and a number! **And** is the magic word. If you have two independent values, and you need them in one place (think first **and** last name), that's a product type. Sum types, the world of **or**, are really where we can get more creative.

Let's take an example: a record that indicates the name of a plant, whether its edible, and how many calories it has in a serving:

```elm
type alias Plant =
  { name : String
  , calories : Int
  , edible : Bool
  }
```

(Don't be thrown by "alias" in that snippet: elm records are defined anonymously, so this is just a way of putting a name on one.)

So when we use this type, the only thing we ever do is say how many calories you get if you eat it:

```elm
calorieCount : Plant -> Int
calorieCount plant =
  if plant.edible then plant.calories else -1
```

Well, that's not quite right... you're not gonna _lose_ calories if you eat an inedible plant (though that depends on the plant!). Maybe return 0 instead, since you won't eat it? But then if there are zero-calorie plants, is that confusing? Can a plant really be _zero_ calories? Didn't I read something about how celery effectively has negative calories??

The problem here is that integers _don't have enough cardinality_ for the problem space. There isn't an integer we could pick that expresses the notion of "from a food perspective it doesn't make sense to ask about the calories in poison ivy". Really, we just want to say "here's the calorie count" _or_ "that's irrelevant, don't eat this":

```
type CaloricEffect
  = Calories Int
  | Inedible

calorieCount : Plant -> CaloricEffect
calorieCount plant =
  if plant.edible then Calories plant.calories else Inedible
```

There! If you can't eat it, we're not stuck picking a magic number that must be memorized as meaning "watch out for this one!". And importantly, now we're representing our problem space _precisely_, with no more or less cardinality than needed. Our cardinality has gone up from "cardinality of Int" to "cardinality of Int + 1".

Of course, looking at that, we realize that the cardinality of our `Plant` definition is actually _too high_:

```elm
  , calories : Int
  , edible : Bool
```

There's no case where `edible = False` and we need to know the calorie count! So why does our type make it possible to define it that way? This is a great opportunity to port our function improvement back to the core type:

```elm
type alias Plant =
  { name : String
  , caloricEffect : CaloricEffect
  }

calorieCount : Plant -> CaloricEffect
calorieCount plant =
  plant.caloricEffect
```

Incredibly succinct, and actually _more_ clear than when we started. Now let's do the algebra.

In the original version, where `Plant` was a product of String, Int, and Bool, its cardinality was "cardof String * cardof Int * 2". Now, its cardinality is "cardof String * (cardof Int + 1)". It's virtually cut in half! Complexity is death by a thousand cuts, and a good sum type has saved us from 499 of them.

---

## (Bonus) Exponentiation

This section is a bonus because in my estimation it's fun, not useful.

At this point you've seen most of the core value of type algebra: addition and multiplication, along with when to use each. But there are other ways of combining types!

Subtraction and division are both possible, I hear. Unfortunately I can't give many more details because it involves language features that are a bit beyond my understanding. But there's another way of combining we could take a look at. So for fun, let's ask: what about exponentiation?

```elm
powerMove : PlayStyle -> RPS
```

The above is a "type annotation" for a function. In Elm, it means

> the next thing you see is going to be the definition of a function named `powerMove`. It will take a `PlayStyle` argument and return a value of type `RPS`.

We could imagine this is a function that determines "for each playstyle, what move gets bonus points?".

```elm
powerMove playStyle =
  case playStyle of
    Aggressive -> Rock
    Glam -> Scissors
```

This function returns `Rock` when the playstyle is `Aggressive`, so `Aggressive` players will get bonus points when they play `Rock`. Similarly, `Glam` players will get bonus points when they play `Scissors`. (Of course, they're taking a risk playing those moves since their opponents know they have to incentive to use them!)

Anyways, the type algebra question: _how many versions of this function could possibly exist?_

```elm
-- our original
powerMove1 playStyle =
  case playStyle of
    Aggressive -> Rock
    Glam -> Scissors

powerMove2 playStyle =
  case playStyle of
    Aggressive -> Rock
    Glam -> Paper

powerMove3 playStyle =
  case playStyle of
    Aggressive -> Rock
    Glam -> Rock

powerMove4 playStyle =
  case playStyle of
    Aggressive -> Paper
    Glam -> Scissors

powerMove5 playStyle =
  case playStyle of
    Aggressive -> Paper
    Glam -> Paper

powerMove6 playStyle =
  case playStyle of
    Aggressive -> Paper
    Glam -> Rock

powerMove7 playStyle =
  case playStyle of
    Aggressive -> Scissors
    Glam -> Scissors

powerMove8 playStyle =
  case playStyle of
    Aggressive -> Scissors
    Glam -> Paper

powerMove9 playStyle =
  case playStyle of
    Aggressive -> Scissors
    Glam -> Rock
```

When we take the perspective that the "insides" of a function are essentially irrelevant, then there are only nine different functions that exist for this type signature. You may come up with a different implementation, but all of its return values for all of its input values will _exactly_ match one of the above instances of the function type.

So the cardinality of this type signature is nine! If you want to get a feel for understanding the cardinality of a function type, try reversing this one. Define all the variants of a `tieBreaker : RPS -> PlayStyle` function that, whenever two players tie on a move, it returns a `PlayStyle` that will automatically beat the other. e.g.

```elm
tieBreaker rps =
  case rps of
    Rock -> Aggressive
    Paper -> Glam
    Scissors -> Glam
```

That's just one example. How many others are there, or rather, what's the cardinality? _It's not nine,_ and I won't give it away, but once you've got them all down (or you have a guess), you can check against the general answer: for any function `a -> b`, its cardinality is "cardof type b **to the power of** cardof type a".


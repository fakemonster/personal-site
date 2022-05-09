---
title: Thinking algebraically
description: A vague description of the algebraic attitude.
---

# Thinking algebraically

This is an article about algebraic data types, but I don't really like the term. It makes it sound like "being algebraic" is a feature of _some_ types, when realistically it's more useful to say "it helps to think about your types algebraically".

To that end, let's look at some examples of types with _simple_ algebra, and then extend that out to algebraic thinking and how that can be useful.

Before we start: when you look around online, most examples you'll see, including this very article, will have types that look pretty Haskell-y; those examples might even be full sections of code in a functional language.

_It's succinct to express algebraic data types in most functional languages,_ but the expression of them is neither exclusive nor intrinsic to functional languages. You can use this thinking in virtually any programming language! To some degree I bet you already do, and "algebraic data types" just give you a better vocabulary for expressing this thinking.

---

Here's a type.

```elm
type Bool
  = False
  | True
```

Great!

In lots of languages, this could pass as an actual definition of the boolean type. In some languages' "core libraries", these three lines _actually exist_ (maybe it's just one or two lines). The "type" is `Bool`; the "variants" are `True` and `False`:

- The **type** is the _name of the universe_ that both defines and limits all possible values that could exist. When I say "I have a `Bool`", I could instead say "I have a thing. It's either a `False` or a `True`". `Bool` saves me some time. A different type is a different universe<fn symbol="1"/>.
- A **variant** is one of the "kinds of values" from this universe that may turn up. Sometimes when I have a `Bool`, it's an instance of `True`, because `True` is a variant of `Bool`<fn symbol="2"/>.

How many distinct values of `Bool` could possibly exist? Two: `False | True`. The **cardinality** of the type `Bool` is two. From here on out, when I say "the cardinality of type `X`," what I mean is "the number of distinct values of type `X` that could possibly exist". (When space is tight I'll actually say "cardof" instead of "cardinality of".) You'll see this term around; it comes from math, where "cardinality" is the number of elements in a set.

You could think of `Bool` as a set: `{False, True}`. `Int` is a set too: `{..., -3, -2, -1, 0, 1, 2, 3, ...}`. Every type is a set, in the sense that every type declares (or least implies) every possible value of that type. The cardinality of a set is the number of elements it has; the cardinality of a type is the number of elements that _could be._

Now we've got the vocabulary to lay it out: **algebraic data types (ADTs) are types where you control cardinality by creating and combining other ADTs.** If this feels too dense to parse right now that's fine; return when you're through and see if it resonates better.

<fn symbol="1">
  When you really land on this way of thinking about types you can see why some people say dynamic languages like JavaScript "only have one type." Sure, there are various primitives that are distinct, but looking at any given (exposed) variable, at any given moment, it _could_ be a string, a number, null, undefined, an object, an array (which is of course an object), a function (which is of course an object)... There's "only one universe", so "only one type".
</fn>
<fn symbol="2">
  There's a difference between variants and instances that isn't clear from the boolean example. A **variant** is what you see in a type definition. It might _look_ like a concrete value, but it's really just a type subdivision: it defines one way a type varies! An **instance** is a concrete value, not a component of a type definition: it's an "item" you can use in a program. So `type Bool = True | False` is a type with two variants `True` and `False`, and `x = True` is an instance of `Bool` being assigned to a variable. Their names collide because in practice this is a lot more useful than trying to distinguish them all the time. Sort of like the old parameters vs. arguments distinction! One is the name, one is the data; sort it out yourself.
</fn>

## Addition


`Bool` is nice, but what if we need more than two values? We're new here, and we don't want to mess with `Bool`, so instead we'll make a new type called `Cool`. We might be afraid of strangers, but we can still be fun.

```elm
type Cool
  = SomeBool Bool
  | TrueWithStylePoints
```

<aside>
In case the syntax is unfamiliar, let's clarify the components of `type Thing = Word OtherWord`:

1. `type`: just a label to say "type incoming!"
1. `Thing`: the name of our type. This has no special meaning, beyond the life we breathe into it now.
1. `=`: everything after this is the _definition_ of our type. This "assigns" that definition to our type name.
1. `Word`: a "variant" called Word. This too has no special meaning, beyond the life we breathe into it now.
1. `OtherWord`: I like to think of this as "the type inside of the variant." This _does_ have special meaning! Somewhere else there must be a definition of `OtherWord`, because while `Word` is basically a label that we just invented here, `OtherWord` refers to an extant type. That's why we can say `type Cool = SomeBool Bool`. `Cool` and `SomeBool` are new names, but `Bool` refers to the type we defined earlier.

The above example went a little further to add a `|`, and another word. The two together _add a variant_ to the type.
</aside>


So what kinds of values can `Cool` have? Well, an instance of it is either `SomeBool` with an instance of `Bool` inside, or `TrueWithStylePoints`. But to be thorough, let's enumerate all the values that could possibly exist.

```elm
allVariants : List Cool
allVariants =
  [ SomeBool False
  , SomeBool True
  , TrueWithStylePoints
  ]
```

As you can see above, the variant `SomeBool` is effectively a "namespace" for `Bool`, which itself has two variants. And `TrueWithStylePoints` doesn't have any type inside of it, so there's just one variant: itself. Our cardinality is **the cardinality of `Bool` (2) + the cardinality of `TrueWithStylePoints` (1) = 3**.

When people say something is a "sum type", this is what they mean: It's a type whose cardinality has been established by _adding_ variants.<fn symbol="1"/>

You don't have to add just one at a time! We could have done this:

```elm
type TooCool
  = SomeBool Bool
  | CoolBool Bool
```


Or this:

```elm
type BeyondCool
  = SomeBool Bool
  | OutOfSight
  | OffTheChain
```

Of these two, the first is "the cardinality of `Bool` within `SomeBool` (2) **plus** the cardinality of `Bool` within `CoolBool` (2)". The second is "the cardinality of `Bool` within `SomeBool` (2) **plus** the cardinality of `OutOfSight` (1) **plus** the cardinality of `OffTheChain` (1)". So both have a cardinality of 4!

Most interesting sum types are "composite types" like the above. Composite types are types that have some subtypes. So far the only subtype we've seen is `Bool`, but any type can be a subtype of any other type. If you're feeling saucy, a type can be a subtype of itself!

```elm
type NestingDoll
  = SmallestDoll
  | Doll NestingDoll
```

Here are some composite types that you see all the time in the wild:

1. `type Maybe x = Nothing | Just x `<fn symbol="2"/>. There may be something there, or not! Its cardinality is "one (for when it's `Nothing`) **plus** cardof `x` (for when it's `Just`)." This is a clean way of dealing with a nullable value, but I'd say that a nullable value _is also a composite type!_ It's a little harder to work with, but again it has two variants: the thing you asked for, and the "oops!" value.
1. `type Result x = Error String | Ok x`. Hopefully things work out, but if they don't, I'd like to get a message explaining what went wrong. Its cardinality is "cardof String (when it's `Error`) **plus** cardof `x` (when it's `Ok`)".
1. Floating point numbers: the IEEE 754 standard for floating points says that a floating point is either a "finite number", positive or negative "infinity", or a "NaN" (not a number). That could be something like `type FloatingPoint = Finite FiniteNumber | Infinity | NegInfinity | NotANumber`. Its cardinality is "cardof `FiniteNumber` **plus** 1 **plus** 1 **plus** 1".

And before moving on, we have to give some credit to enums: straight up and down, this is the iconic sum type. `type Direction = Left | Right | Up | Down`. Not a composite, for sure! But there's no better way to represent variance than variants. The cardinality of this example is "Left (1) **plus** Right (1) **plus** Up (1) **plus** Down (1) = 4".

<fn symbol="1">
  At this point (maybe earlier!), if you've used them before you'd probably ask "what's the difference between this and tagged unions?" Depending on the language you're talking about, there isn't one! "Sum type" is a more general term, so we don't get bogged down in the particular features of certain languages. Plus, in our context, I think sum type is more obviously related to product types, and "doing algebra".
</fn>
<fn symbol="2">
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

<aside>
I hope that the earlier use of `Bool` didn't mystify you too much; those were just names! _Because they both have a cardinality of two_, there's really nothing different between `PlayStyle` and `Bool` other than the names. (Most languages provide some standard library that makes booleans actually useful, to be fair! But 1. we could reimplement it for PlayStyle, and 2. with these examples, we aren't necessarily "in" a programming language, even if we're using the syntax of one.)

The [equivalence](#_Equivalence) section will dig into this a little further.
</aside>

Without defining the rules just now, these types let us imagine a game of rock-paper-scissors, where your play style has some effect. There are two possible values of `PlayStyle`: `Glam` and `Aggressive`, and three possible values of `RPS`: `Rock`, `Paper`, and `Scissors`.

For fun, we _could_ make a sum type combining the two:

```elm
type PlayStyleOrRPS
  = SomePlayStyle PlayStyle
  | SomeRPS RPS
```

with a cardinality of 5. But that doesn't seem like a very useful thing to represent, to be honest. Some individual entity is _either_ a PlayStyle or an RPS? What would that even be?

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

In lots of languages, product types are really the rule of law. An object/struct/record/class-instance with fields is a product type: its cardinality is the product of the cardinalities of its fields.

```ts
interface Text {
  fontSize: number;
  content: string;
}
```

This could have values like `{ fontSize: 16, content: "hello!" }` or `{ fontSize: 15, content: "begone!" }`, so its cardinality is "cardof `number` **times** cardof `string`."

Some other product type examples:

1. Tuples like `(PlayStyle, RPS)`. This is effectively the same as the `Play` type we defined earlier, it just doesn't have any names (which is good or bad, depending on your opinion).
2. `type Round = Unstarted | OnePlayed Play | BothPlayed Play Play`. This is a type that uses both summing and product-ing: A given game round of RPS could be in the state where no one has moved, someone has moved a little early, or both players have moved. This type has some "depth", in that `Play` is a pretty complex subtype, but when we're calculating the cardinality there's really not much special about it. The cardinality of this type is "cardof `Unstarted` (1) **plus** cardof `Play` (we found this to be 6 earlier) **plus** (cardof `Play` (6) **times** cardof `Play` (6))". That's **1 + 6 + 36**, for a grand total cardinality of **43**.


## Where sum types can save you

Honestly, you know when to use product types. Sometimes you just need a string and a number! **And** is the magic word. If you have two independent values, and you need them in one place (think first **and** last name), that's a product type. Sum types, the world of **or**, are really where we can get more creative.

Let's take an example: a record that indicates the name of a plant, whether it's edible, and how many calories it has in a serving:

```elm
type alias Plant =
  { name : String
  , calories : Int
  , edible : Bool
  }
```

<aside>
Don't be thrown by "alias" in that snippet: elm records are defined anonymously, so this is just a way of putting a name on one.
</aside>

When we use this type, the only thing we care about is how many calories you get if you eat it:

```elm
calorieCount : Plant -> Int
calorieCount plant =
  if plant.edible then plant.calories else -1
```

Well, that's not quite right... you're not gonna _lose_ calories if you eat an inedible plant (though that depends on your reaction!). Maybe return 0 instead, since you won't eat it? But then if there are zero-calorie plants, is that confusing? Can a plant really be _zero_ calories? Didn't I read something about how celery has negative calories??

The problem here is that integers _don't have enough cardinality_ for the problem space. No integer can express "please don't eat poison ivy". Really, we just want to say "here's the calorie count" _or_ "that's irrelevant, don't eat this":

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

```
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

In the original version, `Plant` was a product of String, Int, and Bool; its cardinality was "cardof String * cardof Int * 2". Now, its cardinality is "cardof String * (cardof Int + 1)". It's virtually cut in half! Complexity is death by a thousand cuts, and a good sum type has saved us from 499 of them.


## Equivalence

The notions of addition and multiplication are pretty mechanical. Even the above refactor we did is mechanical, once you recognize it! And this is one of the ideas I hope you can walk away with: some design questions can become mechanical in this framing. "These types come together to form n * 2 values, but we definitely only care about n + 1 of them; let's represent it that way!"

Still, once you've established the mechanical component of type algebra (which is more literally the "algebra" I guess), there remains a lot of room for design.

Here's the trick: with two types of the same cardinality, you can define an **isomorphism**, which for our purposes just means "two functions that convert between types losslessly". With an isomorphism, you can go from one type to the other and back, and you wouldn't be able to tell anything "happened" at all.

The isomorphism itself isn't used that often, and usually isn't all that interesting either. Its real value comes from the implication of "going back and forth": with that ability, isomorphism means that 100% of the time, no matter what, no exceptions, when you're using one type, _you could be using the other instead._

Here are two isomorphisms from `Bool` to `PlayStyle`:

```elm
-- Isomorphism 1
createAggressive boolean =
  case boolean of
    True ->
      Aggressive
    False ->
      Glam

isAggressive playStyle =
  case playStyle of
    Aggressive ->
      True
    Glam ->
      False


-- Isomorphism 2
createGlam boolean =
  case boolean of
    True ->
      Glam
    False ->
      Aggressive

isGlam playStyle =
  case playStyle of
    Glam ->
      True
    Aggressive ->
      False
```

Again, the contents aren't all that important, their behavior is: for both isomorphic function pairs, `createPlayStyle (isPlaystyle playStyle)` and `playStyle` are always the same thing. As long as you can find two functions that do this (and you always can when your types share cardinality), then you've got equivalent types.

Here are some really common places equivalence comes up. No new ideas here, just a different way of expressing some (hopefully!) familiar ones.

### Is `bool` really enough?

When you're representing something with a boolean, try replacing it with a custom type (like `Aggressive` and `Glam`). The types are equivalent since their cardinality is the same. And the custom type you come up with has a couple of benefits:

1. The clarity you can get with custom types is always going to be greater than the clarity you can get with a boolean. `isBlue: Bool` tells you less than `Mood = Blue | Chipper`.
1. It's super easy to extend. The classic example is building a permissions system: you start with admins and users. if you structure along the lines of `isAdmin: Bool`, then when the moderator role comes in, you're stuck with `isAdmin: Bool, isModerator: Bool`, which is awkward since all admins can moderate. If you had started with `role: Admin | User`, then you could simply tack on a variant: `role: Admin | Moderator | User`. You fool!

### Going up

Maybe you need to serialize two strings, a first and last name. Within whatever runtime we're in, we could have a product type like `Name String String` or `{ firstName : String, lastName : String }`. Serialized we could obviously stick to the latter, but why not join them into one string? Save a little space!

**String * String is infinite**, and so is **String**, so the cardinalities are the same, right? They're both infinite! But what's the isomorphism? If you join by space, then to go back you'd have to separate by _some space character_, but you don't have a way of knowing which space character is the "joiner" and which ones are part of a first or last name. You'd have to reserve a character for joining, or add an index to split at.

`String` and `Two String String` are _not_ equivalent, because you can't draw an isomorphism. Things get complicated with infinite cardinalities.

Sometimes you can find isomorphisms in infinite cardinalities, though! For instance, `String` and `List Char` (`Char` being a single character). Those are both infinite, but it's pretty easy to find an isomorphism there: just split them apart, or stick them all together.

## Lots of ways to five

Let's bring back our rock-paper-scissors players, and build them a social graph (this is what the RPS community needs to finally get the visibility they deserve).

Graphs are a collection of vertices (people) and edges (two-person relationships), and for now we're just going to think about edges. So let's say

```elm
type Player =
  { name : String
  , style : PlayStyle
  }
```

defines a vertex and move on. How can "vertex one" relate to "vertex two"? In our model, these are the kinds of relationships we want to track:

```elm
type Relationship
  = Defeated
  | DefeatedBy
  | Coached
  | CoachedBy
  | Family
```

Players can defeat one another, players can coach one another, and they can be family. Simple enough!

This is what I would call the "flat" way of representing our possible relationships: each variant has zero subtypes. It's got a cardinality of **1 + 1 + 1 + 1 + 1 = 5**. But can we think of other _equivalent_ representations? Or to put it another way, what other types have a cardinality of 5?

```elm
type Directional
  = Coached
  | Defeated

type RelationshipTwo
  = Outgoing Directional
  | Incoming Directional
  | Family
```

Here's an equivalent one! Let's spell out the possible variants:

```elm
allVariants : List RelationshipTwo
allVariants =
  [ Outgoing Coached
  , Outgoing Defeated
  , Incoming Coached
  , Incoming Defeated
  , Family
  ]
```

The cardinality is **2 + 2 + 1 = 5**. So it's equivalent!<fn symbol="1"/> Because of that equivalence, _anything you can do with one can be done with the other_. The only difference is in the ergonomics. For instance:

```elm
isOutgoing : Relationship -> Bool
isOutgoing rel =
  case rel of
    Defeated ->
      True
    Coached ->
      True
    _ ->
      False

isOutgoingTwo : RelationshipTwo -> Bool
isOutgoingTwo rel =
  case rel of
    Outgoing _ ->
      True
    _ ->
      False
```

_In this case,_ our new equivalent type is easier to work with! We only have to express one specific case to capture the notion of whether or not this edge is outgoing.

With this design we teased apart the notions of _direction_ and _interaction_ in RPS relationships. How else could we tease concepts apart?

```elm
type Position
  = Subject
  | Object

type RelationshipThree
  = Coaching Position
  | Defeating Position
  | Family

haveCompeted : RelationshipThree -> Bool
haveCompeted rel =
  case rel of
    Defeating _ ->
      True
    _ ->
      False
```

With this one, we've flipped around the "directions" and "interactions". It's about as clunky for finding out "is it outgoing" as the original, but if you want to know "have these players competed?", that's nice and easy.

There are more ways of representing these relationships equivalently! The only rule is that there must be 5 unique instances of a type. These are just some straightforward examples. We can see that some are better in certain use cases, and some are worse! When you're dealing with equivalent types, the main thing to remember is that there is _no mechanical difference._ Pick (or invent) the type that's most useful.

---

Let's solve something a little more advanced. First, we'll lay out the rules that complicate our relationships:

1. A player cannot coach a player that coached them.
2. Family members _never_ compete. If two competitors later join into one family, any prior competition between them should be wiped from history.

If we wanted to have a collection of _all_ the relationships two players have, how do we make sure there aren't any incompatible ones?

We're stepping up a level here. We're not asking "what kinds of edges can exist?" Instead we're asking "what _collections_ of edges can exist?" A regular old set of edges (e.g. {Coached, Family}) could have incompatible edges in it.

Let's enumerate these mutually incompatible relationships (we'll go back to the flat representation to stay open-minded):

```elm
invalidPairs : List (Relationship, Relationship)
invalidPairs =
  [ (Family, Defeated) -- forbidden
  , (Family, DefeatedBy) -- forbidden for the same reason
  , (Coached, CoachedBy) -- makes no sense!
  ]
```

Two players can both defeat each other, and trainees can play their coaches. But some players can't compete, and the duties of a coach are too sacred to simply be reversed.

An observation: we can see that being a coach/trainee (let's call it "mentorship") and playing/not playing don't really intersect as concepts. Or at least, they don't intersect _in ways that we care about._ So let's split them up!

```elm
type Mentorship
  = Coach
  | Trainee

type Decision
  = Win
  | Loss
```

We've broken mentorship (**2**) away from the concept of defeat (**2**). But we started with 5! Where did our familial relationship go? It'll turn up again when we join everything back together.

```elm
type Competition
  = Family
  | Competing (Set Decision)

type alias Relationships =
  (Competition, Maybe Mentorship)
```

<aside>
In real life I'd use a record for `Relationships`, and I think you should too, but for this article I'm trying to save a little space!
</aside>

Let's get into this bit by bit. First off, there's a `Set Decision`. `Set a` is a set of elements from `a`. There are never duplicates, so each member is unique. This is a small enough collection that we can enumerate them all: `{}`, `{Win}`, `{Loss}`, `{Win, Loss}`. (Sets aren't ordered, so `{Loss, Win}` is the same thing as `{Win, Loss}`.) So `Set Decision` has a cardinality of **4**.

That set is _inside_ of the `Competing` variant, which comes along with that empty `Family` variant to recognize the notion of "no competition". So the cardinality of their type (`Competition`) is **1 + 4 = 5**.

The `mentorship` field does something similar: Maybe types add a **Nothing** variant, so a `Maybe Mentorship` is a **1 + 2 = 3** cardinality.

And finally, tuples are product types, so the cardinality of Relationships is **5 * 3 = 15**. A total cardinality of 15! To put it another way, when you ask me "in what ways are Player X and Player Y related?" I can only answer in one of 15 different ways.

_But is this answer right?_ A straightforward `Set Relationship` would have a cardinality of **32**<fn symbol="2"/>, meaning that our new formulation eliminated 17 variants. Were there really 17 invalid variants??

Fine, let's check our work...

```elm
allSets : List (Set Relationship)
allSets =
    , [] -- obviously fine (1)
    , [ Coached ] -- ok (2)
    , [ CoachedBy ] -- ok (3)
    , [ Coached, CoachedBy ] -- nope!
    , [ Defeated ] -- ok (4)
    , [ Coached, Defeated ] -- ok (5)
    , [ CoachedBy, Defeated ] -- ok (6)
    , [ Coached, CoachedBy, Defeated ] -- nope!
    , [ DefeatedBy ] -- ok (7)
    , [ Coached, DefeatedBy ] -- ok (8)
    , [ CoachedBy, DefeatedBy ] -- ok (9)
    , [ Coached, CoachedBy, DefeatedBy ] -- nope!
    , [ Defeated, DefeatedBy ] -- ok (10)
    , [ Coached, Defeated, DefeatedBy ] -- ok (11)
    , [ CoachedBy, Defeated, DefeatedBy ] -- ok (12)
    , [ Coached, CoachedBy, Defeated, DefeatedBy ] -- nope!
    , [ Family ] -- ok (13)
    , [ Coached, Family ] -- ok (14)
    , [ CoachedBy, Family ] -- ok (15)
    , [ Coached, CoachedBy, Family ] -- nope!
    , [ Defeated, Family ] -- nope!
    , [ Coached, Defeated, Family ] -- nope!
    , [ CoachedBy, Defeated, Family ] -- nope!
    , [ Coached, CoachedBy, Defeated, Family ] -- nope!
    , [ DefeatedBy, Family ] -- nope!
    , [ Coached, DefeatedBy, Family ] -- nope!
    , [ CoachedBy, DefeatedBy, Family ] -- nope!
    , [ Coached, CoachedBy, DefeatedBy, Family ] -- nope!
    , [ Defeated, DefeatedBy, Family ] -- nope!
    , [ Coached, Defeated, DefeatedBy, Family ] -- nope!
    , [ CoachedBy, Defeated, DefeatedBy, Family ] -- nope!
    , [ Coached, CoachedBy, Defeated, DefeatedBy, Family ] -- nope!
    ]
```

You don't actually have to read that. I stuck a count on the right so you can see how many acceptable instances of `Set Relationship` exist. That's right: 15! And it's not a coincidence. Here's an illustration of an isomorphism between the _valid_ variants of `Set Relationship` and our well-designed `Relationships` tuple.

```elm
{-| Generally, I think code examples should actually compile. This function is
here to save some space and is otherwise unimportant.
-}
toCompeting : List Decision -> Competition
toCompeting decisions =
  Competing (Set.fromList decisions)

validSets : List (Set Relationship)
validSets =
    [ [] -- (Nothing, toCompeting [])
    , [ Coached ] -- (Just Coach, toCompeting [])
    , [ CoachedBy ] -- (Just Trainee, toCompeting [])
    , [ Defeated ] -- (Nothing, toCompeting [Win])
    , [ Coached, Defeated ] -- (Just Coach, toCompeting [Win])
    , [ CoachedBy, Defeated ] -- (Just Trainee, toCompeting [Win])
    , [ DefeatedBy ] -- (Nothing, toCompeting [Loss])
    , [ Coached, DefeatedBy ] -- (Just Coach, toCompeting [Loss])
    , [ CoachedBy, DefeatedBy ] -- (Just Trainee, toCompeting [Loss])
    , [ Defeated, DefeatedBy ] -- (Nothing, toCompeting [Win, Loss])
    , [ Coached, Defeated, DefeatedBy ] -- (Just Coach, toCompeting [Win, Loss])
    , [ CoachedBy, Defeated, DefeatedBy ] -- (Just Trainee, toCompeting [Win, Loss])
    , [ Family ] -- (Nothing, Family)
    , [ Coached, Family ] -- (Just Coach, Family)
    , [ CoachedBy, Family ] -- (Just Trainee, Family)
    ]
```

<fn symbol="1">
If we're being strict, then remember we need an equal cardinality _and_ that pair of back-and-forth functions we call an isomorphism. But if the cardinality is finite and equal, there's always at least one isomorphism. We just need to specify it! Hopefully, all the examples here should have clear isomorphic functions.
</fn>
<fn symbol="2">
How do we get this number? Earlier I described types as "the set of values that could be". So a set of some type **Other** is "the set of values that could be a set of values from **Other**". In other words, a set of sets! So we can phrase that differently: "the set of all subsets of **Other**", which includes the empty set and **Other** itself. There's a great term for this: the [power set](https://en.wikipedia.org/wiki/Power_set). And when the core set is finite (if we only use custom types then it's always finite!), then the cardinality of a power set is **2\**(cardof set)**. That's how we get a **cardof 32** for `Set Relationship`.
</fn>

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

That's just one example. How many others are there, or rather, what's the cardinality? _It's not nine,_ and I won't give it away, but once you've got them all down (or you have a guess), you can check against the general answer: for any function `a -> b`, its cardinality is **cardof b ^ cardof a**.

### Expo-equivalence

If you're reading all the footnotes, you may have noticed something: this exponentiation example (functions) isn't the first time we've actually _seen_ exponentiation in type algebra. The first time was looking at the cardinality of `Set a`, which is **2 ^ cardof a**.

Let's relate that back to our cardinality calculation for functions (**cardof b ^ cardof a**): a `Set a` is isomorphic (i.e. equivalent) to any function going from `a` to `b` where **cardof b = 2**.

An easy choice for a **cardof 2** type is `Bool`, so let's plug it in:

The type of "functions from `a` to `Bool`" is isomorphic to `Set a`. In plain English, "there's no difference between a set of values and a function that tells you which values are in that set".


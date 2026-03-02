---
title: Five years of Elm in production
description: Looking back at the evolution of a fairly large Elm codebase.
---

# Five years of Elm in production

Since 2021, I've been working at Deepgram on a few different properties. The two biggest of these are Elm codebases: our API playground, and our developer console. When I first started, I felt like we were in the dark on what it looks like to start up a long-lived Elm project in a product-led-growth company. Or, really, any company! I knew about _evidence,_ with companies like NoRedInk and Brilliant, but I knew little about experience. So I figure I can share some experience myself. Maybe you'll disagree with my conclusions, but at least you'll have a jumping off point.

Importantly, I don't want to spend time convincing you to use or not use Elm, nor do I want to impart the important lessons you should learn _before_ embarking on a major technical investment in this language; I think there's sufficient material out there for both already. But if you're considering putting Elm into practice, and thinking that you don't have a lot of examples of what it's like post-greenfield, then I want to give you one.

<aside>
First, a concession: I began writing this at just about 4.75 years in prod. But that's not all too catchy, and I'm pretty sure it'll take me three months of small bursts to be happy with the article anyways.
</aside>

## A rough timeline

In 2021, Deepgram had turned up for me in a StackOverflow jobs search for Elm jobs. (I was probably the one person on Earth who found a job this way.) The company had a number of substantial Elm projects, and some great developers with expertise in it, but when I had turned up, they were working exclusively on our (Rust) backends. It turns out if you're an API company, you need a lot more backend devs!

I was hired for our initial push to build the developer console. So strictly speaking, there wasn't yet "an Elm project" to work on, despite the ton of Elm code that already existed at the company. We were breaking ground.

I had been writing React for four-ish years at this point; to put myself in the wider historical context, hooks had been out for a while, but I was raised in the "class components for state, function components for pure view" era. But I'd also been well-exposed to functional concepts: Redux had me primed for the Elm Architecture, Recompose had me (over)leveraging higher-order functions, and my old job's utility library was, if you can believe it, [Ramda](https://ramdajs.com/). I'd also been tricked into messing with Haskell by a friend, so even syntactically Elm was straightforward for me to pick up. Still, by the time I joined Deepgram I'd only been writing it a couple months, even if I loved it.

So when I got asked to get on a call a week before my first day with the CEO and Head of Product about what we'd be building this critical new project in, the subtext was obvious to me: while the company believes in Elm, and believes in its devs taking risks _they_ believe in, this project had to go right, and so it had to go safe; React would be "the right choice".

Instead, the conversation went as thus: I talked about my experience with React, and I talked about what I thought it would be like to work in Elm. Remember, I _hadn't_ worked in Elm, at least professionally! But I knew what immutability, pure view, algbraic types, and zero side-effects would do for a project all the same (especially if you could actually enforce those things). So I talked through what I thought would be easier, what would be harder, what would be better or worse with both options. By the end, they said Elm seemed like the right choice.

Good news for me! I get to write Elm! But bad news too: I've got to deliver.

All I know at this stage of the project is that we're building an SPA. Everything is behind a login, there's a bunch of pages, and our backend is a JSON API. So Step 1 was create-elm-app (remember create-react-app?), and Step 2 was a straight rip of Richard Feldman's [elm-spa-example](https://github.com/rtfeldman/elm-spa-example).

Step 3 turned out to be the most important: I got to work with a phenomenal engineer who already had a _lot_ of Elm experience. He lived in France, and I lived in Los Angeles, so (in California time) a frontend work day at Deepgram looked like this:

```
12:00AM - Phenomenal engineer reviews my code from the day before, merges it, makes changes he wants to make, then does his own work.
9:00AM - Phenomenal engineer graciously has a 6pm standup meeting with me where we talk about what he did that day, and what I'm planning on doing.
9:15AM - I review Phenomenal engineer's code, merge it, make the changes I want to make, then do my own work.
```

Many times, he had the foresight to drive some architectural decisions that I didn't have the context for. A great example of this is our eventual implementation of the [Effect pattern](https://sporto.github.io/elm-patterns/architecture/effects.html), which I had never even heard of, but now swear by. Seriously, if you have more than one module that produces a `Cmd`, consider the Effect pattern. He also helped push my own designs to be more rigorous and _less_ complicated than they needed to be.

Eventually, Phenomenal engineer moved on. For a brief period I was my team's only frontend developer, but pretty quickly we picked up a second. It's gone up and down, but we're a little squad now (plus I goaded my manager into making PRs).

## General lessons

### It's pretty hard to build up technical debt

People talk a lot about "fearless refactoring" in Elm, and it's true. It's really hard to illustrate it succinctly. Maybe I'll record myself spending 4 continuous hours without my code compiling, getting it to compile, taking a quick look, and then committing it all.

In terms of my emotional health, fearless refactoring is the best emergent feature of Elm. But it also has a really huge benefit that you really only see in long-lived projects. If you take a swing at a big subsystem concept, and then a year later you realize it's _wrong,_ then you just get rid of it. It takes maybe a week if you really got it wound up tight in every corner. This is simply not an experience I've had in another language. Rust comes close, though! Just compiles a little slower.

"Subsystems" here means code you whipped together that "completely solves one problem". Some examples of that: notification toasts, client-side page routing, theming, analytics tagging. For all of these we came up with something, shipped it, and came back 1-6 months later and said "no, let's do it different". And then we just did it different! No fighting with leadership to carve out a technical debt project, because the debt is small.

### You still need tests

I'll be blunt: I started this project with an open heart and a vague memory of someone saying "you only need tests because your types aren't good enough". It's not that we have _no_ tests, but we have way less than you think. The reality is that your types can prove a (non-total) quantity of correctness, and your tests can disprove a (non-total) quantity of incorrectness. Neither truly substitutes the other.

The Elm type system is extremely powerful, but it's not perfectly expressive, and so inevitably there's a collection of behaviors that you'll have to disallow with tests. Way less than the alternatives, in my opinion (not just because of types but because of FP), but still nonzero.

While we may never really have to deal with runtime errors, there are regressions in our business logic that only get caught during review because the reviewer _remembers an old requirement_ and sees it's been invalidated. Especially now that I'm starting to see AI contribution, the need for tests as a quality control measure _and_ a feedback mechanism for LLMs is apparent. So we need to push our coverage up.

### Elm-review is the secret

Elm-review is the really smart "yes-and" answer to "linting" in the Elm ecosystem. It's nontrivial to write an elm-review rule, but I strongly recommend you write at least one to understand how much power this tool can offer. It's not just coding style controls! Beyond the standard stuff, here are some rules I use to make guarantees about my entire codebase:

1. [NoMissingTypeConstructor](https://package.elm-lang.org/packages/Arkham/elm-review-no-missing-type-constructor/latest/): if someone makes a constant called `allX : List SomeType`, elm-review will fail if that list doesn't have every constructor of that type
2. [NoFunctionOutsideOfModules](https://package.elm-lang.org/packages/henriquecbuss/elm-review-no-function-outside-of-modules/latest/): I use this to disallow every module in my repo from calling the `button` function _except_ the one that wraps around it to make sure analytics attributes are present
3. PreferTailwindUtilsToCssProperty (this one's in-house, sorry): given a call of `Css.property`, check if that invocation already exists in our Tailwind.Utilities (we use [elm-tailwind-modules](https://github.com/matheus23/elm-tailwind-modules), roughly speaking) and autofix your call to reference that instead

Elm-review carries enough information about your entire AST that, in combination with its autofixing, you really can think of it as a codegen tool. Though, on that note, you should really consider using elm-codegen as well. We use it for our [feature flags](https://package.elm-lang.org/packages/fakemonster/elm-codegen-feature-flags/latest/)!

### Web components are the other secret

I love [Luke Westby's talk](https://www.youtube.com/watch?v=tyFe9Pw6TVE) on using web components in Elm, so I won't rehash it. But I will enumerate the two kinds of problems that I've solved with web components, because if I _didn't_ have web components, I probably would've regretted choosing Elm for Deepgram:

1. integrating JS libraries that have no Elm equivalent. To name a couple examples: Stripe and Lottie. These companies aren't building Elm implementations any time soon (and in fact these technologies leverage web components themselves. Thank you web components!).
2. integrating browser APIs that have no Elm implementation. Strictly speaking, this can all be done with ports, but there are benefits to web components. In particular, you do not need to label your messages (think about how trackers in Http need a string), and if you're _very_ careful, you can sneak in side effects through attributes/properties. We use web components for ResizeObserver, IntersectionObserver, and the Web Audio API. We actually use web components for websocket management!

### You probably want a monorepo

We have a slightly interesting story in that our two biggest Elm projects (the developer console and the API Playground) are independent repos owned by the same team, with the latter coming much later. This came after some discussion, and we were motivated by two main arguments:

1. The API Playground is a "serious" project. It's big enough and distinct enough from the dev console that it could easily be owned by a standalone team in the future. Architecture reflects your org, or vice versa, ipso facto, different repo.
2. There was a big educational/exploratory opportunity here; did we _need_ the same localization approach? Did we approach theming the right way? Enough was functionally distinct about what the product org wanted with the API playground that we thought to use it as a playground _for our devs too,_ to experiment with different architecture strategies.

I don't regret this choice, but maintenance is objectively more complicated. If someone has a new cool elm-review rule, they make two PRs for it. When we migrated from eslint 8 to 9, I had to figure out why these two configs were different while migrating them independently.

You can't have a private package in Elm, and for things like our theming library at work, it just
didn't make sense to publish it (honestly even if we _could_ have private packages, I'm not sure it
would make sense to deal with the overhead). It's plain easy to have a monorepo, and it's not like
you're impacted by compile times.

---

Those are some of my lessons. Hit me up in the Elm Slack if you have thoughts! I want to hear if you're happy with your own technology choices.

So on that note, in case you came to this article feeling existential, let me answer the big question for you.

## Would I choose Elm for production again?

Yup. It's not particularly close. While I do earnestly believe that with enough smart people, you'll survive any frontend framework/language choice, this one was a real positive call for the team and the company.

So I wouldn't change the choice, but I will revisit the bets I made when I pitched our leadership on Elm:

### Hiring should be easier (more of a wash)

My thinking here was that picking a "weird" stack means your applicants are people who are _excited_ about your stack. For them to be excited they must be pretty well-studied! I'm not the first one to make this claim, but I will caveat it: the pool is qualified but _very_ small. If you actually filter for "has Elm experience", then there's just not a lot of people! And you still have to deal with a mass of applicants who _don't_ have Elm experience, and just claim they do.

So in my opinion, there's just no point filtering for it. We tell everybody we use Elm, I think it does attract great talent, but we still benefit from the attitude that "you can learn it on the job" (an engineering org that's mostly Elm and Rust pretty much _has_ to have this opinion). So it's been more common that we hire React developers who are familiar with functional programming than it is to hire Elm developers.

### Brand-new Elm apps are slow to build (underestimated)

As I noted above, fearless refactoring means you eliminate a lot of risk in decisionmaking. But even if that refactoring is really safe, you're still doing it. If you aren't diligent, you can lose your productivity to your imagination while you learn your domain.

Plus, when you're building up the Effect pattern from scratch, or designing your API handling module, you're doing stuff that in JavaScript frameworks is probably already handed to you. You might not always like Next.JS (I know I don't) but you aren't going to spend time thinking about how page routing is going to work. That said, our projects are truly from-scratch, and your mileage is going to vary if you use elm-pages or elm-land.

Keep in mind, these are slowing factors in _making a production codebase._ When I'm making throwaway code, I personally find using Elm to be faster to prototype, even if I have to rig up a bunch of port/web-component plumbing (which I often do, since Deepgram is a pretty audio-forward company!). But if you're thinking about maintenance in the long run, time-to-first-launch might be, say, 6 weeks for React and 8 for Elm. Account for it.

### Old Elm apps are easy to maintain (underestimated)

There are well-studied reasons that you could just assume this is true: pure functions eliminates classes of errors, algebraic data types are superior for domain modeling, Elm dependencies can't have security vulnerabilities (unless you're using Sub or Cmd from them of course). I just thought these would be minor effects on balance, and they turned out major. The bug incident rate on our dev console is vanishingly low, and mostly caused by whack-a-mole with browser extensions. Our API Playground has a lot more TypeScript (GitHub suggests it's around 6%) since it does so much audio and websocket work, and that interop-ing code is always going to be a point of failure, but even then bugs are pretty uncommon (and I attribute much of it to us still learning the best practices of web components).

And most importantly, when the product vision changes, it is stupid easy to just rewrite the type, chase the compiler, and commit. I simply don't worry about shuttling around a ton of code, and I don't have to prove I did it right; the compiler (and elm-review!) do it for me.

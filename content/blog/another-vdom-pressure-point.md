---
title: One more Elm VDOM pressure point
description: We found a lightweight technique for letting users run Google Translate in our Elm apps without the house falling down, and without patching the compiler.
---

# One more Elm VDOM pressure point

Recently, we had a very fun VDOM bug at work caused by Google Translate. This is actually the _second_ bug with Google Translate we've encountered, the first being a well-known issue where Google Translate is a little too liberal with `<font>` tags.

Working in Elm (or, really, any language/framework with a VDOM) we've gotten pretty used to browser extensions like password managers or, say, Grammarly, totally obliterating our pages. Sometimes the fix is just to disable extensions, but whenever we can we like to let people keep their toys, and this is a case where we could without risking damage to the VDOM.

But first,

## What do you mean VDOM?

The very short version is that VDOM (short for "virtual DOM", itself short for "virtual Document Object Model") refers to a "virtual" implementation of the DOM that represents what you see and interact with on a website. Mutating the DOM is verbose and error-prone, so the VDOM acts as a convenient interface for end developers like me to focus on content. The VDOM library author's code will deal with the work of translating the virtual DOM we change to the (verbose but generally sound) real DOM.

Maybe, as an "interface" author, I'll come up with something that looks a bit more like I'm writing HTML than like I'm executing JavaScript:

```jsx
const ProfileBar = ({ name, avatarSrc }) => (
  <div className="profile-bar">
    <div className="profile-bar__name">{name}</div>
    <img className="profile-bar__image" alt="Profile image" src={avatarSrc} />
  </div>
);
```

or maybe a nice functional style...

```elm
profileBar name avatarSrc =
    div
        [ class "profile-bar" ]
        [ div [ class "profile-bar__name" ] [ text name ]
        , img [ class "profile-bar__image", alt "Profile image", src avatarSrc ] []
        ]
```

These (React and Elm) are both functions that return VDOM in their respective implementations (a `ReactNode` and an `Html msg`, respectively). Then the library takes on the important work of **diffing:** comparing the VDOM it receives to the _last iteration,_ finding all the differences, and then hopping into the DOM to make modifications. This is more performant than rebuilding the DOM tree every time, and because the framework/library is continuously resynchronizing the DOM to its VDOM, end developers can generally think of the VDOM as interchangeable with the real DOM.

> You may have heard this relationship referred to as "transparent", or, incredibly, "opaque." I prefer "interchangeable", mostly because no one will ever say its opposite somehow means the same thing!

For a more thorough explanation of VDOM you should visit the [Elm guide](https://guide.elm-lang.org/optimization/lazy.html), which describes why you'd use VDOM _in general,_ as well as the basic principles underlying it. But for us, we'll need to get a bit more into the details of how VDOM management works in Elm specifically.

## Elm specifically

Elm has a [few core functions](https://package.elm-lang.org/packages/elm/browser/latest/Browser) that deal with, among other things, translating VDOM into the DOM. Each is slightly more "advanced" than the last; more control in exchange for greater complexity. The most complex (`Browser.document` and `Browser.application`), when used to make a single-page app, will _clean out_ `document.body`, and render all of their content inside of it. As an example, let's say your entry point looks like

```elm
main : Program () Model Msg
main =
    Browser.application
        { view: \_ ->
            { title = "My site!"
            , body =
                [ div [ id "hello" ] []
                , div [ id "joe"] []
                ]
            }
        -- yada yada yada
        }
```

then the Elm runtime will take that **VDOM** that you've returned from your `view` function, diff it from the **real DOM** (which is initially `<body></body>`), and then apply all the differences, leaving you with a `document.body` that (in plain HTML) looks like

```html
<body>
  <div id="hello"></div>
  <div id="joe"></div>
</body>
```

(To be clear, what I've written above isn't "the DOM", it's just what you would see in the Elements tab. If you want to see "the DOM", get an HTML page that looks like that, and in the javascript console look at the aptly-named `document` object.)

Point is, Elm is taking over the DOM _as high up as possible_ when it's using `Browser.application` or `Browser.document`; this is because it's handling things like page navigations and browser titles for you, and so it sort of expects that it's in control of everything!

## Lay of the land

To greatly oversimplify, our Elm application at work looks fundamentally similar to the previous example:

```elm
main : Program () Model Msg
main =
    Browser.application
        { view = \_ ->
            { title = "Welcome to Business"
            , body =
                [ div [ id "main" ] []
                , ul [ id "notifications"]
                    [ li [] [ text "You've got 3975 new followers!" ]
                    , li [] [ text "Your latest post was a big success." ]
                    , li [] [ text "Everyone's very proud of you." ]
                    ]
                ]
            }
        -- yada yada yada
        }
```

The actual list in the Elm code above is essentially what the Elm VDOM uses as its representation; if you add a class to that `ul#notifications` element, Elm will:

1. visit the DOM's `body` element,
2. find the second element of its child list (`ul#notifications`), and
3. add a class to it.

Let's take a slightly tougher example, and modify the text of the third notification to "extremely proud". The DOM is a tree, so Elm can take advantage of that:

1. visit the DOM's `body` element,
2. find the second element of its child list (`ul#notifications`),
3. find the third element of _that_ element's child list (`li [] [...]`),
4. find the first element of _THAT_ element's child list (`text "Everyone's very proud of you."`), and
5. change the text.

We call this an **index basis** for VDOM diffing, since the tree traversal is simply descending through indices until it's "at the right spot".

### Soundness of VDOM

In programming you generally hear about "soundness" in reference to a type system, as in "this type system is unsound", or "this type system is sound" (a fun lie). But more generally it can mean "this idea always makes sense," and I'm here to tell you VDOM does not always make sense. For the notion of VDOM to work, you're assuming that

1. all values and guarantees represented in VDOM can be mapped losslessly into them DOM
2. to know what changes to map into the DOM, you can compare your old VDOM to your new VDOM

The first is why VDOM is "nice to write", the second is why VDOM is generally "fast enough." _Both are untrue because other stuff mutates the DOM sometimes._ But let's start with an example where this unsoundness isn't a big deal.

Let's say you've got a browser extension that puts a little widget over whatever page you're on; it's an image of a well-camouflaged animal, and if you can find that animal you'll win a little crypto. To show you that image, the extension must mutate the DOM! Sticking to our example, most extension authors are generous enough to do so in this way:

```html
<body>
  <div id="main"></div>
  <ul id="notifications"></ul>
  <div class="fuzzyfinder">
    <img src="https://fuzzyfinder.online/asset/80ae3b1.jpg"></img>
    <button class="fuzzyfinder__answer"></button>
  </div>
</body>
```

What's most important here is that it's at the _end_ of the child list. With an index basis, as far as Elm is concerned, that last div doesn't even exist. Unsound? Yes. A problem? no. You can keep clicking your crypto capybaras without a care.

## Now for the bug

We got a report that Google Translate was crashing our app. This was kind of odd because we've definitely used Google Translate on the app before, and as mentioned up top, we'd already added a patch to fix it. And we couldn't immediately reproduce the issue, either.

But as it turns out, the "it" was a _different_ Google Translate bug, and not with the extension as we had assumed, but the built-in translate functionality in Chrome. When you translate a page, _two_ widgets pop up (cmon!), and not exactly where you'd like:

```html
<body>
  <div id="main"></div>
  <div id="goog-gt-tt"><!-- some bullshit --></div>
  <ul id="notifications"></ul>
  <div class="goog-gt-tt"><!-- some more bullshit --></div>
</body>
```

That's right! It appends an element _before_ the last element of `body`, as well as one at the end. Ok! This is pretty bad, because now this soundness presumption:

> to know what changes to map into real DOMspace, you can compare your old VDOM to your new VDOM

is **absolutely untrue.** If we follow the same update algorithm as before:

1. visit the DOM's `body` element,
2. find the second element of its child list (`<div id="goog-gt-tt">`),
3. find the third element of _that_ element's child list, and
4. !!! there is no third one. runtime error!

And so this new friend has caused the language without runtime errors to become a language with runtime errors.

Defensively, you could say "well Google Translate breaks React too", and depending on when you're reading this, that's true, but just cause it screws with someone else doesn't mean I like it screwing with _me._ I put my nodes where I wanted them and I'll be damned if I let someone move them around!

## What we did

Originally we discussed a few options:

1. "Block" Google Translate entirely. We ruled this out almost immediately; a lot of people use and like this tool, and we can't even block it confidently; we can slap a `notranslate` on the body, but the widget part of Google Translate is undocumented, and so we can't be sure we're protected. Maybe try to detect the runtime error and force a page refresh or something; not too satisfying!
2. Use something like [elm-break-dom](https://github.com/jinjor/elm-break-dom) to make Elm not work at the top-level of the DOM. This was a little sketchy to us. In principle it works, but breaking a core assumption of the Elm runtime may have other effects down the road that would be harder to understand. Plus, your build pipeline having a `sed` command in it is... a bit of a code smell.
3. Let Translate do its thing, but rebuild the world after the fact. It's not strictly a problem for the DOM to go out of order, only for it to _be_ out of order while the Elm runtime is looking at it!

We took path #3 by adding a MutationObserver. Elm-side, the change is trivial:

```elm
main : Program () Model Msg
main =
    Browser.application
        { view = \_ ->
            { title = "Welcome to Business"
            , body =
                [ div [ id "elm-root" ] -- new!
                    [ div [ id "main" ] []
                    , ul [ id "notifications"]
                        [ li [] [ text "You've got 3975 new followers!" ]
                        , li [] [ text "Your latest post was a big success." ]
                        , li [] [ text "Everyone's very proud of you." ]
                        ]
                    ]
                ] -- new!
            }
        -- yada yada yada
        }
```

We just moved all of our content into a single node. Now Google Translate makes our DOM look like this:

```html
<body>
  <div id="goog-gt-tt"><!-- some bullshit --></div>
  <div id="elm-root"><!-- our bullshit --></div>
  <div class="goog-gt-tt"><!-- some more bullshit --></div>
</body>
```

Less dramatic! And having our content in a single node simplifies the JS side of the fix:

```js
const observer = new MutationObserver(() => {
  const children = [...document.body.children];

  if (children[0] && children[0].id !== "elm-root") {
    const elmRoot = document.getElementById("elm-root");

    if (elmRoot) document.body.prepend(elmRoot);
  }
});

observer.observe(document.body, { childList: true });
```

To summarize, our MutationObserver watches the body element. If it ever changes, it checks whether Elm's assumptions about the real DOM (which, in our case, is now "#elm-root is at index 0 and everything is inside of it") have been invalidated, and then forces it to be true again.

Once that observer's fired, all is right with the DOM:

```html
<body>
  <div id="elm-root"><!-- our bullshit --></div>
  <div id="goog-gt-tt"><!-- some bullshit --></div>
  <div class="goog-gt-tt"><!-- some more bullshit --></div>
</body>
```

You could end up in a vicious cycle if your browser extension is _insistent_ on reordering the entire DOM on every animation frame, but at that point, are you even really trying to look at websites anymore?

This has proved out well for us; it's a good general solution to the problem, doesn't try to change compiler output, and hasn't needed a change since its first release. It supports Google Translate but also keeps the page healthy for any other extensions that are out here trying to have a little fun.

## What you could do instead

In the intervening time, Simon Lydell has come out with a very cool [alternate VDOM implementation](https://github.com/lydell/elm-safe-virtual-dom) that uses a **reference basis** for diffing. That means the VDOM tree is a collection of references to the DOM nodes Elm created, rather than a collection of indices for _finding_ them. So nodes are never "in the wrong place", because that notion of place is done away with entirely!

Though it's quite an extensive change, it's also more comprehensive. It doesn't require reorganizing "intruding" DOM nodes, and even in dramatic situations like random Elm-tracked nodes being _completely removed from the DOM,_ Elm will peacefully go on updating them. Now, updating an effectively deleted node isn't really all that useful, but the resulting soundness is. NoRedInk has a [great article](https://blog.noredink.com/post/800011916366020608/adopting-elm-safe-virtual-dom) on adopting this alternate VDOM implementation as well.

For now I expect we'll stick to what we have given its simplicity, but this is a great option since it requires _no_ changes to your "true source" code, despite the extensive changes to your build pipeline.

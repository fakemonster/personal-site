---
title: projects
---

# projects

My existing work is mostly split between [music](/projects#Music) and [programming](/projects#Software) (I don't usually relate them to each other). These days it's about 90% programming!

## Software

### brom

- [source](https://github.com/22bulbs/brom)

> brom is a configurable CLI for recording HTTP transactions and improving security practices, designed for use in local environments and CI tools. Get your headers in order before deployment.

Essentially brom has two major functions:

1. an inverted test suite, where one can write rules against an entire REST server, introspecting on headers for each response without a ton of repetitive unit testing.
1. a GUI for spying on a live (local) server, reverse-proxying all your requests to provide a little more detail than dev tools, plus comparing against your ruleset (mentioned above)

### Sand

- [play](https://our-beach.github.io/sand/)
- [source](https://github.com/our-beach/sand)

An interactive waveform using the Web Audio API and React. Click and drag to change the wave shape, further controls on the bottom. For an educational experience, try drawing a wave half as long twice, or changing the shape to triangles (zigzags) or squares.

### This site

- [source](https://github.com/fakemonster/elm-personal-site)

This site is built in Elm (hence the JS requirement). Elm is quite nice! Probably the biggest nuisances I encountered were:

1. it really is pure, so effects are managed exclusively by the runtime. This means you have to colocate all your state in one place, which gets a little hairy when you want to have an isolated state that you could (theoretically) duplicate
1. due to the lack of typeclasses, I had to put up a bit of a fight to get a sane page architecture going. If you were to do something like this web app in Haskell, probably your first bet would be for each page to `implement Page`, where here you instead define a `Page` type that's a union of each page's unique constructor. It was pretty ugly originally, but I came across Richard Feldman's [elm SPA example](https://github.com/rtfeldman/elm-spa-example) which proved to solve the problem more nicely.

All said, it's been excellent to work with. I get to have 100% confidence in every refactor, which I'd generally given up on in frontends! And algebraic types are particularly nice when making UI, where you have a lot of things that are _nearly_ identical.

### Stardew Valley Heelies Mod

- [download](https://www.nexusmods.com/stardewvalley/mods/7751)
- [source](https://github.com/fakemonster/stardew-valley-heelies)

Not exactly a crowning technical achievement, but was fun to do a bit of C#! SV is one of my all-time favorite games, so it felt great to contribute a little bit to the experience.

---

## Music

Feel free to reach out for a copy of a score to any of these works.

### Rondo for Strings and Pegs

A tuning piece for solo guitar. Very very peaceful, except it breaks all six strings. An excerpt below:

<youtube
src="https://www.youtube.com/embed/ev-eo7x5nf8"
name="Rondo for Strings and Pegs"
/>

### Poem Pieces

An ultra-EP of my ongoing project to turn poetry into music; this is my way of getting involved in an art form for which I have great love and inability.

<bandcamp
player="https://bandcamp.com/EmbeddedPlayer/album=4110281240/size=large/bgcol=ffffff/linkcol=0687f5/artwork=small/transparent=true/"
site="https://jthel.bandcamp.com/album/poem-pieces"
name="Poem Pieces"
/>

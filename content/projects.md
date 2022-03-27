---
title: projects
---

# projects

A little sampling of things I've done (or thought about) recently. My existing work is mostly split between [music](/projects#_Music) and [programming](/projects#_Software) (I don't usually relate them to each other). These days it's about 90% programming!

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

- [source](https://github.com/fakemonster/personal-site)

This site is built in Elm. Elm is great! Coming from React (and with a decent understanding of functional programming), probably the biggest hurdles I encountered were:

1. it really is pure, so effects are managed exclusively by the runtime. This means you have to colocate all your state in one place, which gets a little hairy when you want to have an isolated state that you could (theoretically) duplicate. To put that another way, Elm _discourages_ you from making things that look like components!
1. I had to put up a bit of a fight to get a sane page architecture going. There's only one view function, and everything is typed, so how do you view two different things?? What I came up with alone was heinous, but I reworked things after finding Richard Feldman's [elm SPA example](https://github.com/rtfeldman/elm-spa-example), and managed to solve the problem more nicely. Since then, I actually remade this site in [elm-pages](https://elm-pages.com/), so the whole "page" thing is just handled for me.

All said, it's been excellent to work with. I get to have 100% confidence in every refactor, which I've certainly never had in JavaScript (and often even TypeScript)!

Custom types (and immutability!) are particularly nice when making websites, where you have to shuttle around a bunch of things that are _nearly_ identical, and you have a lot of common ways that those things need to be "lifted" into some context (like "value may not exist", "value needs to be loaded over the network", "value will show up later", etc.).

### Stardew Valley Heelies Mod

- [download](https://www.nexusmods.com/stardewvalley/mods/7751)
- [source](https://github.com/fakemonster/stardew-valley-heelies)

> Sick heelies for the homie. Use this mod for a solid - but not game breaking - speed boost, and coast with the most.

Not exactly a crowning technical achievement, but was fun to do a bit of C#! SV is one of my all-time favorite games, so it felt great to contribute a little bit to the experience.


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

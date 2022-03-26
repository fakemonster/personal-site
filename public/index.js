/** @typedef {{load: (Promise<unknown>); flags: (unknown)}} ElmPagesInit */

import { pixelate } from './dots.js'

import "https://unpkg.com/elm-canvas@2.2.4/elm-canvas.js"

const oneOf = opts => opts[Math.floor(Math.random() * opts.length)]

/** @type ElmPagesInit */
export default {
  load: async function (elmLoaded) {
    const bigWidth =
      Math.floor(Math.min(window.innerWidth * 0.8, window.innerHeight * 1.4))
    const app = await elmLoaded
    app.ports.gatherConfig.subscribe(({
      id,
      cutoffPercentage,
      frameLength,
      resolutions,
      text,
      width,
    }) => {
      app.ports.configReady.send({
        ...pixelate({
          text,
          width: width || bigWidth,
          resolution: oneOf(resolutions),
        }),
        id,
        frameLength,
        cutoffPercentage,
      })
    })

    console.info("App loaded", app)
  },
  flags: function () {
    return "You can decode this in Shared.elm using Json.Decode.string!"
  },
}

/** @typedef {{load: (Promise<unknown>); flags: (unknown)}} ElmPagesInit */

import { pixelate } from './dots.js'

import "https://unpkg.com/elm-canvas@2.2.4/elm-canvas.js"

const oneOf = opts => opts[Math.floor(Math.random() * opts.length)]

/** @type ElmPagesInit */
export default {
  load: async function (elmLoaded) {
    const app = await elmLoaded
    console.log("App loaded", app)
  },
  flags: function () {
    return {
      dotConfig: {
        ...pixelate({
          text: 'joe thel',
          width: 150,
          resolution: oneOf([2, 3, 10, 20]),
        }),
        frameLength: 10,
        cutoffPercentage: 100,
      },
    }
  },
}

const range = (min, max, freq = 1) => {
  const output = []
  for (let i = min; i < max; i += freq) {
    output.push(i)
  }
  return output
}

const setFontSize = (scale, word, width, ctx) => {
  ctx.font = 'bold 1px Arial'
  const ratio = Math.floor((width * scale) / ctx.measureText(word).width)
  ctx.font = `bold ${ratio}px Arial`
}

const readBufAtCoords = (buf, width) => (x, y) => buf[y * width + x]

const getPoints = (ctx, freq) => {
  const { width, height } = ctx.canvas
  const buffer32 = new Uint32Array(ctx.getImageData(0, 0, width, height).data.buffer)
  const atCoords = readBufAtCoords(buffer32, width)
  return range(0, height, freq).reduce((points, y) => {
    range(0, width, freq).forEach(x => {
      if (atCoords(x, y)) points.push([x,y])
    })
    return points
  }, [])
}

export const pixelate = ({
  text,
  width,
  resolution = 3,
  scale = 0.9, // text proportion to canvas
}) => {
  const canvas = document.createElement('canvas')
  canvas.id = 'joe'
  const ctx = canvas.getContext('2d')

  ctx.textAlign = 'center'
  setFontSize(scale, text, width, ctx)
  const {
    actualBoundingBoxAscent: ascent,
    actualBoundingBoxDescent: descent,
  } = ctx.measureText(text)
  const height = Math.ceil((ascent + descent) / scale)
  if (Number.isNaN(height)) throw new Error('unable to calculate height')

  canvas.width = width
  canvas.height = height
  ctx.textAlign = 'center'
  ctx.textBaseline = 'middle'
  setFontSize(scale, text, width, ctx)

  ctx.fillText(text, width / 2, height / 2)

  const freq = Math.floor(Math.sqrt(width / resolution)) || 1
  const points = getPoints(ctx, freq)
  ctx.clearRect(0, 0, width, height)
  return { points, radius: freq / 2, width, height }
}

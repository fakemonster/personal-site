const express = require('express')
const elmServe = require('./elmServe')
const compress = require('./compress')
const httpsUpgrade = require('./httpsUpgrade')

process.env.PORT = process.env.PORT || '3000'
const app = express()

const info = console.info

if (process.env.DEPLOYED === 'true') {
  info('Running in deployment mode...')
  info(`-- ${httpsUpgrade.description}`)
  info(`-- ${compress.description}`)
  app.set('trust proxy', true)
  app
    .use(httpsUpgrade)
    .use(compress)
}

elmServe(app)
  .listen(process.env.PORT, () => info('lets do it'))

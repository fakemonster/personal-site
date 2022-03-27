const express = require('express')
const path = require('path')
const fs = require('fs')

const to = filepath => path.join(__dirname, filepath)
const sendFile = filepath => (req, res) => res.sendFile(filepath)

module.exports = app => {
  app.use(express.static(to('../dist')))
  app.get('*', sendFile(to('../dist/index.html')))

  return app
}

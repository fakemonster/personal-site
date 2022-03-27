module.exports = (req, res, next) => {
  if (!req.secure && req.headers['upgrade-insecure-requests'] === '1') {
    return res.redirect(301, `https://${req.headers.host}${req.url}`)
  }
  next()
}

module.exports.description = 'upgrade http to https when requested'

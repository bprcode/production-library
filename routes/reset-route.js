const express = require('express')
const {} = require('../database.js')
const router = express.Router()

const resetDatabase = function (req, res) {
  res.send('roger roger.')
}

router
  .post('/', resetDatabase)

module.exports = router
#!/usr/bin/env node
if (process.env.NODE_ENV !== 'production') {
    require('dotenv').config()
}
require('@bprcode/handy')
const express = require('express')
const app = express()

app
    .use('*', (req, res, next) => {
        log(req.method + ': ' + req.originalUrl, dim)
        next()
    })
    .get('/', (req, res) => {
        res.send('Welcome!')
    })

const server = app.listen(process.env.PORT || 2666, () => {
    log(moo() + ' Server active on: ', green, server.address())
})

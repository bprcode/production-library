#!/usr/bin/env node
if (process.env.NODE_ENV !== 'production') {
    require('dotenv').config()
}
const path = require('node:path')
require('@bprcode/handy')
const express = require('express')
const app = express()

const homeRouter = require('./routes/home.js')

app
    .use('/', homeRouter)
    .use(express.static(path.join(__dirname, 'public')))
    // Fallthrough handler: route not found
    .use((req, res, next) => {
        res.status(404)
        throw new Error('File not found.')
    })
    .use((err, req, res, next) => {
        res.send('An error occurred: ' + err.message)
    })

const server = app.listen(process.env.PORT || 2666, () => {
    log(moo() + ' Server active on: ', green, server.address())
})

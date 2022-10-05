#!/usr/bin/env node
if (process.env.NODE_ENV !== 'production') {
    require('dotenv').config()
}
const path = require('node:path')
require('@bprcode/handy')
const express = require('express')
const app = express()
const hbs = require('hbs')
hbs.registerPartials(path.join(__dirname, '/views/partials'))

const layoutExampleRouter = require('./routes/layout-examples.js')


app
    .use((req, res, next) => {
        log(req.method + ': ' + req.originalUrl, dim)
        next()
    })

    .use('/', layoutExampleRouter)

    .use(express.static(path.join(__dirname, 'public')))

    .use((req, res, next) => {
        res.status(404)
        throw new Error('File not found.')
    })

    .use((err, req, res, next) => {
        res.render('error.hbs', {
            title: 'Error encountered',
            status_code: res.statusCode,
            error_message: err.message
        })
    })

const server = app.listen(process.env.PORT || 2666, () => {
    log(moo() + ' Server active on: ', green, server.address())
})

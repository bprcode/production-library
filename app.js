#!/usr/bin/env node
const path = require('node:path')
if (process.env.NODE_ENV !== 'production') {
    require('dotenv').config({
        path: path.join(__dirname, '../shared/.env') })
}
require('@bprcode/handy')
const express = require('express')
const app = express()
const hbs = require('hbs')
hbs.registerPartials(path.join(__dirname, '/views/partials'))

const layoutExampleRouter = require('./routes/layout-examples.js')
const dbRouter = require('./routes/db-route.js')
const libRouter = require('./routes/library-route.js')

log.err('Next step: Convert downloaded data to SQL, test genres/book_genres table.')

app
    .use((req, res, next) => {
        log(req.method + ': ' + req.originalUrl, dim)
        next()
    })

    .use('/', layoutExampleRouter)
    .use('/db', dbRouter)
    .use('/lib', libRouter)

    .use(express.static(path.join(__dirname, 'public')))

    .use((req, res, next) => {
        res.status(404)
        throw new Error('File not found.')
    })

    .use((err, req, res, next) => {
        res.render('error.hbs', {
            title: 'Error Encountered',
            status_code: res.statusCode,
            error_message: err.message,
            error_stack: process.env.NODE_ENV !== 'production'
                            ? err.stack
                            : undefined
        })
    })

const server = app.listen(process.env.PORT || 2666, () => {
    log(moo() + ' Server active on: ', green, server.address())
})

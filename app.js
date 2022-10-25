#!/usr/bin/env node
const path = require('node:path')
if (process.env.NODE_ENV !== 'production') {
    require('dotenv').config({
        path: path.join(__dirname, '../shared/.env') })
}
require('@bprcode/handy')
const express = require('express')
const app = express()

// Initialize templating
const { DateTime } = require('luxon')
const hbs = require('hbs')
hbs.registerPartials(path.join(__dirname, '/views/partials'))
hbs.registerHelper('match', (a,b) => a === b)
hbs.registerHelper('pretty-date', date => {
    if ( !date ) { return '' }
    return DateTime.fromJSDate(date).toLocaleString(DateTime.DATE_MED)
})

// Helper to use position in iterable to insert a comma, or not:
hbs.registerHelper('comma-list', (...stuff) => {
    if ( !stuff[stuff.length-1].data.last )
        return `, `
    else
        return ``})

// Load routers
const layoutExampleRouter = require('./routes/layout-examples.js')
const dbRouter = require('./routes/db-route.js')
const libRouter = require('./routes/library-route.js')
const catalogRouter = require('./routes/catalog-route.js')

app
    .disable('x-powered-by')
    .use((req, res, next) => {
        log(req.method + ': ' + req.originalUrl, dim)
        next()
    })

    .use('/', layoutExampleRouter)
    .get('/', (req, res) => { res.redirect('/catalog') })
    .use('/catalog', catalogRouter)
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
    log('Todo: Fix nav bar spacing (slightly different between pages?)')
    log('Adding author bios and styling more like book detail page would look nicer, but would take more data')
})

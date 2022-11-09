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
hbs.registerHelper('match-string', (a,b) => String(a) === String(b))
hbs.registerHelper('find-in', (arr, key, value) => {
    return arr?.find(e => e[key] === value)
})
hbs.registerHelper('pretty-date', date => {
    if ( !date ) { return '' }
    if (date instanceof Date) {
        return DateTime.fromJSDate(date).toLocaleString(DateTime.DATE_MED)
    }
    return DateTime.fromISO(date).toLocaleString(DateTime.DATE_MED)
})

// Helper to use position in iterable to insert a comma, or not:
hbs.registerHelper('comma-list', (...stuff) => {
    if ( !stuff[stuff.length-1].data.last )
        return `, `
    else
        return ``
})

// Obtain an error status message, or undefined if not set:
hbs.registerHelper('error-check', (trouble, name) => {
    if (trouble)
        return trouble.find(t => t.param === name)?.msg
    return undefined
})

// Load routers
const layoutExampleRouter = require('./routes/layout-examples.js')
const dbRouter = require('./routes/db-route.js')
const libRouter = require('./routes/library-route.js')
const catalogRouter = require('./routes/catalog-route.js')

app
    .disable('x-powered-by')

    .use(express.urlencoded({ extended: true }))

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
    log('Would be nice: encapsulate book creation with its genres as a transaction.')
    log('There is a 2px doubled border on book_detail availability. Low-priority but debug.')
})

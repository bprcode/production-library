const router = require('express').Router()
const fsp = require('node:fs/promises')
const { query, library } = require('../database.js')
require('express-async-errors')

router
    .get('/', async (req, res) => {
        const result = await library.allBooks()
        res.render('lean_status.hbs',
            { result, mod_title: 'Library Query Result' })
    })
    .get('/foo/:val?', async (req, res) => {
        log('query: ', req.query)
        res.render('lean_status.hbs',
            { mod_title: 'Foo route ' + (req.params.val !== undefined
                ? 'with: ' + req.params.val
                : 'without parameter.') })
    })
    .get('/hbcheck', async (req, res) => {
        res.json({
            name: 'Bob', face: '😀',
            age: 42, cats: ['Whiskers', 'Fluffy', 'Spot']
        })
    })
    // Proof-of-concept loading of data from Mongo js file
    .post('/autoload', async (req, res) => {
        log('AUTOLOAD POST REQUEST RECEIVED', yellow)

        const file = await fsp.readFile('populatedb.js.txt')
        let extract = String(file).matchAll(
            /(?<!function )authorCreate\((.*)\).*$/gm)

        for (const e of [...extract]) {
            log.rainbow(e[1])
            await library.createAuthor(...e[1].split(', '))
        }
        res.render('lean_status.hbs', {
            pre: file, mod_title: 'Proof-of-concept'
        })
    })

module.exports = router

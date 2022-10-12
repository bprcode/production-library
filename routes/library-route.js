const router = require('express').Router()
const fsp = require('node:fs/promises')
const { query, library } = require('../database.js')
require('express-async-errors')

router
    .get('/', async (req, res) => {
        const result = await library.allBooks()
        res.render('lean_status.hbs', {
            result, mod_title: 'Library Query Result' })
    })
    .get('/concept', async (req, res) => {
        const file = await fsp.readFile('populatedb.js.txt')
        res.render('lean_status.hbs', {
            pre: file, mod_title: 'Proof-of-concept'
        })
    })

module.exports = router

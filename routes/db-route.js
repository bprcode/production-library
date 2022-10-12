const express = require('express')
require('express-async-errors')
const { query, members, getStatus } = require('../database.js')

const router = express.Router()

router
    .get('/user/:idx', async (req, res) => {
        const result = await members.find(req.params.idx)
        res.render( 'lean_status.hbs',
            { result, mod_title: 'User Record' })
    })
    .get('/foo', async(req, res) => {
        const result = await query(
            'SELECT * FROM lib.foo')
        res.render('lean_status.hbs',
            { result, mod_title: 'Foo.' })
    })
    .get('/status', async (req, res) => {
        const result = await getStatus()
        res.render('lean_status.hbs',
            { result, mod_title: 'DB Connection Status' })
    })
    .get('/cat', (req, res) => {
        res.send('db->cat')
    })

module.exports = router

const express = require('express')
require('express-async-errors')
const { Pool } = require('pg')
require('@bprcode/handy')

const router = express.Router()
const pool = new Pool()

router
    .get('/user/:idx', async (req, res) => {
        const result = await pool.query(
            'SELECT * FROM cd.members WHERE memid = $1',
            [parseInt(req.params.idx)])
        if (result.rows[0])
            res.send(result.rows[0])
        else
            throw new Error('Could not find record.')
    })
    .get('/status', async (req, res) => {
        const result = await pool.query(
            'SELECT * FROM get_status()')
        res.render('lean_status.hbs', { result })
    })
    .get('/cat', (req, res) => {
        res.send('db->cat')
    })

module.exports = router

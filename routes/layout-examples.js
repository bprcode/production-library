const express = require('express')
const router = express.Router()
require('@bprcode/handy')

router
    .get('/', (req, res, next) => {
        res.render('home.hbs', {
            title: 'Handlebars Layout Examples',
            page: 'Sample Rendered Output'
            })
    })
    .get('/lean', (req, res, next) => {
        res.render('lean_home.hbs')
    })
    .get('/moo/:count', (req, res, next) => {
        log(`Rendering...`, green)
        res.render('moo.hbs', {
            partial_header: 'head',
                 top_face: '🐲',
            partial_footer: 'foot',
            partial_name: Math.random() < 0.5 ? 'foo' : 'bar',
            title: 'Layout from Dynamic Lookup',
            animals: Array.from({ length: req.params.count }, _ => moo()),
            baz: req.query.baz || 111.222
        })
    })

module.exports = router

const express = require('express')
const router = express.Router()
require('@bprcode/handy')

router
    .get('/', (req, res, next) => {
        res.render('home.hbs', {
            title: 'Welcome to the Home Page',
            page: 'Sample Rendered Output'
            })
    })
    .get('/moo/:count', (req, res, next) => {
        log(`Rendering...`, green)
        res.render('moo.hbs', {
            partial_header: 'head',
                 top_face: '🐲',
            partial_footer: 'foot',
            partial_name: Math.random() < 0.5 ? 'foo' : 'bar',
            title: req.query.top || 'Quack Quack',
            animals: Array.from({ length: req.params.count }, _ => moo()),
            baz: req.query.baz || 111.222
        })
    })

module.exports = router

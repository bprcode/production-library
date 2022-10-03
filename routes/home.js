const express = require('express')
const router = express.Router()

router
    .get('/', (req, res, next) => {
        res.render('home.hbs',
            {   title: 'Welcome to the Home Page',
                page: 'Sample Rendered Output'
            })
    })

module.exports = router

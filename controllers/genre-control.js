require('express-async-errors')
const { genres, booksByGenre } = require('../database.js')
const { body, validationResult } = require('express-validator')

async function alreadyHaveGenre (name) {
    if (await genres.find({ name: name }))
        throw new Error(`Genre already created`)
}

const genreValidators = [
    body('name')
        .trim()
        .isLength({ min: 1 }).withMessage('Name required')
        .isString().withMessage('Name must be a string')
        .custom(alreadyHaveGenre).withMessage('Genre already in catalog')
        .escape(),
]

exports.genre_list = async (req, res) => {
    const result = await genres.find()
    res.render(`genre_list.hbs`, { genres: result })
}
exports.genre_detail = async (req, res) => {
    const [resultGenre, resultBooks] = await Promise.all([
        genres.find({ genre_id: req.params.id }),
        booksByGenre.find({ genre_id: req.params.id })
    ])

    if ( !resultGenre )
        return res.render(`no_results.hbs`, {
            title: 'Genre not found.',
            text: ' '
        })

    let title = resultGenre[0].name + ` titles`
    if( !resultBooks )
        return res.render(`no_results.hbs`, {
            title: title,
            text: 'None in catalog.'
        })

    res.render(`genre_detail.hbs`, {
        title: title,
        result: resultBooks
    })
}
exports.genre_create_get = (req, res) => {
    res.render(`genre_form.hbs`)
}
exports.genre_create_post = [
    ...genreValidators,
    async (req, res) => {
        let result
        const trouble = validationResult(req)

        if ( !trouble.isEmpty() ) {
            return res.status(400).render(`genre_form.hbs`, {
                trouble: trouble.array()
            })
        }
        try {
            result = await genres.insert({ name: req.body.name })
        } catch (e) {
            log.err(e.message)
            throw e
        }

        res.redirect(result[0].genre_url)
    }
]
exports.genre_update_get = (req, res) => {
    res.send(`<❕ placeholder>: Genre update (GET)`)
}
exports.genre_update_post = (req, res) => {
    res.send(`<❕ placeholder>: Genre update (POST)`)
}
exports.genre_delete_get = (req, res) => {
    res.send(`<❕ placeholder>: Genre delete (GET)`)
}
exports.genre_delete_post = (req, res) => {
    res.send(`<❕ placeholder>: Genre delete (POST)`)
}

require('express-async-errors')
const { body, validationResult } = require('express-validator')
const { authors, books } = require('../database.js')

async function alreadyHaveAuthor (lname, { req }) {
    if (await authors.find({
            first_name: req.body.first_name, last_name: lname
        }))
        throw new Error(`Author already created`)
}

const authorValidators = [
    body('first_name')
        .trim()
        .isLength({ min: 1 })
        .withMessage('First name required')
        .escape(),
    body('last_name')
        .trim()
        .isLength({ min: 1})
        .escape()
        .withMessage('Last name required')
        .custom(alreadyHaveAuthor)
        .withMessage('Author already in catalog.'),
    body('dob', 'Invalid date')
        .optional({ checkFalsy: true })
        .isISO8601()
        .toDate(),
    body('dod', 'Invalid date')
        .optional({ checkFalsy: true })
        .isISO8601()
        .toDate()
]

exports.author_list = async (req, res) => {
    const result = await authors.find()
    res.render(`author_list.hbs`, { authors: result })
}
exports.author_detail = async (req, res) => {
    const [resultAuthors, resultBooks] = await Promise.all([
        authors.find({ author_id: req.params.id }),
        books.find({ author_id: req.params.id })
    ])
    if ( !resultAuthors ) {
        return res.render(`no_results.hbs`)
    }

    log('resultAuthors', blue)
    log(resultAuthors)
    log('resultBooks', blue)
    log(resultBooks)

    res.render(`author_detail.hbs`, {
        author: resultAuthors[0],
        books: resultBooks
    })
}
exports.author_create_get = (req, res) => {
    res.render(`author_form.hbs`)
}
exports.author_create_post = [
    ...authorValidators,
    async (req, res) => {
        let result
        const trouble = validationResult(req)

        if ( !trouble.isEmpty() ) {
            return res.status(400).render(`author_form.hbs`, {
                trouble: trouble.array()
            })
        }

        try {
            result = await authors.insert({
                first_name: req.body.first_name,
                last_name: req.body.last_name,
                dob: req.body.dob || null,
                dod: req.body.dod || null
            })
        } catch (e) {
            log.err(e.message)
            throw e
        }

        res.redirect(result[0].author_url)
    }
]
exports.author_delete_get = (req, res) => {
    res.send(`<❕ placeholder>: Author delete (GET)`)
}
exports.author_delete_post = (req, res) => {
    res.send(`<❕ placeholder>: Author delete (POST)`)
}
exports.author_update_get = (req, res) => {
    res.send(`<❕ placeholder>: Author update (GET)`)
}
exports.author_update_post = (req, res) => {
    res.send(`<❕ placeholder>: Author update (POST)`)
}

require('express-async-errors')
const { body, param, validationResult } = require('express-validator')
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

const authorDeleteValidator =
    param('id')
        .escape()
        .custom(async id => {
            if ( !(await authors.find({ author_id: id })) )
                throw new Error(`Invalid author ID.`)
        })
        .withMessage('Author ID not found.')

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

    res.render(`author_detail.hbs`, {
        author: resultAuthors[0],
        books: resultBooks
    })
}
exports.author_create_get = (req, res) => {
    res.render(`author_form.hbs`,
        { title: 'Add Author', form_action: '/catalog/author/create' })
}
exports.author_create_post = [
    ...authorValidators,
    async (req, res) => {
        let result
        const trouble = validationResult(req)

        if ( !trouble.isEmpty() ) {
            return res.status(400).render(`author_form.hbs`, {
                trouble: trouble.array(),
                title: 'Add Author',
                form_action: '/catalog/author/create'
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
exports.author_update_choose = async (req, res) => {
    const result = await authors.find()
    res.render(`author_action_choose.hbs`,
        { authors: result, action: 'update' })
}
exports.author_delete_choose = async (req, res) => {
    const result = await authors.find()
    res.render(`author_action_choose.hbs`,
        { authors: result, action: 'delete' })
}
exports.author_delete_get = [
    authorDeleteValidator,
    async (req, res) => {
        const trouble = validationResult(req)
        if ( !trouble.isEmpty() ) {
            return res.redirect(`/catalog/author/delete`)
        }

        const [resultAuthor, resultBooks] = await Promise.all([
            authors.find({ author_id: req.params.id }),
            books.find({ author_id: req.params.id })
        ])
        res.render(`author_delete.hbs`, {
            author: resultAuthor[0],
            books: resultBooks
        })
    }
]
exports.author_delete_post = [
    authorDeleteValidator,
    (req, res) => {
        authors.delete({ author_id: req.params.id })
        res.redirect(`/catalog/authors`)
    }
]
exports.author_update_get = (req, res) => {
    res.send(`<❕ placeholder>: Author update (GET)`)
}
exports.author_update_post = (req, res) => {
    res.send(`<❕ placeholder>: Author update (POST)`)
}

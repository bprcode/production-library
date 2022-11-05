require('express-async-errors')
const { body, param, validationResult } = require('express-validator')
const { authors, books, snipTimes } = require('../database.js')

const authorNameValidator =
    body('last_name')
        .custom(async (lname, { req }) => {
            if (await authors.find({
                    first_name: req.body.first_name, last_name: lname
                }))
                throw new Error(`Author already created`)
        })
        .withMessage('Author already in catalog.')

const preventNameCollision =
    body('last_name')
        .custom(async (lname, { req }) => {
            const [result] = await authors.find({
                first_name: req.body.first_name, last_name: lname
            })
            if (result && String(result.author_id) !== String(req.params.id)) {
                throw new Error(`Author name in use.`)
            }
        })
        .withMessage('Name already in use.')

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
        .withMessage('Last name required'),
    body('dob', 'Invalid date')
        .optional({ checkFalsy: true })
        .isISO8601(),
    body('dod', 'Invalid date')
        .optional({ checkFalsy: true })
        .isISO8601()
]

const authorIdValidator =
    param('id')
        .escape()
        .custom(async id => {
            if ( ! await authors.find({ author_id: id }) )
                throw new Error(`Invalid author ID.`)
        })
        .withMessage('Author ID not found.')

exports.author_list = async (req, res) => {
    const result = await snipTimes(authors.find())
    res.render(`author_list.hbs`, { authors: result })
}
exports.author_detail = async (req, res) => {
    const [resultAuthors, resultBooks] = await Promise.all([
        snipTimes(authors.find({ author_id: req.params.id })),
        books.find({ author_id: req.params.id })
    ])
    if ( ! resultAuthors ) {
        return res.render(`no_results.hbs`)
    }

    res.render(`author_detail.hbs`, {
        author: resultAuthors[0],
        books: resultBooks
    })
}
exports.author_create_get = (req, res) => {
    res.render(`author_form.hbs`, {
        title: 'Add Author',
        form_action: '/catalog/author/create',
        submit: 'Create'
    })
}
exports.author_create_post = [
    ...authorValidators,
    authorNameValidator,
    async (req, res) => {
        let result
        const trouble = validationResult(req)

        if ( !trouble.isEmpty() ) {
            return res.status(400).render(`author_form.hbs`, {
                author: {
                    first_name: req.body.first_name,
                    last_name: req.body.last_name,
                    dob: req.body.dob,
                    dod: req.body.dod,
                },
                trouble: trouble.array(),
                title: 'Add Author',
                form_action: '/catalog/author/create',
                submit: 'Create'
            })
        }

        try {
            [result] = await authors.insert({
                first_name: req.body.first_name,
                last_name: req.body.last_name,
                dob: req.body.dob || null,
                dod: req.body.dod || null
            })
        } catch (e) {
            log.err(e.message)
            throw e
        }

        res.redirect(result.author_url)
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
    authorIdValidator,
    async (req, res) => {
        const trouble = validationResult(req)
        if ( ! trouble.isEmpty() ) {
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
    authorIdValidator,
    (req, res) => {
        authors.delete({ author_id: req.params.id })
        res.redirect(`/catalog/authors`)
    }
]
exports.author_update_get = [
    authorIdValidator,
    async (req, res) => {
        const trouble = validationResult(req)
        if( ! trouble.isEmpty() ) {
            return res.redirect(`/catalog/author/update`)
        }

        const [author] =
            await snipTimes(authors.find({ author_id: req.params.id }))

        res.render(`author_form.hbs`, {
            author,
            title: 'Edit Author',
            form_action: undefined,
            submit: 'Save Changes'
        })
    }
]
exports.author_update_post = [
    authorIdValidator,
    ...authorValidators,
    preventNameCollision,
    async (req, res) => {
        const author = {
            first_name: req.body.first_name,
            last_name: req.body.last_name,
            dob: req.body.dob || null,
            dod: req.body.dod || null
        }

        const trouble = validationResult(req)
        if (!trouble.isEmpty()) {
            if (trouble.array().find(e => e.param === 'id')) {
                return res.redirect(`/catalog/author/update`)
            }

            return res.status(400).render(`author_form.hbs`, {
                author,
                trouble: trouble.array(),
                title: 'Edit Author',
                form_action: undefined,
                submit: 'Save Changes'
            })
        }

        const [result] = await authors.update(
            author, { author_id: req.params.id }
        )

        res.redirect(result.author_url)
    }
]

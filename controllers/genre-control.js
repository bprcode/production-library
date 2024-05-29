require('express-async-errors')
const { genres, booksByGenre, justBooks, bookGenres }
    = require('../database.js')
const { body, param, validationResult }
    = require('express-validator')
const { paginate, sanitizePagination } = require('./paginator.js')

async function alreadyHaveGenre (name) {
    if (await genres.find({ name: name }))
        throw new Error(`Genre already created`)
}

const genreIdValidator =
    param('id')
        .custom(async id => {
            if (!await genres.find({ genre_id: id }) )
                throw new Error(`Invalid genre ID.`)
        })
        .withMessage('Genre ID not found.')

const genreCreateValidators = [
    body('name')
        .trim()
        .isLength({ min: 1 }).withMessage('Name required')
        .isString().withMessage('Name must be a string')
        .custom(alreadyHaveGenre).withMessage('Genre already in catalog'),
]

const genreUpdateValidators = [
    genreIdValidator,
    body('name')
        .trim()
        .isLength({ min: 1 }).withMessage('Name required')
        .isString().withMessage('Name must be a string')
        .custom(async (value, { req }) => {
            const result = await genres.find({ name: value })
            if (result && result.find(r =>
                    String(r.genre_id) !== String(req.params.id))) {
                throw new Error(`Genre name unavailable.`)
            }
        })
        .withMessage('Genre name already in use.')
]

exports.genre_list = [
    ...sanitizePagination,
    async (req, res) => {
        const limit = req.query.limit || 10
        const [genreList, total] = await Promise.all([

            genres.find({
                _page: req.query.page,
                _limit: limit
            }),

            genres.count()

        ])

        const position = paginate(req.query.page, limit, total)

        res.render(`genre_list.hbs`, {
            genres: genreList,
            noResults: !genreList,
            ...position
        })
    }
]
exports.genre_detail = async (req, res) => {
    const [resultGenre, resultBooks, genreCount] = await Promise.all([
        genres.find({ genre_id: req.params.id }),
        booksByGenre.find({ genre_id: req.params.id }),
        booksByGenre.count({ genre_id: req.params.id })
    ])

    if ( !resultGenre )
        return res.render(`no_results.hbs`, {
            title: 'Genre not found.',
            text: ' '
        })

    let title = resultGenre[0].name

    res.render(`genre_detail.hbs`, {
        title: title,
        genre_url: resultGenre[0].genre_url,
        result: resultBooks,
        genreCount: genreCount
    })
}
exports.genre_create_get = (req, res) => {
    res.render(`genre_form.hbs`, {
        title: 'Add Genre',
        form_action: '/catalog/genre/create',
        submit: 'Create'
    })
}
exports.genre_create_post = [
    ...genreCreateValidators,
    async (req, res) => {
        let result
        const trouble = validationResult(req)

        if ( ! trouble.isEmpty() ) {
            return res.status(400).render(`genre_form.hbs`, {
                trouble: trouble.array(),
                title: 'Add Genre',
                form_action: '/catalog/genre/create',
                submit: 'Create',
                populate: { name: req.body.name }
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
exports.genre_update_get = [
    genreIdValidator,
    async (req, res) => {
        // Check for valid genre ID
        const trouble = validationResult(req)
        if ( ! trouble.isEmpty() ) {
            return res.redirect(`/catalog/genre/update`)
        }

        // Retrieve prior record
        const prior = await genres.find({ genre_id: req.params.id })

        // Render populated update form
        res.render(`genre_form.hbs`, {
            title: 'Edit Genre',
            form_action: undefined, // post to current URL
            populate: prior[0],
            submit: 'Save Changes'
        })
    }
]
exports.genre_update_post = [
    ...genreUpdateValidators,
    async (req, res) => {
        // Check for valid genre ID
        const trouble = validationResult(req)
        if ( ! trouble.isEmpty() ) {
            // Redirect invalid ID update requests
            if (trouble.array().find(e => e.param === 'id')) {
                return res.redirect(`/catalog/genre/update`)
            }

            // Re-render the form for invalid submitted data
            return res.status(400).render(`genre_form.hbs`, {
                trouble: trouble.array(),
                title: 'Edit Genre',
                form_action: undefined,
                submit: 'Save Changes',
                populate: { name: req.body.name }
            })
        }

        const result = await genres.update(
            { name: req.body.name },
            { genre_id: req.params.id }
        )

        res.redirect(result[0].genre_url)
    }
]
exports.genre_update_choose = async (req, res) => {
    const result = await genres.find()
    res.render(`genre_action_choose.hbs`, { genres: result, action: 'update' })
}
exports.genre_delete_choose = async (req, res) => {
    const result = await genres.find()
    res.render(`genre_action_choose.hbs`, { genres: result, action: 'delete' })
}
exports.genre_delete_get = [
    genreIdValidator,
    async (req, res) => {
        const trouble = validationResult(req)
        if ( !trouble.isEmpty() ) {
            return res.redirect(`/catalog/genre/delete`)
        }

        const result = await genres.find({ genre_id: req.params.id })
        res.render(`genre_delete.hbs`, { genre: result[0] })
    }
]
exports.genre_delete_post = [
    genreIdValidator,
    async (req, res) => {
        const trouble = validationResult(req)
        if ( !trouble.isEmpty() ) {
            return res.redirect(`/catalog/genre/delete`)
        }

        genres.delete({ genre_id: req.params.id })
        res.redirect(`/catalog/genres`)
    }
]
exports.genre_json_post = [
    ...genreCreateValidators,
    async (req, res) => {
        const trouble = validationResult(req)

        if (!trouble.isEmpty()) {
            return res.status(400).send({ trouble: trouble.array() })
        }
        try {
            const result = await genres.insert({ name: req.body.name })
            res.status(201).send(result[0])

        } catch (e) {
            log.err(e.message)
            throw e
        }
    }
]
exports.associate_json_post = [
    body('genre_id')
        .custom(async id => {
            if (!await genres.find({ genre_id: id }) )
                throw new Error(`Invalid genre ID.`)
        })
        .withMessage('Genre ID not found.'),
    body('book_id')
        .custom(async id => {
            if (!await justBooks.find({ book_id: id }) )
                throw new Error(`Invalid book ID.`)
        })
        .withMessage('Book ID not found.'),
    async (req, res) => {
        const trouble = validationResult(req)

        if (!trouble.isEmpty()) {
            return res.status(400).send({ trouble: trouble.array() })
        }
        try {
            const result = await bookGenres.insert({
                book_id: req.body.book_id,
                genre_id: req.body.genre_id
            })
            if (result)
                res.status(201).send(result[0])

        } catch (e) {
            log.err(e.message)
            throw e
        }

    }
]
exports.genre_json_get = async (req, res) => {
    const result = await genres.find()
    res.send( result || [] )
}

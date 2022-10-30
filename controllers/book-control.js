require('express-async-errors')
const { body, validationResult } = require('express-validator')
const { books, justBooks, authors, genres, bookInstances, genresByBook,
        bookGenres }
        = require('../database.js')

const bookValidators = [
    body('title')
        .trim()
        .isLength({ min: 1 })
        .withMessage('Title required')
        .escape(),
    body('author_id', 'Unable to match author.')
        .isLength({ min: 1 })
        .withMessage('No author indicated.')
        .bail()
        .custom(async value => {
            if( !(await authors.find({ author_id: value })).rows.length )
                throw new Error('Invalid author.')
        }),
    body('isbn', 'ISBN required')
        .trim()
        .isLength({ min: 1 })
        .escape(),
    body('summary')
        .optional({ checkFalsy: true }),
    body()
        .custom(async (value, { req }) => {
            // Extract IDs from genre checkbox fields
            let genreList = Object.keys(req.body)
                            .filter(k => k.startsWith('genre'))
                            .map(x => x.match( /genre-(\d+)/ )[1])
            const result = await Promise.all(
                genreList.map(g => genres.find({ genre_id: g }))
            )
            for(const r of result) {
                if ( !r.rows.length ) {
                    throw new Error('Invalid genre ID')
                }
            }
            // Store the parsed genre list.
            req.body.genreList = genreList
        })
        .withMessage('Invalid genre.')
]

exports.index = async (req, res) => {
    const result = await Promise.all([
        books.count(),
        authors.count(),
        genres.count(),
        bookInstances.count(),
        bookInstances.count({ status: 'Available' }),
    ])

    res.render('catalog-home.hbs', {
        title: 'Welcome to the catalog',
        book_count: result[0],
        author_count: result[1],
        genre_count: result[2],
        available_count: result[4],
        total_count: result[3],
    })
}
exports.book_list = async (req, res) => {
    const result = await books.find()
    res.render('book_list.hbs', result)
}
exports.book_detail = async (req, res) => {
    const result = await Promise.all([
        books.find({ book_id: req.params.id }),
        bookInstances.find({ book_id: req.params.id }),
        genresByBook.find({ book_id: req.params.id })
    ])

    if ( !result[0].rows[0] ) {
        return res.render(`no_results.hbs`)
    }

    res.render(`book_detail.hbs`, {
        book_info: result[0].rows[0],
        instances: result[1].rows,
        genre_info: result[2].rows
    })
}
exports.book_create_get = async (req, res) => {
    const result = await Promise.all([
        genres.find(),
        authors.find()
    ])

    res.render(`book_form.hbs`, {
        genres: result[0].rows,
        authors: result[1].rows
    })
}
exports.book_create_post = [
    ...bookValidators,
    async (req, res) => {
        const necessaryLabels = await Promise.all([
            genres.find(),
            authors.find()
        ])

        const trouble = validationResult(req)
        if ( !trouble.isEmpty() ) {
            return res.status(400).render(`book_form.hbs`, {
                trouble: trouble.array(),
                genres: necessaryLabels[0].rows,
                authors: necessaryLabels[1].rows
            })
        }

        // Having passed validation, create the new book.
        const result = await justBooks.insert({
            title: req.body.title,
            isbn: req.body.isbn,
            author_id: req.body.author_id,
            summary: req.body.summary || null
        })

        // Also need to insert on genre/book junction table
        const bookID = result.rows[0].book_id
        for (const genreID of req.body.genreList) {
            try {
                await bookGenres.insert({
                    book_id: bookID,
                    genre_id: genreID
                })
            } catch (e) {
                log.err(e.message)
                throw e
            }
        }

        res.redirect(result.rows[0].book_url)
    }
]
exports.book_update_get = (req, res) => {
    res.send(`<❕ placeholder>: Book update (GET)`)
}
exports.book_update_post = (req, res) => {
    res.send(`<❕ placeholder>: Book update (POST)`)
}
exports.book_delete_get = (req, res) => {
    res.send(`<❕ placeholder>: Book delete (GET)`)
}
exports.book_delete_post = (req, res) => {
    res.send(`<❕ placeholder>: Book delete (POST)`)
}

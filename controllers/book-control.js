require('express-async-errors')
const { body, param, query, validationResult } = require('express-validator')
const { books, justBooks, authors, genres, bookInstances, genresByBook,
        bookGenres }
        = require('../database.js')
const { paginate, sanitizePagination } = require('./paginator.js')

const preventTitleCollision =
    body('title')
        .trim()
        .custom(async value => {
            const priorEntry = await books.find({ title: value })
            if (priorEntry) {
                throw new Error(`Book already recorded: #`
                    + priorEntry[0].book_id)
            }
        })

const onlySelfTitleCollision =
    body('title', 'Title already in catalog')
        .trim()
        .custom(async (value, { req }) => {
            const result = await books.find({ title: value })
            if (result
                && String(req.params.id) !== String(result[0].book_id)) {
                throw new Error('Title already in catalog.')
            }
        })

const bookValidators = [
    body('title')
        .trim()
        .isLength({ min: 1 })
        .withMessage('Title required'),
    body('author_id', 'Unable to match author.')
        .isLength({ min: 1 })
        .withMessage('No author indicated.')
        .bail()
        .custom(async value => {
            if ( !(await authors.find({ author_id: value })) )
                throw new Error('Invalid author.')
        }),
    body('isbn')
        .trim(),
    body('summary')
        .optional({ checkFalsy: true }),
    body()
        .custom(async (_, { req }) => {
            // Extract IDs from genre checkbox fields
            let genreList = Object.keys(req.body)
                            .filter(k => k.startsWith('genre'))
                            .map(x => x.match( /genre-(\d+)/ )[1])
            const result = await Promise.all(
                genreList.map(g => genres.find({ genre_id: g }))
            )
            for (const r of result) {
                if ( !r ) {
                    throw new Error('Invalid genre ID')
                }
            }
            // Store the parsed genre list.
            req.body.genreList = genreList
        })
        .withMessage('Invalid genre.')
]

const bookIdValidator =
    param('id', 'Invalid book ID.')
        .trim()
        .custom(async value => {
            if (!await books.find({ book_id: value }))
                throw new Error(`Book ID not found.`)
        })

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
exports.book_list = [
    ...sanitizePagination,
    async (req, res) => {
        const limit = req.query.limit || 10
        const [bookList, total] = await Promise.all([

            books.find(
                'book_url', 'title', 'snippet', 'author_url', 'full_name', {
                _page: req.query.page,
                _limit: limit
            }),

            justBooks.count()
        ])

        const position = paginate(req.query.page, limit, total)

        res.render('book_list.hbs', {
            books: bookList,
            noResults: !bookList,
            ...position
        })
    }
]
exports.book_detail = async (req, res) => {
    const [resultBook, resultInstances, resultGenres] = await Promise.all([
        books.find({ book_id: req.params.id }),
        bookInstances.find({ book_id: req.params.id }),
        genresByBook.find({ book_id: req.params.id })
    ])

    if ( !resultBook ) {
        return res.render(`no_results.hbs`)
    }

    res.render(`book_detail.hbs`, {
        book_info: resultBook[0],
        instances: resultInstances,
        genre_info: resultGenres
    })
}
exports.book_create_get = async (req, res) => {
    const [genreLabels, authorLabels] = await Promise.all([
        genres.find(),
        authors.find()
    ])

    res.render(`book_form.hbs`, {
        genres: genreLabels,
        authors: authorLabels,
        title: 'Add Book',
        form_action: '/catalog/book/create',
        submit: 'Create'
    })
}
exports.book_create_post = [
    preventTitleCollision,
    ...bookValidators,
    async (req, res) => {
        const [genreLabels, authorLabels] = await Promise.all([
            genres.find(),
            authors.find()
        ])

        const item = {
            title: req.body.title,
            isbn: req.body.isbn || null,
            author_id: req.body.author_id,
            summary: req.body.summary || null
        }

        const trouble = validationResult(req)
        if ( !trouble.isEmpty() ) {
            return res.status(400).render(`book_form.hbs`, {
                trouble: trouble.array(),
                genres: genreLabels,
                authors: authorLabels,
                title: 'Add Book',
                form_action: '/catalog/book/create',
                submit: 'Create',
                populate: item,
                genreChecks: req.body.genreList
                            ?.map(g => { return { genre_id: parseInt(g) } })
            })
        }

        // Having passed validation, create the new book.
        const result = await justBooks.insert(item)

        // Also need to repeatedly insert on genre/book junction table
        const bookID = result[0].book_id
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

        res.redirect(result[0].book_url)
    }
]
exports.book_update_get = [
    bookIdValidator,
    async (req, res) => {
        const trouble = validationResult(req)
        if ( ! trouble.isEmpty() ) {
            return res.redirect(`/catalog/book/update`)
        }

        const [[previous], genreList, authorList, genreChecks] =
        await Promise.all([
            books.find({ book_id: req.params.id }),
            genres.find(),
            authors.find(),
            genresByBook.find({ book_id: req.params.id })
        ])

        res.render(`book_form.hbs`, {
            genres: genreList,
            authors: authorList,
            title: 'Edit Book',
            form_action: undefined,
            submit: 'Save Changes',
            populate: previous,
            genreChecks: genreChecks
        })
    }
]
exports.book_update_post = [
    bookIdValidator,
    ...bookValidators,
    onlySelfTitleCollision,
    async (req, res) => {
        const [genreLabels, authorLabels] = await Promise.all([
            genres.find(),
            authors.find()
        ])

        const item = {
            title: req.body.title,
            isbn: req.body.isbn || null,
            author_id: req.body.author_id,
            summary: req.body.summary || null
        }

        const trouble = validationResult(req)
        if (!trouble.isEmpty()) {
            if (trouble.array().find(e => e.param === 'id')) {
                return res.redirect(`/catalog/book/update`)
            }

            return res.status(400).render(`book_form.hbs`, {
                trouble: trouble.array(),
                genres: genreLabels,
                authors: authorLabels,
                title: 'Edit Book',
                form_action: undefined,
                submit: 'Save Changes',
                populate: item,
                genreChecks: req.body.genreList
                            ?.map(g => { return { genre_id: parseInt(g) } })
            })
        }

        // Remove the old book_genres table entries
        await bookGenres.delete({ book_id: req.params.id })
        const [resultBook] =
            await justBooks.update(item, { book_id: req.params.id})

        // Also need to repeatedly insert on genre/book junction table
        const bookID = resultBook.book_id
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

        res.redirect(resultBook.book_url)
    }
]
exports.book_update_choose = async (req, res) => {
    const result = await books.find()
    res.render(`book_action_choose.hbs`,
        { books: result, action: 'update' })
}
exports.book_delete_choose = async (req, res) => {
    const result = await books.find()
    res.render(`book_action_choose.hbs`,
        { books: result, action: 'delete' })
}
exports.book_delete_get = [
    bookIdValidator,
    async (req, res) => {
        const trouble = validationResult(req)
        if (!trouble.isEmpty() ) {
            log('got trouble>>', yellow)
            log(trouble.array())
            return res.redirect(`/catalog/book/delete`)
        }
        const [ resultBook, resultInstances ] = await Promise.all([
            books.find({ book_id: req.params.id }),
            bookInstances.find({ book_id: req.params.id })
        ])
        res.render(`book_delete.hbs`, {
            book: resultBook[0],
            instances: resultInstances
        })
    }
]
exports.book_delete_post = [
    bookIdValidator,
    async (req, res) => {
        justBooks.delete({ book_id: req.params.id })
        res.redirect(`/catalog/books`)
    }
]
exports.book_json_post = [
    preventTitleCollision,
    ...bookValidators,
    async (req, res) => {

        const trouble = validationResult(req)
        if (!trouble.isEmpty()) {
            return res.status(400).send({ trouble: trouble.array() })
        }

        const item = {
            title: req.body.title,
            isbn: req.body.isbn || null,
            author_id: req.body.author_id,
            summary: req.body.summary || null
        }

        // Having passed validation, create the new book.
        const result = await justBooks.insert(item)

        res.status(201).send(result[0])
    }
]
exports.book_import_get = (req, res) => {
    res.render(`import_book.hbs`, { title: 'Import book' })
}

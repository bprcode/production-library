require('express-async-errors')
const { body, param, validationResult } = require('express-validator')
const { books, justBooks, authors, genres, bookInstances, genresByBook,
        bookGenres, spotlightWorks, suggestions }
        = require('../database.js')
const { paginate, sanitizePagination } = require('./paginator.js')
const axios = require('axios')
const Fuse = require('fuse.js')

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
        suggestions.find('cover_id', 'title', 'snippet', 'book_url')
    ])

    res.render('catalog-active-home.hbs', {
        title: 'Welcome to the catalog',
        book_count: result[0],
        author_count: result[1],
        genre_count: result[2],
        available_count: result[4],
        total_count: result[3],
        recent_books: result[5]
    })
}
exports.book_list = [
    ...sanitizePagination,
    async (req, res) => {
        const limit = req.query.limit || 10
        const query = req.query.q || null

        if (query) {
            const allBooks = await books.find(
                'book_url', 'title', 'snippet', 'author_url', 'full_name')
            const fuse = new Fuse(allBooks, {
                keys: ['title'],
                threshold: 0.3,
                ignoreLocation: true,
                minMatchCharLength: 2,
                includeScore: true
            })
            const matches = fuse.search(req.query.q)
            return res.render('book_list.hbs', {
                books: matches.map(e => e.item),
                noResults: !Boolean(matches.length),
                total: matches.length,
                allResults: true,
                populate: { search: req.query.q }
            })
        }

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

        // Start a lookup on OpenLibrary,
        // add this book to the recent works spotlight if it looks good.
        suggestBook(result[0].title,
                    (await authors.find('full_name',
                        { author_id: result[0].author_id }))[0].full_name,
                    result[0].book_id)

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

        // Consider including the book in the recently-added list:
        suggestRecent(req.body.work_key, result[0].book_id)

        res.status(201).send(result[0])
    }
]
exports.book_import_get = (req, res) => {
    res.render(`import_book.hbs`, { title: 'Import book' })
}

async function suggestBook (title, author, book_id) {
    log(`Attempting book lookup for "${title}" by ${author}`
        +` with book_id ${book_id}`)

    try {
        const result = await axios({
            method: 'get',
            url: 'https://openlibrary.org/search.json?'
                    + 'title=' + title
                    + '&author=' + author
                    + '&fields=key'
                    + '&limit=1',
            headers: {
                // Refuse compression to avoid decompression bug in Axios 1.2.0
                'Accept-Encoding': 'identity'
            }
        })
        const workKey = result.data.docs[0].key

        const work = await axios ({
            method: 'get',
            url: 'https://openlibrary.org' + workKey + '.json',
            headers: {
                // Refuse compression to avoid decompression bug in Axios 1.2.0
                'Accept-Encoding': 'identity'
            }
        })

        const firstCover = work.data.covers[0]

        if (work.data.covers[0] > 0) {
            log('Work accepted. Adding to spotlight queue...', green)
            spotlightWorks.insert({ cover_id: firstCover, book_id: book_id })
        }
    } catch(e) {
        log.err(e.message)
    }
}

async function suggestRecent (workKey, book_id) {
    const minDescriptionLength = 200
    if (typeof workKey !== 'string') { return }

    try {
        log('Considering ', 'https://openlibrary.org' + workKey + '.json')

        const response = await axios({
            method: 'get',
            url: 'https://openlibrary.org' + workKey + '.json',
            headers: {
                // Refuse compression to avoid decompression bug in Axios 1.2.0
                'Accept-Encoding': 'identity'
            }
        })

        if (!Array.isArray(response.data.covers)) {
            log(`Rejecting suggestion `
                    + `(no covers available for ${workKey})`, pink)
            return
        }

        const firstCover = response.data.covers[0]
        const parsed = parseDescription(response.data.description)

        if (firstCover > 0 && parsed.length > minDescriptionLength) {
            log(`Suggested work looks good.`, pink)
            spotlightWorks.insert({ cover_id: firstCover, book_id: book_id })
        } else {
            log('This text doesn\'t look like a good candidate.', yellow)
        }

    } catch(e) {
        log.err(e.message)
    }

    function parseDescription (description) {
        if (!description) { return 'No description available.' }
        if (typeof description === 'string') { return description }
        return description.value || 'Unrecognized format.'
    }
}

const { books, authors, genres, bookInstances, genresByBook }
    = require('../database.js')

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
exports.book_create_get = (req, res) => {
    res.send(`<❕ placeholder>: Book create (GET)`)
}
exports.book_create_post = (req, res) => {
    res.send(`<❕ placeholder>: Book create (POST)`)
}
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

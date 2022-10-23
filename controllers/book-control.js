require('../database.js')

exports.index = (req, res) => {
    res.render('partials/catalog-layout.hbs',
        { title: 'Welcome to the catalog' })
}
exports.book_list = (req, res) => {
    res.send(`<❕ placeholder>: Book list`)
}
exports.book_detail = (req, res) => {
    res.send(`<❕ placeholder>: Book detail ${req.params.id}`)
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

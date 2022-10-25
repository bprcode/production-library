const { authors, books } = require('../database.js')

exports.author_list = async (req, res) => {
    const result = await authors.find()
    res.render(`author_list.hbs`, result)
}
exports.author_detail = async (req, res) => {
    const result = await Promise.all([
        authors.find({ author_id: req.params.id }),
        books.find({ author_id: req.params.id })
    ])
    if ( !result[0].rows.length ) {
        return res.render(`no_results.hbs`)
    }

    res.render(`author_detail.hbs`, {
        author: result[0].rows[0],
        books: result[1].rows
    })
}
exports.author_create_get = (req, res) => {
    res.send(`<❕ placeholder>: Author create (GET)`)
}
exports.author_create_post = (req, res) => {
    res.send(`<❕ placeholder>: Author create (POST)`)
}
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

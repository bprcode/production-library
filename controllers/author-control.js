const { authors } = require('../database.js')

exports.author_list = async (req, res) => {
    const result = await authors.find()
    res.render(`author_list.hbs`, result)
}
exports.author_detail = (req, res) => {
    res.send(`<❕ placeholder>: Author detail ${req.params.id}`)
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

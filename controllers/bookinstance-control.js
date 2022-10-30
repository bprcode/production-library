require('express-async-errors')
const { inventory, justBooks } = require('../database.js')

exports.bookinstance_list = async (req, res) => {
    const result = await inventory.find()
    res.render('instance_list.hbs', { items: result })
}
exports.bookinstance_detail = async (req, res) => {
    const result = await inventory.find({ instance_id: req.params.id })
    if ( !result ) {
        return res.render(`no_results.hbs`)
    }
    res.render(`bookinstance_detail.hbs`, result[0])
}
exports.bookinstance_create_get = async (req, res) => {
    const result = await justBooks.find()
    
    res.render(`bookinstance_form.hbs`, {
        bookList: result
    })
}
exports.bookinstance_create_post = (req, res) => {
    res.send(`<❕ placeholder>: Bookinstance create (POST)`)
}
exports.bookinstance_update_get = (req, res) => {
    res.send(`<❕ placeholder>: Bookinstance update (GET)`)
}
exports.bookinstance_update_post = (req, res) => {
    res.send(`<❕ placeholder>: Bookinstance update (POST)`)
}
exports.bookinstance_delete_get = (req, res) => {
    res.send(`<❕ placeholder>: Bookinstance delete (GET)`)
}
exports.bookinstance_delete_post = (req, res) => {
    res.send(`<❕ placeholder>: Bookinstance delete (POST)`)
}

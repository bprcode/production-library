const { inventory } = require('../database.js')
const { DateTime } = require('luxon')

exports.bookinstance_list = async (req, res) => {
    const result = await inventory.find()
    res.render('instance_list.hbs', {
        ...result
    })
}
exports.bookinstance_detail = (req, res) => {
    res.send(`<❕ placeholder>: Bookinstance detail ${req.params.id}`)
}
exports.bookinstance_create_get = (req, res) => {
    res.send(`<❕ placeholder>: Bookinstance create (GET)`)
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

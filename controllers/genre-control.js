const { genres, booksByGenre } = require('../database.js')

exports.genre_list = async (req, res) => {
    const result = await genres.find()
    res.render(`genre_list.hbs`, result)
}
exports.genre_detail = async (req, res) => {
    const result = await Promise.all([
        genres.find({ genre_id: req.params.id }),
        booksByGenre.find({ genre_id: req.params.id })
    ])

    if( !result[0].rows[0] )
        return res.render(`no_results.hbs`)

    res.render(`genre_detail.hbs`, {
        title: result[0].rows[0].name + ` titles`,
        result: result[1].rows
    })
}
exports.genre_create_get = (req, res) => {
    res.send(`<❕ placeholder>: Genre create (GET)`)
}
exports.genre_create_post = (req, res) => {
    res.send(`<❕ placeholder>: Genre create (POST)`)
}
exports.genre_update_get = (req, res) => {
    res.send(`<❕ placeholder>: Genre update (GET)`)
}
exports.genre_update_post = (req, res) => {
    res.send(`<❕ placeholder>: Genre update (POST)`)
}
exports.genre_delete_get = (req, res) => {
    res.send(`<❕ placeholder>: Genre delete (GET)`)
}
exports.genre_delete_post = (req, res) => {
    res.send(`<❕ placeholder>: Genre delete (POST)`)
}

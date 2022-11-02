require('express-async-errors')
const { body, param, validationResult } = require('express-validator')
const { inventory, justBooks, bookStatusList, bookInstances }
        = require('../database.js')

const instanceValidators = [
    body('book_id')
        .trim()
        .escape()
        .isLength({ min: 1 })
        .custom(async value => {
            if ( !(await justBooks.find({ book_id: value })) )
                throw new Error(`book_id not found.`)
        })
        .withMessage('Invalid title.'),
    body('imprint', 'Imprint required')
        .trim()
        .escape()
        .isLength({ min: 1 }),
    body('status')
        .escape()
        .isLength({ min: 1})
        .custom(async value => {
            const validStatusList = await bookStatusList()
            if ( !validStatusList.includes(value) )
                throw new Error(`Status not recognized.`)
        })
        .withMessage('Invalid status.'),
    body('due_back', 'Invalid date')
        .optional({ checkFalsy: true })
        .isISO8601()
        .toDate()
]

const instanceDeleteValidator =
    param('id', 'Invalid item ID.')
        .trim()
        .escape()
        .custom(async id => {
            if ( !await bookInstances.find({ instance_id: id }) )
                throw new Error(`Item ID not found.`)
        })

exports.bookinstance_list = async (req, res) => {
    const result = await inventory.find()
    res.render('instance_list.hbs', { items: result })
}
exports.bookinstance_detail = async (req, res) => {
    const result = await inventory.find({ instance_id: req.params.id })
    if ( !result ) {
        return res.render(`no_results.hbs`)
    }
    res.render(`bookinstance_detail.hbs`, {
        book_title: result[0].title, // Rename to avoid namespace conflict
        ...result[0]
    })
}
exports.bookinstance_create_get = async (req, res) => {
    const [bookList, statusList] = await Promise.all([
        justBooks.find(),
        bookStatusList()
    ])

    res.render(`bookinstance_form.hbs`, {
        bookList,
        statusList
    })
}
exports.bookinstance_create_post = [
    ...instanceValidators,
    async (req, res) => {
        let result
        const [bookList, statusList] = await Promise.all([
            justBooks.find(),
            bookStatusList()
        ])

        const trouble = validationResult(req)
        if ( !trouble.isEmpty() ) {
            return res.status(400).render(`bookinstance_form.hbs`, {
                bookList,
                statusList,
                trouble: trouble.array()
            })
        }

        let item = {
            book_id: req.body.book_id,
            imprint: req.body.imprint,
            status: req.body.status,
            due_back: req.body.due_back
        }

        if ( !req.body.due_back )
            delete item.due_back // Allow database to handle default

        try {
            result = await bookInstances.insert(item)
        } catch (e) {
            log.err(e.message)
            throw e
        }

        res.redirect(result[0].book_instance_url)
    }
]
exports.bookinstance_update_get = (req, res) => {
    res.send(`<❕ placeholder>: Bookinstance update (GET)`)
}
exports.bookinstance_update_post = (req, res) => {
    res.send(`<❕ placeholder>: Bookinstance update (POST)`)
}
exports.bookinstance_update_choose = async (req, res) => {
    const result = await inventory.find()
    res.render(`bookinstance_action_choose.hbs`,
        { items: result, action: 'update' })
}
exports.bookinstance_delete_choose = async (req, res) => {
    const result = await inventory.find()
    res.render(`bookinstance_action_choose.hbs`,
        { items: result, action: 'delete' })
}
exports.bookinstance_delete_get = [
    instanceDeleteValidator,
    async (req, res) => {
        const trouble = validationResult(req)
        if ( !trouble.isEmpty() ) {
            return res.status(400).redirect(`/catalog/inventory/delete`)
        }

        const result = await inventory.find({ instance_id: req.params.id })
        res.render(`bookinstance_delete.hbs`, { item: result[0] })
    }
]
exports.bookinstance_delete_post = [
    instanceDeleteValidator,
    async (req, res) => {
        const trouble = validationResult(req)
        if ( !trouble.isEmpty() ) {
            return res.status(400).redirect(`/catalog/inventory/delete`)
        }

        bookInstances.delete({ instance_id: req.params.id })
        res.status(200).redirect(`/catalog/inventory`)
    }
]

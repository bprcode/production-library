const { Pool } = require('pg')
const pool = new Pool()
const format = require('pg-format')

// Expose general query method
function query (...etc)  {
    return pool.query(...etc)
}

// General model for tables
// Note: Constructor values are an injection risk and should not
// be based on user input.
class Model {
    constructor (properties) {
        Object.assign(this, {
            schema: undefined,
            table: 'default_table',
            ...properties
        })
    }

    get relation () {
        if (this.junction) { return this.junction }
        if (this.schema) { return this.schema + '.' + this.table }
        return this.table
    }

    async count (conditions) {
        let clean
        let dirty = `SELECT count(*) FROM ${this.relation}`
        if ( !conditions ) {
            clean = format(dirty)
            log(clean, blue)
            return (await query(clean)).rows[0].count
        }
        // Otherwise...
        dirty += ` WHERE `
                    +Array(Object.keys(conditions).length)
                    .fill(`%I = %L`) // Escapes for format()
                    .join(` AND `)

        log(dirty, yellow)
        clean = format(dirty,
                        ...[...Object.entries(conditions)].flat())
        log(clean,blue)
        return (await query(clean)).rows[0].count
    }

    insert (item) {
        let clean = ``
        let dirty = `INSERT INTO ${this.relation} (` +
                    Array(Reflect.ownKeys(item).length)
                        .fill('%I')
                        .join(', ')
                    + `) VALUES (`
                    + Object.values(item)
                        .map((_,i) => `$` + (i+1))
                        .join(', ')
                    + `) RETURNING *`

        log(dirty, yellow)
        clean = format(dirty,
                        ...Object.keys(item))
        log(clean, blue)

        return query(clean, [...Object.values(item)])
    }

    /**
     * Columns to retrieve, followed by where-clause object
     * Ex: find('name', 'age', 'height', {state: 'NY', year: 1999})
     * @returns promise for query
     */
    find (...etc) {
        let dirty = `SELECT * FROM ${this.relation}`
        let clean = ``

        if (etc.length === 0) {
            dirty += this.orderClause
            log(dirty, yellow)
            return query(dirty) // Nothing to sanitize
        }
        // Otherwise...
        let where = null
        if (typeof etc.at(-1) === 'object') {
            where = etc.at(-1)
            etc = etc.slice(0, -1)
        }

        if (etc.length > 0) {
            dirty = `SELECT `
                    +Array(etc.length)
                    .fill(`%I`)
                    .join(`, `)
                    + ` FROM ${this.relation}`
        }

        if (where) {
            dirty += ` WHERE `
                        +Array(Object.keys(where).length)
                        .fill(`%I::text ILIKE `)
                        .map((x,i) => x + `$${i + 1}`)
                        .join(` AND `)
                        // %I::text ILIKE '$1', %I::text ILIKE '$2'...
        } else {
            where = {} // Use blank object for easier formatting
        }

        dirty += this.orderClause

        log(dirty, yellow)
        clean = format(dirty,
                        ...etc, // column names
                        ...Object.keys(where), // where-columns
                        this.order)
        log(clean, blue)

        return query(clean, Object.values(where))
    }

    join (other, key) {
        let newOrder = ''
        if (this.order) {
            newOrder = this.order +
                            (other.order
                            ? ', '
                            : '')
        }
        if (other.order) { newOrder += other.order }

        return new Model({
            junction: `${this.relation} JOIN ${other.relation}`
                        + ` USING(${key})`,
            order: newOrder
        })
    }

    get orderClause () {
        if ( !this.order )
            return ''
        let dirty = ` ORDER BY `
                        + Array(this.order.split(', ').length)
                        .fill('%I')
                        .join(', ')
        let clean = format(dirty, ...this.order.split(', '))
        return clean
    }
}

// Instantiate table models
const authors = new Model({
    schema: 'lib', table: 'authors', order: 'last_name' })
// Create books as a junction table (lib.books + lib.authors)
const books = new Model({
    schema: 'lib', table: 'books', order: 'title' })
    .join(authors, 'author_id')

// Sometimes you need books without the joined information:
const justBooks = new Model({ schema: 'lib', table: 'books', order: 'title' })

const genres = new Model({ schema: 'lib', table: 'genres', order: 'name' })
const bookGenres = new Model({ schema: 'lib', table: 'book_genres' })

const booksByGenre = new Model({
    schema: 'lib', table: 'books', order: 'title'})
    .join(bookGenres, 'book_id')

const genresByBook = bookGenres
    .join(genres, 'genre_id')

const bookInstances = new Model({
    schema: 'lib', table: 'book_instance', order: 'instance_id' })
const inventory = books.join(bookInstances, 'book_id')

// Data model for cd.members -- not used in library project
const members = {
    async find ( memid ) {
        memid = parseInt(memid)
        if (isNaN(memid))
            throw new Error('Invalid format for field: memid')

        const result = await query(
            'SELECT * FROM cd.members WHERE memid = $1',
            [memid])

        if (result.rows[0])
            return result
        else
            throw new Error(`Record ${memid} not found.`)
    }
}

// General library object -- not used much
const library = {
    async allBooks () {
        const result = await query({
            text:
            'select full_name, title, summary, isbn, author_url, book_url, lifespan::text '
            + ' from lib.books b join lib.authors a'
            + ' on a.author_id = b.author_id'
            + ' order by title',
            rowMode: 'array'
        })
        if (!result.rows[0])
            throw new Error('Unable to retrieve list of books.')

        const summaryIndex =
            result.fields.findIndex(f => f.name === 'summary')

        for (const r of result.rows) {
            if (r[summaryIndex]?.length > 50)
                r[summaryIndex] = r[summaryIndex].slice(0, 50) + '...'
        }

        return result
    },

    async createAuthor (...fields) {
        if (fields.length < 1)
            throw new Error('New authors require a first name.')

        fields = {
            1: '',
            ...fields
        }

        for (const k in fields) {
            let m = fields[k].match(/'(.*)'/)
            fields[k] = m?.[1]
        }
        log(`Creating author:`, blue)
        log(fields)

        return query(
            'INSERT INTO lib.authors(first_name, last_name, dob, dod) '
            +'VALUES ($1, $2, $3, $4)',
            [fields[0], fields[1], fields[2], fields[3]]
        )
    }
}

// Check the active database connections (exposes query text)
function getStatus () {
    return query('SELECT * FROM get_status()')
}

module.exports = {
    query, members, getStatus, library, books, justBooks, authors, genres,
    bookInstances, inventory, booksByGenre, genresByBook, bookGenres
}

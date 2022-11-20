const { Pool } = require('pg')
const pool = new Pool()
const format = require('pg-format')
require('@bprcode/handy')
let dbLog = log
if (process.env.NODE_ENV === 'production') {
    dbLog('Database driver operating in production mode.', blue)
    dbLog = x => {} // Silence database logging in production.
} else {
    dbLog('Database driver operating in development mode.', yellow)
}

// Expose general query method
function query (...etc)  {
    return pool.query(...etc)
}

// Run a query, but just return the rows, or row for single results,
// or null for no results.
async function queryResult (...etc) {
    const rows = (await pool.query(...etc)).rows
    if (rows.length === 0) {
        return null
    }
    
    return rows
}

/**
 * Find all Date objects in a result, and truncate them to YYYY-MM-DD strings.
 * Intended to work around the sometimes-problematic default behavior of pg,
 * wherein dates without timestamps are given "assumed" timestamps.
 * @param {*} source - An object, array of objects, or promise which resolves
 * to an object or array of objects, from which to convert Date objects into
 * date strings.
 */
async function snipTimes (source) {
    function snipObject (o) {
        for(const key in o) {
            if (o[key] instanceof Date)
                o[key] = o[key].toISOString().split('T')[0]
        }    
    }

    result = await source

    if (Array.isArray(result)) {
        for (const r of result)
            snipObject(r)
    } else {
        snipObject(result)
    }
    
    return result
}

// A class which parses an object into a SQL WHERE statement,
// accounting for nulls (IS NULL) and treating other properties as
// case-insensitive ILIKE comparisons.
class WhereClause {

    clause = ''
    _values = []

    constructor (conditions) {
        if (!conditions) { return }
        
        let index = 1
        const dirty = ' WHERE '
                    + Object.keys(conditions)
                        .map(k =>
                            conditions[k] === null
                                ? '%I IS NULL'
                                : '%I::text ILIKE $' + (index++))
                        .join(' AND ')

        this.clause = format(dirty, ...Object.keys(conditions))
        this._values = Object.values(conditions)
                        .filter(v => v !== null)
                        .map(v => String(v))
    }

    toString () {
        return this.clause
    }

    get values () {
        this._values.length
            && dbLog(' values: ', pink, this._values.join(', '), green)
        return this._values
    }

    static from (conditions) {
        return new WhereClause(conditions)
    }
}

// General model for tables
// Note: Constructor values are an injection risk
// and should not be based on user input.
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
        const sql = `SELECT count(*) FROM ${this.relation}`
        const where = WhereClause.from(conditions)

        dbLog(sql, green)
        return (await queryResult(sql + where, where.values))[0].count
    }

    delete (conditions) {
        if (!conditions)
            throw new Error(`No WHERE-parameters specified for DELETE.`)

        const where = WhereClause.from(conditions)
        const sql = `DELETE FROM ${this.relation} ${where}`
                        + ` RETURNING *`
        
        dbLog(sql, pink)
        return queryResult(sql, where.values)
    }

    insert (item) {
        let clean = ``
        let dirty = `INSERT INTO ${this.relation} (` +
                    Array(Object.keys(item).length)
                        .fill('%I')
                        .join(', ')
                    + `) VALUES (`
                    + Object.values(item)
                        .map((_,i) => `$` + (i+1))
                        .join(', ')
                    + `) RETURNING *`

        dbLog(dirty, yellow)
        clean = format(dirty,
                        ...Object.keys(item))
        dbLog(clean, blue)

        return queryResult(clean, Object.values(item))
    }

    /**
     * Makes the changes specified in the first object,
     * given that the conditions in the second object are met.
     * Ex: update({ price: 19.99 }, { state: 'CA', item_id: 123 })
     * @param {Object} replace - The key-value pairs to substitute
     * @param {Object} where - The conditions to meet
     */
    update (replace, where) {
        let clean = ``
        let dirty = `UPDATE ${this.relation} SET `
        const whereClause = WhereClause.from(where)
        // Where-clause indices come first,
        // followed by replace-value indices:
        let i = whereClause.values.length + 1

        dirty +=
            Object.keys(replace)
                .map(_ => `%I = $` + (i++))
                .join(', ')
        
        dirty += whereClause
        dirty += ` RETURNING *`

        clean = format(dirty, ...Object.keys(replace))

        dbLog(dirty, yellow)
        dbLog(clean, blue)

        return queryResult(clean,
            [...whereClause.values, ...Object.values(replace)])
    }

    /**
     * Columns to retrieve, followed by where-clause object
     * Ex: find('name', 'age', 'height', {state: 'NY', year: 1999})
     * @returns promise for query
     */
    find (...etc) {
        let clean = ``
        let dirty = `SELECT * FROM ${this.relation}`
        let where = null

        if (etc.length === 0) {
            dirty += this.orderClause
            dbLog(dirty, yellow)
            return queryResult(dirty) // Nothing to sanitize
        }
        // Otherwise...
        if (typeof etc.at(-1) === 'object') {
            where = WhereClause.from(etc.at(-1))
            etc = etc.slice(0, -1)
        }

        if (etc.length > 0) {
            dirty = `SELECT `
                    +Array(etc.length)
                    .fill(`%I`)
                    .join(`, `)
                    + ` FROM ${this.relation}`
        }

        dirty += where ?? ''
        dirty += this.orderClause

        clean = format(dirty,
                        ...etc, // column names
                        this.order)
                        
        dbLog(clean, blue)

        return queryResult(clean, where?.values)
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
    schema: 'lib', table: 'authors', order: 'last_name, first_name' })
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

/**
 * Retrieve an array of book status strings.
 * @returns Promise
 */
async function bookStatusList () {
    return (await queryResult(
                    `SELECT unnest(enum_range(NULL::lib.book_status))`))
                    .map(e => e.unnest)
}

module.exports = {
    query, queryResult, snipTimes,
    books, justBooks, authors, genres,
    bookInstances, inventory, booksByGenre, genresByBook, bookGenres,
    bookStatusList
}

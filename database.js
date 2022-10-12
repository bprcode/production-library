const { Pool } = require('pg')
const pool = new Pool()

// Expose general query method
function query (...etc)  {
    return pool.query(...etc)
}

// Data model for cd.members
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

// Data model for library tables
const library = {
    async allBooks () {
        const result = await query({
            text:
            'select full_name, title, summary, isbn, author_url, book_url, lifespan::text '
            + 'from lib.books b join lib.authors a '
            + 'on a.author_id = b.author_id',
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
    }
}

// Check the active database connections (exposes query text)
function getStatus () {
    return query('SELECT * FROM get_status()')
}

module.exports = { query, members, getStatus, library }

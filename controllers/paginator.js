const { query } = require('express-validator')

module.exports.sanitizePagination = [
    query('page').toInt().customSanitizer(v => v < 1 ? 1 : v),
    query('limit').toInt().customSanitizer(v => v < 1 ? 1 : v)
]

module.exports.paginate = function (page, limit, total) {
    console.log('resultPosition got ', page, limit, total)
    total = parseInt(total)

    const currentPage = page || 1
    let nextPage = null
    let previousPage = null
    let moreAfter = undefined
    let moreBefore = undefined
    let firstPage = undefined
    let lastPage = undefined

    let allResults = false
    let countStart = ((page - 1) * limit)
    let countEnd = Math.min(countStart + limit, total)
                        || limit
                        || total
    
    countStart = countStart + 1 || 1

    if (countStart === 1 && countEnd === total) { allResults = true }
    if (countEnd < total) { nextPage = currentPage + 1 }
    if (countStart > 1) { previousPage = currentPage - 1}
    if (countEnd + limit < total) {
        moreAfter = true
        lastPage = Math.ceil(total / limit)
    }
    if (countStart - limit > 1) {
        moreBefore = true
        firstPage = 1
    }

    return { countStart, countEnd, total, allResults, limit,
                firstPage, moreBefore, previousPage,
                currentPage, nextPage, moreAfter, lastPage }
}

export function paginate (page, limit, total) {
    page = parseInt(page)
    limit = parseInt(limit)
    total = parseInt(total)

    const currentPage = page || 1
    let nextPage = null
    let previousPage = null
    let moreAfter = undefined
    let moreBefore = undefined
    let firstPage = undefined
    let lastPage = undefined

    let allResults = false
    let countStart = ((page - 1) * limit) + 1
    let countEnd = Math.min(countStart + limit - 1, total)
                        || limit
                        || total
    
    countStart ||= 1

    if (countEnd > total) { countEnd = total }
    if (countStart === 1 && countEnd === total) { allResults = true }
    if (countEnd < total) { nextPage = currentPage + 1 }
    if (countStart > 1) { previousPage = currentPage - 1}
    if (countEnd + limit < total) { lastPage = Math.ceil(total / limit) }
    if (countStart - limit > 1) { firstPage = 1 }
    if (countEnd + 2 * limit < total ) { moreAfter = true }
    if (countStart - 2 * limit > 1 ) { moreBefore = true }

    return { countStart, countEnd, total, allResults, limit,
                firstPage, moreBefore, previousPage,
                currentPage, nextPage, moreAfter, lastPage }
}

export const openLibraryAddress = `https://openlibrary.org/search.json`
export const bookApiAddress =     `https://openlibrary.org/search/books.json`
export const bookDetailAddress =  `https://openlibrary.org/books/`
export const authorDetailAddress =`https://openlibrary.org/authors/`
export const authorApiAddress =   `https://openlibrary.org/search/authors.json`
export const workRootAddress =    `https://openlibrary.org`

Handlebars.registerHelper('error-check', (trouble, name) => {
    if (trouble)
        return trouble.find(t => t.param === name)?.msg
    return undefined
})

Handlebars.registerHelper('extract-year', dateString => {
    return dateString?.match(/\d*/)[0]
})

Handlebars.registerHelper('find-in', (arr, key, value) => {
    return arr?.find(e => e[key] === value)
})

Handlebars.registerHelper('delimit-array', (arr, delimiter) => {
    console.log(arr?.join(delimiter))
    return arr?.join(delimiter)
})

export function parseDescription (description) {
    if (!description) { return 'No description available.' }
    if (typeof description === 'string') { return description }
    return description.value || 'Unrecognized format.'
}

export function parseBio (doc) {
    if (!doc.bio)
        return 'No bio available.'

    if (typeof doc.bio === 'string')
        return doc.bio

    if (typeof doc.bio?.value === 'string')
        return doc.bio.value

    return 'Unrecognized format for bio.'
}

export function parseDate (dateString) {
    if (typeof dateString === 'string' && !dateString.match(/^\d+$/)) {
        let parsed
        try {
            parsed = new Date(dateString).toISOString().split('T')[0]
        } catch(e) {
            parsed = dateString.match(/\d+/)[0]
        }
        return parsed
    }

    return dateString
}

export function parseName (fullName) {
    if (!fullName)
        return fullName

    // Some OpenLibrary names end in a period.
    fullName = fullName.replace(/\.$/, '')

    // Some OpenLibrary names are last, first; others are first last.
    if (fullName.match(',')){
        fullName = fullName.split(', ').reverse().join(' ')
    }

    const split = fullName.split(' ')
    return {
        first: split.slice(0, -1).join(' '),
        last: split.slice(-1)[0]
    }
}

export async function retrieveBio (url) {
    try {
        const response = await fetch(url)
        const result = await response.json()
        return parseBio(result)
    } catch (e) {
        return 'Unable to retrieve biography.'
    }
}

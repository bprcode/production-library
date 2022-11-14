const openLibraryAddress = `https://openlibrary.org/search.json`
const bookApiAddress = `https://openlibrary.org/search/books.json`
const bookDetailAddress = `https://openlibrary.org/books/`

// Convenience shorthands
const log = console.log.bind(console)
const el = document.getElementById.bind(document)

const listTemplate = el('list-template')
const renderList = Handlebars.compile(listTemplate.innerHTML.trim())

Handlebars.registerHelper('error-check', (trouble, name) => {
    if (trouble)
        return trouble.find(t => t.param === name)?.msg
    return undefined
})
Handlebars.registerHelper('extract-year', dateString => {
    return dateString?.match(/\d*/)[0]
})

el('search-button').addEventListener('click', async event => {
    event.preventDefault()

    const query = el('search-text').value
    if (!query) { return }
    
    const searchParams = new URLSearchParams({
        title: query,
        limit: 20,
        page: 1,
        fields: [
            'key', 'title', 'author_name', 'first_publish_year', 'subject',
             'author_key',
             'cover_edition_key',
        ]
        // possibly take cover_edition_key by preference?
        // lots of isbns available, suggest taking one from the particular
        // edition preferred, not just the first one in the isbn arary
    })

    let queryUrl = new URL(openLibraryAddress)
    queryUrl.search = searchParams

    const searchButton = el('search-button')
    const searchSpinner = el('search-spinner')
    const magnifyingGlass = el('magnifying-glass')

    searchButton.setAttribute('disabled', 'true')
    searchSpinner.classList.remove('visually-hidden')
    magnifyingGlass.classList.add('d-none')

    const response = await fetch(queryUrl)
    const json = await response.json()

    log(json)
    
    el('search-result-id').innerHTML = renderList({
        header: `Displaying ${json.start + 1} `
                + ` to ${json.start + json.docs.length} `
                + `of ${json.numFound} results:`,
        books: json.docs
    })

    magnifyingGlass.classList.remove('d-none')
    searchButton.removeAttribute('disabled')
    searchSpinner.classList.add('visually-hidden')
})

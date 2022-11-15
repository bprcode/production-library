const openLibraryAddress = `https://openlibrary.org/search.json`
const bookApiAddress = `https://openlibrary.org/search/books.json`
const bookDetailAddress = `https://openlibrary.org/books/`
const workRootAddress = `https://openlibrary.org`

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

function parseDescription (description) {
    if (!description) { return 'No description available.' }
    if (typeof description === 'string') { return description }
    return description.value || 'Unrecognized format.'
}

async function handleDescriptionToggle (event) {
    const paragraph = event.target.children[1]
    if (paragraph.textContent !== 'Loading...') { return }

    try {
        const response = await fetch(workRootAddress
                                    + paragraph.dataset.key + '.json')
        const json = await response.json()
        log(json)
        paragraph.textContent = parseDescription(json.description)

    } catch(e) {
        return paragraph.textContent = 'Unable to retrieve record.'
    }
}

async function revealModal (event) {
    log('Modal template is:')
    log(revealModal.template)

    revealModal.template ??=
        await
            (await fetch('/templates/book_form_body.hbs'))
        .text()
    revealModal.renderTemplate ??= Handlebars.compile(revealModal.template)

    log('relatedTarget:')
    log(event.relatedTarget)
    
    return

    const authorKey = event.relatedTarget.dataset.key
    const modalBody = event.target.querySelector('#modal-body-id')
    let response
    let json

    modalBody.innerHTML = 'Loading...'
    try {
        response = await fetch(authorDetailAddress + authorKey + '.json')
        json = await response.json()
    } catch (e) {
        return modalBody.innerHTML = 'Unable to retrieve record.'
    }

    let parsedName
    let author
    let trouble = null

    try {
        parsedName = parseName(json.personal_name || json.name)
        author = {
            first_name: parsedName.first,
            last_name: parsedName.last,
            bio: parseBio(json),
            dob: parseDate(json.birth_date),
            dod: parseDate(json.death_date)
        }
    } catch(e) {
        return modalBody.innerHTML = 'Unable to parse record.'
    }

    modalBody.innerHTML = revealModal.renderTemplate({ author, trouble })
}

el('input-modal').addEventListener('show.bs.modal', revealModal)

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

        // ... seems like we need description from the work key,
        // perhaps ISBN preferentially from the cover edition?
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

    for (const e of document.querySelectorAll('.description')) {
        e.removeEventListener('toggle', handleDescriptionToggle)
    }

    el('search-result-id').innerHTML = renderList({
        header: `Displaying ${json.start + 1} `
                + ` to ${json.start + json.docs.length} `
                + `of ${json.numFound} results:`,
        books: json.docs
    })

    for (const e of document.querySelectorAll('.description')) {
        e.addEventListener('toggle', handleDescriptionToggle)
    }

    magnifyingGlass.classList.remove('d-none')
    searchButton.removeAttribute('disabled')
    searchSpinner.classList.add('visually-hidden')
})

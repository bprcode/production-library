import * as lib from "./import-common.js"

// Convenience shorthands
const log = console.log.bind(console)
const el = document.getElementById.bind(document)

const listTemplate = el('list-template')
const renderList = Handlebars.compile(listTemplate.innerHTML.trim())

async function handleDescriptionToggle (event) {
    const paragraph = event.target.children[1]
    if (paragraph.textContent !== 'Loading...') { return }

    try {
        const json = await fetch(lib.workRootAddress
                                + paragraph.dataset.key + '.json')
                                .then(response => response.json())

        paragraph.textContent = lib.parseDescription(json.description)

    } catch(e) {
        return paragraph.textContent = 'Unable to retrieve record.'
    }
}

async function revealModal (event) {
    // Initialize templates when first needed
    if (!revealModal.bookTemplate) {
        [revealModal.bookTemplate, revealModal.authorTemplate] =
        await Promise.all([
            fetch('/templates/book_form_body.hbs')
                .then(response => response.text()),

            fetch('/templates/author_form_body.hbs')
                .then(response => response.text())  
        ])

        revealModal.renderBookForm ??=
            Handlebars.compile(revealModal.bookTemplate)

        revealModal.renderAuthorForm ??=
            Handlebars.compile(revealModal.authorTemplate)
    }
    
    const dataset = event.relatedTarget.dataset

    const modalBook = el('modal-body-book')
    const modalAuthor = el('modal-body-author')
    modalBook.innerHTML = 'Loading...'

    try {
        const [work, coverEd, authorJson, genres] = await Promise.all([

            fetch(
                lib.workRootAddress + dataset.key + '.json'
                ).then(response => response.json()),
            
            dataset.editionKey
                ? fetch(lib.bookDetailAddress + dataset.editionKey + '.json')
                    .then(response => response.json())
                : {},

            dataset.firstAuthor
                ? fetch(
                    lib.authorDetailAddress + dataset.firstAuthor + '.json')
                    .then(response => response.json())
                : {},

            fetch('../genre/json').then(response => response.json())
        ])

        // Remove already-known genres from the suggestion list:
        work.subjects =
        work.subjects.filter(s => !genres.find(g => 
                g.name.localeCompare(s, undefined, { sensitivity: 'base' })
                    === 0
        ))

        let parsedName =
            lib.parseName(authorJson.personal_name || authorJson.name)
        const author = {
            first_name: parsedName.first,
            last_name: parsedName.last,
            bio: lib.parseBio(authorJson),
            dob: lib.parseDate(authorJson.birth_date),
            dod: lib.parseDate(authorJson.death_date)
        }

        modalBook.innerHTML = revealModal.renderBookForm({
            populate: {
                title: work.title,
                summary: lib.parseDescription(work.description),
                // Suggested ISBNs, in order of preference:
                isbn: coverEd.isbn_10 || coverEd.isbn_13
                        || dataset.firstIsbn || ''
            },
            genres: genres,
            suggestions: work.subjects.map((s,i) => {return {
                                        suggestion_id: i,
                                        name: s}}),
            omit_author: true,
            condense: true
        })
        modalAuthor.innerHTML = revealModal.renderAuthorForm({
            author: author,
            collapse: true
        })

    } catch (e) {
        log('error: ', e)
        modalBook.innerHTML = `Record not currently available.`
    }

    return
/*
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
    */
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
            'key', 'title', 'author_name', 'first_publish_year',
            'isbn',
            'author_key',
            'cover_edition_key',
        ]
    })

    let queryUrl = new URL(lib.openLibraryAddress)
    queryUrl.search = searchParams

    const searchButton = el('search-button')
    const searchSpinner = el('search-spinner')
    const magnifyingGlass = el('magnifying-glass')

    searchButton.setAttribute('disabled', 'true')
    searchSpinner.classList.remove('visually-hidden')
    magnifyingGlass.classList.add('d-none')

    const json = await fetch(queryUrl)
                        .then(response => response.json())

    log(json)

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

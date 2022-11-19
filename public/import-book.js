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
        if (work.subjects) {
            work.subjects = work.subjects.filter(
                s => !genres.find(g => 
                g.name.localeCompare(s, undefined, { sensitivity: 'base' })
                    === 0))
        } else {
            work.subjects = []
        }

        let parsedName =
            lib.parseName(authorJson.personal_name || authorJson.name)
        const author = {
            first_name: parsedName.first,
            last_name: parsedName.last,
            bio: lib.parseBio(authorJson),
            dob: lib.parseDate(authorJson.birth_date),
            dod: lib.parseDate(authorJson.death_date)
        }

        // Store retrieved values in case they are needed for re-rendering:
        revealModal.lastGenres = genres
        revealModal.lastSuggestions =
            work.subjects.map((s,i) => ({ suggestion_id: i, name: s }))

        modalBook.innerHTML = revealModal.renderBookForm({
            populate: {
                title: work.title,
                summary: lib.parseDescription(work.description),
                // Suggested ISBNs, in order of preference:
                isbn: coverEd.isbn_10 || coverEd.isbn_13
                        || dataset.firstIsbn || ''
            },
            genres: revealModal.lastGenres,
            suggestions: revealModal.lastSuggestions,
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
}

// Modal import click handler: Attempt to import data
el('import-button-id').addEventListener('click', async event => {
    const authorInput = Object.fromEntries(
                    new FormData(el('author-form')).entries())

    const bookInput = Object.fromEntries(
                    new FormData(el('book-form')).entries())

    el('import-button-id').setAttribute('disabled', 'true')
    el('import-spinner').classList.remove('visually-hidden')

    // Begin import process:
    // Create author -> create book -> create genres -> create associations
    let authorResult
    let bookResult
    let genreResult

    try {
        // Attempt to create author
        authorResult = await fetch('../author/json', {
            headers: {
                'Content-Type': 'application/json'
            },
            method: 'POST',
            body: JSON.stringify(authorInput)
        }).then(response => response.json())

        // If creation failed because the author is already recorded,
        // use the existing author_id and proceed:
        if (authorResult.trouble
            && authorResult.trouble[0].msg.startsWith(
                'Author already recorded')) {

            const previousID = authorResult.trouble[0].msg.split('#')[1]
            authorResult = { author_id: previousID }
            log('Proceeding with artificial result.')

        // If creation failed for another reason,
        // abort and re-render the form.
        } else if (authorResult.trouble) {
            throw new Error('Error recording author')
        }

        log(authorResult)

        if (authorResult.author_id) {
            log('Proceeding with author_id: ', authorResult.author_id)
        }

        // Attempt to create book
        bookInput.author_id = authorResult.author_id
        bookResult = await fetch('./json', {
            headers: {
                'Content-Type': 'application/json'
            },
            method: 'POST',
            body: JSON.stringify(bookInput)
        }).then(response => response.json())

        if (bookResult.trouble) {
            throw new Error('Error recording book')
        }

        log('No trouble encountered. Database accepted request with result:')
        log(bookResult)

        log('DEBUG placeholder -- handle genres')
        location.href = bookResult.book_url

    } catch (e) {
        log(e)
        log('Error encountered. Rendering bounceback.')
        log('Author trouble is:')
        log(authorResult?.trouble)
        log('Book trouble is:')
        log(bookResult?.trouble)

        el('modal-body-book').innerHTML = revealModal.renderBookForm({
            populate: bookInput,
            genres: revealModal.lastGenres,
            suggestions: revealModal.lastSuggestions,
            omit_author: true,
            condense: true,
            trouble: bookResult?.trouble
        })
        el('modal-body-author').innerHTML = revealModal.renderAuthorForm({
            author: authorInput,
            collapse: true,
            trouble: authorResult?.trouble
        })

    } finally {
        el('import-button-id').removeAttribute('disabled')
        el('import-spinner').classList.add('visually-hidden')
    }

    log('Todo: await create author, if successful, use rv to proceed.')
    log('Todo: await create book, if successful, use rv to proceed.')
    log('Todo: await create genres, if successful, use rvs to proceed.')
    log('Todo: create book/genre associations. No failover needed.')
})

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

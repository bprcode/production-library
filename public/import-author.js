import * as lib from './import-common.js'
import * as pager from './client-paginate.js'

// Convenience shorthands
const log = console.log.bind(console)
const el = document.getElementById.bind(document)

const listTemplate = el('list-template')
const renderList = Handlebars.compile(
    listTemplate.innerHTML.trim().replaceAll('#client-partial', '>'))

async function handleBioToggle (event) {
    const paragraph = event.target.children[1]

    if (paragraph.textContent === 'Loading...') {
        const url = lib.authorDetailAddress + paragraph.dataset.key + '.json'
        paragraph.textContent = await lib.retrieveBio(url)
    }
}

async function revealModal (event) {
    revealModal.template ??=
        await fetch('/templates/author_form_body.hbs')
                .then(response => response.text())

    revealModal.renderTemplate ??= Handlebars.compile(revealModal.template)

    const authorKey = event.relatedTarget.dataset.key
    const modalBody = event.target.querySelector('#modal-body-id')
    let json

    modalBody.innerHTML = 'Loading...'
    try {
        json = await fetch(lib.authorDetailAddress + authorKey + '.json')
                            .then(response => response.json())
    } catch (e) {
        return modalBody.innerHTML = 'Unable to retrieve record.'
    }

    let parsedName
    let author
    let trouble = null

    try {
        parsedName = lib.parseName(json.personal_name || json.name)
        author = {
            first_name: parsedName.first,
            last_name: parsedName.last,
            bio: lib.parseBio(json),
            dob: lib.parseDate(json.birth_date),
            dod: lib.parseDate(json.death_date)
        }
    } catch(e) {
        log(e)
        return modalBody.innerHTML = 'Unable to parse record.'
    }

    modalBody.innerHTML = revealModal.renderTemplate({ author, trouble })
}

el('input-modal').addEventListener('show.bs.modal', revealModal)

// Attempt to import form input data into our database.
el('import-button-id').addEventListener('click', async event => {
    try {
        const input = Object.fromEntries(
                        new FormData(el('author-form')).entries())

        el('import-button-id').setAttribute('disabled', 'true')
        el('import-spinner').classList.remove('visually-hidden')

        const result = await fetch('./json', {
            headers: {
                'Content-Type': 'application/json'
            },
            method: 'POST',
            body: JSON.stringify(input)
        }).then(response => response.json())

        el('import-button-id').removeAttribute('disabled')
        el('import-spinner').classList.add('visually-hidden')

        if (result.trouble)
            return el('modal-body-id').innerHTML =
                revealModal.renderTemplate({
                    author: input,
                    trouble: result.trouble
                })

        location.href = result.author_url // Redirect to new author page.

    } catch (e) {
        return log('Unable to connect to endpoint.')
    }

})

// Execute OpenLibrary search, render results
async function executeQuery (query, page = 1, limit = 20) {

    const searchParams = new URLSearchParams({
        q: query,
        limit: limit,
        offset: limit * (page - 1)
    })

    let queryUrl = new URL(lib.authorApiAddress)
    queryUrl.search = searchParams

    const searchButton = el('search-button')
    const searchSpinner = el('search-spinner')
    const magnifyingGlass = el('magnifying-glass')

    searchButton.setAttribute('disabled', 'true')
    searchSpinner.classList.remove('visually-hidden')
    magnifyingGlass.classList.add('d-none')

    try {
        if (!('pagination_header' in Handlebars.partials)) {
            const [header, footer] = await Promise.all([
                fetch('/templates/pagination_header.hbs')
                    .then(response => response.text()),
        
                fetch('/templates/pagination_footer.hbs')
                    .then(response => response.text())
            ])
        
            Handlebars.registerPartial('pagination_header', header)
            Handlebars.registerPartial('pagination_footer', footer)
        }

        const json = await fetch(queryUrl).then(response => response.json())
        const position = pager.paginate(page, limit, json.numFound)

        for (const e of document.querySelectorAll('.bio')) {
            e.removeEventListener('toggle', handleBioToggle)
        }

        for(const e of document.querySelectorAll('.pagination-control a')) {
            e.removeEventListener('click', handlePageClick)
        }

        el('search-result-id').innerHTML = renderList({
            header: `Displaying ${json.start + 1} `
                    + ` to ${json.start + json.docs.length} `
                    + `of ${json.numFound} results:`,
            authors: json.docs,
            noResults: !json.numFound,
            ...position
        })

        for (const e of document.querySelectorAll('.bio')) {
            e.addEventListener('toggle', handleBioToggle)
        }

        for(const e of document.querySelectorAll('.pagination-control a')) {
            e.addEventListener('click', handlePageClick)
            e.href = ''
            e.dataset.query = query
        }

        let animationDelay = (page === 1)
                                ? 30
                                : 400
        for(const e of document.querySelectorAll('.shade-initially')) {
            setTimeout(() =>
                e.classList.add('background-revert'), animationDelay)
            animationDelay += (page === 1)
                                ? 70
                                : -40
            if (animationDelay < 0) { animationDelay = 0}
        }

    } catch (e) {
        console.error(e.message)

    } finally {
        magnifyingGlass.classList.remove('d-none')
        searchButton.removeAttribute('disabled')
        searchSpinner.classList.add('visually-hidden')
    }
}

async function handlePageClick (event) {
    event.preventDefault()
    
    executeQuery(
        event.target.dataset.query,
        event.target.dataset.page,
        event.target.dataset.limit
    )

    el('results-header').scrollIntoView()
}

el('search-button').addEventListener('click', async event => {
    event.preventDefault()

    const query = el('search-text').value
    if (!query) { return }

    const page = 1
    const limit = 10

    executeQuery(query, page, limit)
})

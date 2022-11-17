import * as lib from './import-common.js'

// Convenience shorthands
const log = console.log.bind(console)
const el = document.getElementById.bind(document)

const listTemplate = el('list-template')
const renderList = Handlebars.compile(listTemplate.innerHTML.trim())

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

        const json = await fetch('./json', {
            headers: {
                'Content-Type': 'application/json'
            },
            method: 'POST',
            body: JSON.stringify(input)
        }).then(response => response.json())

        el('import-button-id').removeAttribute('disabled')
        el('import-spinner').classList.add('visually-hidden')

        if (json.trouble)
            el('modal-body-id').innerHTML =
                revealModal.renderTemplate({
                    author: input,
                    trouble: json.trouble
                })
        else
            location.href = json.url // Redirect to new author page.

    } catch (e) {
        return log('Unable to connect to endpoint.')
    }

})

// Execute OpenLibrary search
el('search-button').addEventListener('click', async event => {
    event.preventDefault()

    const query = el('search-text').value
    if (!query) { return }
    
    const searchParams = new URLSearchParams({
        q: query,
        limit: 20,
        page: 1
    })

    let queryUrl = new URL(lib.authorApiAddress)
    queryUrl.search = searchParams

    const searchButton = el('search-button')
    const searchSpinner = el('search-spinner')
    const magnifyingGlass = el('magnifying-glass')

    searchButton.setAttribute('disabled', 'true')
    searchSpinner.classList.remove('visually-hidden')
    magnifyingGlass.classList.add('d-none')

    const json = await fetch(queryUrl).then(response => response.json())

    for (const e of document.querySelectorAll('.bio')) {
        e.removeEventListener('toggle', handleBioToggle)
    }

    el('search-result-id').innerHTML = renderList({
        header: `Displaying ${json.start + 1} `
                + ` to ${json.start + json.docs.length} `
                + `of ${json.numFound} results:`,
        authors: json.docs
    })

    for (const e of document.querySelectorAll('.bio')) {
        e.addEventListener('toggle', handleBioToggle)
    }

    magnifyingGlass.classList.remove('d-none')
    searchButton.removeAttribute('disabled')
    searchSpinner.classList.add('visually-hidden')
})

const openLibraryAddress = `https://openlibrary.org/search.json`
const authorApiAddress = `https://openlibrary.org/search/authors.json`
const authorDetailAddress = `https://openlibrary.org/authors/`

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

function parseBio (doc) {
    if (!doc.bio)
        return 'No bio available.'

    if (typeof doc.bio === 'string')
        return doc.bio

    if (typeof doc.bio?.value === 'string')
        return doc.bio.value

    return 'Unrecognized format for bio.'
}

function parseDate (dateString) {
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

function parseName (fullName) {
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

async function retrieveBio (url) {
    try {
        const response = await fetch(url)
        const result = await response.json()
        return parseBio(result)
    } catch (e) {
        return 'Unable to retrieve biography.'
    }
}

async function handleBioToggle (event) {
    const paragraph = event.target.children[1]

    if (paragraph.textContent === 'Loading...') {
        const url = authorDetailAddress + paragraph.dataset.key + '.json'
        paragraph.textContent = await retrieveBio(url)
    }
}

async function revealModal (event) {
    revealModal.template ??=
        await
            (await fetch('/templates/author_form_body.hbs'))
        .text()
    revealModal.renderTemplate ??= Handlebars.compile(revealModal.template)

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

// Attempt to import form input data into our database.
el('import-button-id').addEventListener('click', async event => {
    try {
        const input = Object.fromEntries(
                        new FormData(el('author-form')).entries())

        el('import-button-id').setAttribute('disabled', 'true')
        el('import-spinner').classList.remove('visually-hidden')

        const response = await fetch('./json', {
            headers: {
                'Content-Type': 'application/json'
            },
            method: 'POST',
            body: JSON.stringify(input)
        })

        const json = await response.json()

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

    let queryUrl = new URL(authorApiAddress)
    queryUrl.search = searchParams

    const searchButton = el('search-button')
    const searchSpinner = el('search-spinner')
    const magnifyingGlass = el('magnifying-glass')

    searchButton.setAttribute('disabled', 'true')
    searchSpinner.classList.remove('visually-hidden')
    magnifyingGlass.classList.add('d-none')

    const response = await fetch(queryUrl)
    const json = await response.json()

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

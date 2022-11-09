const openLibraryAddress = `https://openlibrary.org/search.json`
const authorApiAddress = `https://openlibrary.org/search/authors.json`
const authorDetailAddress = `https://openlibrary.org/authors/`

const log = console.log
const template = document.getElementById('result-template')
const renderTemplate = Handlebars.compile(template.innerHTML.trim())

async function retrieveBio (url) {
    const response = await fetch(url)
    const result = await response.json()
    if (!result.bio)
        return 'No bio available.'

    if (typeof result.bio === 'string')
        return result.bio

    if (typeof result.bio?.value === 'string')
        return result.bio.value

    return 'Unrecognized format for bio.'
}

async function handleBioToggle (event) {
    const paragraph = event.target.children[1]

    if (paragraph.textContent === 'Loading...') {
        const url = authorDetailAddress + paragraph.dataset.key + '.json'
        paragraph.textContent = await retrieveBio(url)
    }
}

document.addEventListener('DOMContentLoaded', () => {
    document.getElementById('search-text').focus()
})

document.getElementById('search-button')
    .addEventListener('click', async event => {
        event.preventDefault()

        const query = document.getElementById('search-text').value
        let searchParams = new URLSearchParams({
            q: query,
            limit: 20,
            page: 1
        })

        let queryUrl = new URL(authorApiAddress)
        queryUrl.search = searchParams

        const searchButton = document.getElementById('search-button')
        const searchSpinner = document.getElementById('search-spinner')
        const magnifyingGlass = document.getElementById('magnifying-glass')

        searchButton.setAttribute('disabled', 'true')
        searchSpinner.classList.remove('visually-hidden')
        magnifyingGlass.classList.add('d-none')

        const response = await fetch(queryUrl)
        const json = await response.json()

        for (const e of document.querySelectorAll('.plus-button')) {
            e.removeEventListener('toggle', handleBioToggle)
        }

        document.getElementById('search-result-id').innerHTML
            = renderTemplate({
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

const openLibraryAddress = `https://openlibrary.org/search.json`

const log = console.log
log('Do I have Handlebars?')
log(Handlebars)
log('Can I find my template?')
const template = document.getElementById('result-template')
log(template.innerHTML.trim())
const renderTest = Handlebars.compile(template.innerHTML.trim())
log('Can I render with it?')
const templateData = {
    header: `Matching authors (${13} of ${69}):`,
    authors: [
        {author_name: 'Stevie King', dob: '1969-01-02',
            aka: ['Li\'l Steve', 'Steve the Wonderful', 'Mr. King', 'The KING']},
        {author_name: 'Ernie Hamingway', dod: '2039-13-27',
            aka: ['Easy E', 'The \'Way', 'El Presidente']},
        {author_name: 'Joy Carrot Oatmeal', dob: '1969-01-02', dod: '2039-13-27'},
        {author_name: 'Bill Faultner'},
    ]
}
log(renderTest(templateData))
document.getElementById('test-id').innerHTML = renderTest(templateData)

document.getElementById('search-button')
    .addEventListener('click', async event => {
        event.preventDefault()

        let searchParams = new URLSearchParams({
            author: 'tolkien',
            limit: 20,
            page: 1
        })
        let queryUrl = new URL(openLibraryAddress)

        queryUrl.search = searchParams

        console.log('>>')
        console.log(queryUrl.toString())

        // const query = document.getElementById('search-text').value
        // const listRoot = document.getElementById('list-root')
        const searchButton = document.getElementById('search-button')
        const searchSpinner = document.getElementById('search-spinner')
        const magnifyingGlass = document.getElementById('magnifying-glass')

        searchButton.setAttribute('disabled', 'true')
        searchSpinner.classList.remove('visually-hidden')
        magnifyingGlass.classList.add('d-none')

        const response = await fetch(queryUrl)
        const json = await response.json()

        // document.getElementById('list-header').textContent =
        //     `Displaying ${json.docs.length} of ${json.numFound} results.`
        
        // while (listRoot.lastElementChild) {
        //     listRoot.removeChild(listRoot.lastElementChild)
        // }

        // for (const doc of json.docs) {
        //     const li = document.createElement('li')
        //     li.textContent = doc.title
        //     li.classList.add('list-group-item')
        //     listRoot.append(li)
        // }

        magnifyingGlass.classList.remove('d-none')
        searchButton.removeAttribute('disabled')
        searchSpinner.classList.add('visually-hidden')
        
        console.log(json)
    })

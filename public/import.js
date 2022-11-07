const openLibraryURL = `https://openlibrary.org/search.json?`

document.getElementById('search-button')
    .addEventListener('click', async event => {
        event.preventDefault()

        const query = document.getElementById('search-text').value
        const listRoot = document.getElementById('list-root')
        const searchButton = document.getElementById('search-button')
        const searchSpinner = document.getElementById('search-spinner')

        searchButton.setAttribute('disabled', 'true')
        searchSpinner.classList.remove('visually-hidden')

        const response = await fetch(openLibraryURL + 'title=' + query)
        const json = await response.json()

        document.getElementById('list-header').textContent =
            `Displaying ${json.docs.length} of ${json.numFound} results.`
        
        while (listRoot.lastElementChild) {
            listRoot.removeChild(listRoot.lastElementChild)
        }

        for (const doc of json.docs) {
            const li = document.createElement('li')
            li.textContent = doc.title
            li.classList.add('list-group-item')
            listRoot.append(li)
        }

        searchButton.removeAttribute('disabled')
        searchSpinner.classList.add('visually-hidden')
        
        console.log(json)
    })

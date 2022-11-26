import * as lib from './import-common.js'
import * as pager from './client-paginate.js'

// Convenience shorthands
const log = console.log.bind(console)
const el = document.getElementById.bind(document)

const listTemplate = el('list-template')
let renderList = Handlebars.compile(
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

// ****************
const mockData = {
    "numFound": 146,
    "start": 0,
    "numFoundExact": true,
    "docs": [
      {
        "key": "OL3082758A",
        "type": "author",
        "name": "ABC-Clio Information Services",
        "top_work": "American family history",
        "work_count": 44,
        "top_subjects": [
          "Protected DAISY",
          "History",
          "Accessible book",
          "Bibliography",
          "United States",
          "Abstracts",
          "Politics and government",
          "Miscellanea",
          "Germany",
          "1933-1945"
        ],
        "_version_": 1735691928579604500
      },
      {
        "key": "OL727995A",
        "type": "author",
        "name": "James E. Lukaszewski",
        "alternate_names": [
          "James E. Lukaszewski; ABC; APR; Fellow PRSA; CCEP",
          "ABC, APR, Fellow PRSA James E. Lukaszewski"
        ],
        "top_work": "Why Should the Boss Listen to You",
        "work_count": 43,
        "top_subjects": [
          "Crisis management",
          "Public relations",
          "Business",
          "Risk management",
          "Management",
          "Leadership",
          "Handbooks, manuals",
          "Decision making",
          "Business consultants",
          "Business communication"
        ],
        "_version_": 1735707913784131600
      },
      {
        "key": "OL2648602A",
        "type": "author",
        "name": "ABC",
        "top_work": "About Campus",
        "work_count": 24,
        "top_subjects": [
          "Education",
          "Student activities",
          "Higher & further education",
          "Creative activities and seat work",
          "General",
          "Education / Teaching",
          "Coloring books",
          "Universities / polytechnics",
          "Protected DAISY",
          "Nature/Ecology"
        ],
        "_version_": 1735689867211309000
      },
      {
        "key": "OL9977921A",
        "type": "author",
        "name": "ABC-Clio",
        "top_work": "When Good Companies Go Bad",
        "work_count": 18,
        "top_subjects": [
          "Internet, law and legislation",
          "World war, 1914-1918",
          "Wind power",
          "United states, politics and government, 1865-1933",
          "United states, history",
          "Social conflict",
          "Soccer, juvenile literature",
          "Soccer",
          "Rome, history, military",
          "Progressivism (united states politics)"
        ],
        "_version_": 1735718129855627300
      },
      {
        "key": "OL3544484A",
        "type": "author",
        "name": "Abc",
        "top_work": "Fire & ice",
        "work_count": 16,
        "top_subjects": [
          "MEM REQ: 4m/Consumer..",
          "MACINTOSH & WINDOWS../"
        ],
        "_version_": 1735693583103557600
      },
      {
        "key": "OL2918743A",
        "type": "author",
        "name": "Abc-Clio Editors",
        "top_work": "Printmakers (Guide to Exhibited Artists, Vol 3)",
        "work_count": 11,
        "top_subjects": [
          "Protected DAISY",
          "Accessible book"
        ],
        "_version_": 1735691012491182000
      },
      {
        "key": "OL7551929A",
        "type": "author",
        "name": "Bee Book ABC",
        "top_work": "ABC Tracing Book For Preschool",
        "work_count": 10,
        "_version_": 1735708895508168700
      },
      {
        "key": "OL3637885A",
        "type": "author",
        "name": "ABC Staff",
        "top_work": "Play School",
        "work_count": 8,
        "top_subjects": [
          "Child and youth fiction"
        ],
        "_version_": 1735693797663178800
      },
      {
        "key": "OL218549A",
        "type": "author",
        "name": "Andrew Browne Cunningham Viscount Cunningham of Hyndhope",
        "alternate_names": [
          "Cunningham, Andrew Browne Viscount Cunningham of Hyndehope.",
          "Cunningham, Andrew Browne Cunningham Viscount",
          "A. B. Viscount Cunningham of Hyndhope Cunningham",
          "ABC",
          "Cunningham, Andrew Browne Cunningham, 1st Viscount, 1883-1963"
        ],
        "birth_date": "1883",
        "death_date": "1963",
        "top_work": "A sailor's odyssey",
        "work_count": 6,
        "top_subjects": [
          "World War, 1939-1945",
          "Naval operations, British",
          "British Naval operations",
          "World war, 1939-1945, naval operations, british",
          "World war, 1939-1945, campaigns",
          "Personal narratives, British",
          "Naval History",
          "Mediterranean Sea",
          "Mediterranean Sea",
          "History, Naval"
        ],
        "_version_": 1735688522922197000
      },
      {
        "key": "OL9812750A",
        "type": "author",
        "name": "ABC Book Publishers",
        "top_work": "Caminamos Por la FE",
        "work_count": 6,
        "top_subjects": [
          "Children's fiction",
          "Travel",
          "Religion",
          "Mind and body",
          "Spirituality",
          "Health",
          "Fiction, religious"
        ],
        "_version_": 1735717432694145000
      },
      {
        "key": "OL5664414A",
        "type": "author",
        "name": "ABC Television.",
        "top_work": "Studies in inter-media comparison",
        "work_count": 5,
        "_version_": 1735701557643575300
      },
      {
        "key": "OL6593972A",
        "type": "author",
        "name": "Live ABC",
        "top_work": "Mcgraw-hill's Chinese Illustrated Dictionary",
        "work_count": 5,
        "top_subjects": [
          "Textbooks for foreign speakers",
          "English",
          "Juvenile literature",
          "Glossaries, vocabularies",
          "Spanish language, dictionaries, english",
          "Spanish language",
          "Spanish Picture dictionaries",
          "Sound recordings for English speakers",
          "Self-instruction",
          "Picture dictionaries"
        ],
        "_version_": 1735705396481360000
      },
      {
        "key": "OL8960747A",
        "type": "author",
        "name": "ABC-CLIO Interactive Media (Firm)",
        "top_work": "The environmental movement in the United States",
        "work_count": 5,
        "top_subjects": [
          "United States",
          "Modern History",
          "History",
          "Sources",
          "Race relations",
          "Public officers",
          "Military biography",
          "Environmentalism",
          "Encyclopedias",
          "Civil rights movements"
        ],
        "_version_": 1735714131660505000
      },
      {
        "key": "OL10291317A",
        "type": "author",
        "name": "Comoposition COMOPOSITION abc",
        "top_work": "Halloween Activity : Halloween Activity Book for Kids Ages 4-8",
        "work_count": 4,
        "_version_": 1735682749743759400
      },
      {
        "key": "OL6986389A",
        "type": "author",
        "name": "ABC/Nepal",
        "top_work": "A situation analysis report on \"girls trafficking in Sindhupalchowk\"",
        "work_count": 4,
        "top_subjects": [
          "Women",
          "Nepal",
          "Crimes against",
          "Prostitution",
          "India",
          "Women in politics",
          "Social conditions",
          "Prostitutes",
          "Prevention",
          "Political activity"
        ],
        "_version_": 1735706700388761600
      },
      {
        "key": "OL10287459A",
        "type": "author",
        "name": "composition composition abc",
        "top_work": "Celebration of Life : Guest Book for Funeral, Memorial Service Guest Book for Funeral, Condolence Book for Memorial, Remembrances, Welcome to My Home",
        "work_count": 3,
        "_version_": 1735683122128748500
      },
      {
        "key": "OL3108337A",
        "type": "author",
        "name": "ABC Inc.",
        "top_work": "Cisco Networking Academy Program",
        "work_count": 3,
        "top_subjects": [
          "Computers",
          "Computer networks",
          "Workbooks",
          "Study guides",
          "Protected DAISY",
          "Programming - General",
          "Professional - General",
          "Operating systems (Computers)",
          "Networking - General",
          "Microcomputers"
        ],
        "_version_": 1735691852483395600
      },
      {
        "key": "OL3365650A",
        "type": "author",
        "name": "ABC Distribution Company",
        "top_work": "Focus On The Environment",
        "work_count": 3,
        "top_subjects": [
          "ELT: Learning Material & Coursework",
          "Nature/Ecology",
          "Nature",
          "NATURAL HISTORY, COUNTRY LIFE & PETS",
          "Language",
          "Foreign Language Study",
          "Environmental Conservation & Protection - General",
          "English as a Second Language",
          "Conservation of the environment",
          "American English"
        ],
        "_version_": 1735692662623699000
      },
      {
        "key": "OL3365652A",
        "type": "author",
        "name": "Maurice;Phr;Abc",
        "top_work": "Businesswatch TB",
        "work_count": 3,
        "_version_": 1735692662633136000
      },
      {
        "key": "OL9633079A",
        "type": "author",
        "name": "Passwort ABC",
        "top_work": "Passwort Buch Mit ABC Register",
        "work_count": 3,
        "_version_": 1735716949299560400
      }
    ]
  }
// ****************

let inputs = document.querySelectorAll('input')
for (const i of inputs) {
    i.addEventListener('focus', event => {
        i.classList.remove('is-invalid')
    })
}

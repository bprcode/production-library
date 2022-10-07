let forum = 'base'

let talker = {
    listen (s) {
        forum += ' ' + s
    },

    speak () {
        return forum
    }
}

module.exports = talker

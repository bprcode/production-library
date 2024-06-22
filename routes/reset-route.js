const express = require('express')
const { query } = require('../database.js')
const router = express.Router()

const resetDatabase = async function (req, res) {
  result = await query(resetSQL)
  res.send('Reset complete.')
  console.log('♻️ Reset complete.')
}

router
  .post('/', resetDatabase)

const resetSQL =
`
BEGIN;
DELETE FROM lib.spotlight_works;
DELETE FROM lib.book_instance;
DELETE FROM lib.book_genres;
DELETE FROM lib.books;
DELETE FROM lib.genres;
DELETE FROM lib.authors;

INSERT INTO lib.authors (author_id, first_name, last_name, dob, dod, bio)
  OVERRIDING SYSTEM VALUE (SELECT author_id, first_name, last_name, dob, dod,
  bio FROM lib.authors_restore);
INSERT INTO lib.genres (genre_id, name)
  OVERRIDING SYSTEM VALUE (SELECT genre_id, name FROM lib.genres_restore);
INSERT INTO lib.books (book_id, author_id, isbn, title, summary)
  OVERRIDING SYSTEM VALUE (SELECT book_id, author_id, isbn, title,
  summary FROM lib.books_restore);
INSERT INTO lib.book_genres (genre_id, book_id)
  (SELECT genre_id, book_id FROM lib.book_genres_restore);
INSERT INTO lib.book_instance (book_id, instance_id, imprint, due_back, status)
  OVERRIDING SYSTEM VALUE (SELECT book_id, instance_id, imprint,
  due_back, status FROM lib.book_instance_restore);
INSERT INTO lib.spotlight_works (serial, book_id, cover_id)
  OVERRIDING SYSTEM VALUE (SELECT * FROM lib.spotlight_works_restore);

SELECT SETVAL('lib.authors_author_id_seq',
  (SELECT max(author_id) FROM lib.authors));
SELECT SETVAL('lib.book_instance_instance_id_seq',
  (SELECT max(instance_id) FROM lib.book_instance));
SELECT SETVAL('lib.books_book_id_seq', (SELECT max(book_id) FROM lib.books));
SELECT SETVAL('lib.genres_genre_id_seq',
  (SELECT max(genre_id) FROM lib.genres));
SELECT SETVAL('lib.spotlight_works_serial_seq',
  (SELECT max(serial) FROM lib.spotlight_works));
COMMIT;
`

module.exports = router

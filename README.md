# Archivia

Archivia is a mock library catalog, implemented as a full-stack web service. Users can search a catalog of available books by title, subject, or author; update the status of inventory; and add or import metadata from real-world library databases.

For the purposes of publicly demonstrating this project, the server allows all users to freely modify records, however the catalog will periodically be reverted to its reference state by an automated process.

## Features

- Integration with the OpenLibrary API allows automated retrieval and population of database records. Non-relational record structures are parsed for a best-fit match to Archivia's catalog schema.

- The site renders a three-dimensional carousel gallery of recently added books using CSS transitions. Mesh textures and dimensions are inferred based on imported metadata. Records unlikely to yield quality results are excluded from the recency queue.

- Pages rendered via server-side templating for a nostalgic, vintage browsing experience.

### Built with:

Node.js, Handlebars, Bootstrap, PostgreSQL.

--
-- PostgreSQL database dump
--

-- Dumped from database version 14.5
-- Dumped by pg_dump version 14.5

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: lib; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA lib;


ALTER SCHEMA lib OWNER TO postgres;

--
-- Name: book_status; Type: TYPE; Schema: lib; Owner: postgres
--

CREATE TYPE lib.book_status AS ENUM (
    'Available',
    'Maintenance',
    'Loaned',
    'Reserved'
);


ALTER TYPE lib.book_status OWNER TO postgres;

--
-- Name: delete_oldest_spotlight(); Type: FUNCTION; Schema: lib; Owner: postgres
--

CREATE FUNCTION lib.delete_oldest_spotlight() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN

	IF (SELECT count(*) FROM lib.spotlight_works) > 4 then

		DELETE FROM lib.spotlight_works WHERE serial =

		(SELECT serial FROM lib.spotlight_works ORDER BY serial ASC LIMIT 1);

	END IF;

	RETURN NULL;

END;



$$;


ALTER FUNCTION lib.delete_oldest_spotlight() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: authors; Type: TABLE; Schema: lib; Owner: postgres
--

CREATE TABLE lib.authors (
    author_id integer NOT NULL,
    first_name text NOT NULL,
    last_name text,
    dob text,
    dod text,
    author_url text GENERATED ALWAYS AS (('/catalog/author/'::text || (author_id)::text)) STORED,
    bio text,
    full_name text GENERATED ALWAYS AS (
CASE
    WHEN (last_name IS NULL) THEN first_name
    WHEN (last_name = ''::text) THEN first_name
    ELSE ((first_name || ' '::text) || last_name)
END) STORED,
    blurb text GENERATED ALWAYS AS (
CASE
    WHEN (character_length(bio) > 250) THEN (SUBSTRING(bio FROM 1 FOR 250) || '...'::text)
    ELSE bio
END) STORED
);


ALTER TABLE lib.authors OWNER TO postgres;

--
-- Name: authors_author_id_seq; Type: SEQUENCE; Schema: lib; Owner: postgres
--

ALTER TABLE lib.authors ALTER COLUMN author_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME lib.authors_author_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: book_genres; Type: TABLE; Schema: lib; Owner: postgres
--

CREATE TABLE lib.book_genres (
    genre_id integer NOT NULL,
    book_id integer NOT NULL
);


ALTER TABLE lib.book_genres OWNER TO postgres;

--
-- Name: book_instance; Type: TABLE; Schema: lib; Owner: postgres
--

CREATE TABLE lib.book_instance (
    book_id integer NOT NULL,
    instance_id integer NOT NULL,
    imprint text NOT NULL,
    due_back date DEFAULT now(),
    status lib.book_status DEFAULT 'Maintenance'::lib.book_status NOT NULL,
    book_instance_url text GENERATED ALWAYS AS (('/catalog/inventory/'::text || (instance_id)::text)) STORED
);


ALTER TABLE lib.book_instance OWNER TO postgres;

--
-- Name: book_instance_instance_id_seq; Type: SEQUENCE; Schema: lib; Owner: postgres
--

ALTER TABLE lib.book_instance ALTER COLUMN instance_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME lib.book_instance_instance_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: books; Type: TABLE; Schema: lib; Owner: postgres
--

CREATE TABLE lib.books (
    book_id integer NOT NULL,
    author_id integer NOT NULL,
    isbn text,
    title text NOT NULL,
    summary text,
    book_url text GENERATED ALWAYS AS (('/catalog/book/'::text || (book_id)::text)) STORED,
    snippet text GENERATED ALWAYS AS (
CASE
    WHEN (character_length(summary) > 250) THEN (SUBSTRING(summary FROM 1 FOR 250) || '...'::text)
    ELSE summary
END) STORED
);


ALTER TABLE lib.books OWNER TO postgres;

--
-- Name: books_book_id_seq; Type: SEQUENCE; Schema: lib; Owner: postgres
--

ALTER TABLE lib.books ALTER COLUMN book_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME lib.books_book_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: genres; Type: TABLE; Schema: lib; Owner: postgres
--

CREATE TABLE lib.genres (
    genre_id integer NOT NULL,
    name text NOT NULL,
    genre_url text GENERATED ALWAYS AS (('/catalog/genre/'::text || (genre_id)::text)) STORED
);


ALTER TABLE lib.genres OWNER TO postgres;

--
-- Name: genres_genre_id_seq; Type: SEQUENCE; Schema: lib; Owner: postgres
--

ALTER TABLE lib.genres ALTER COLUMN genre_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME lib.genres_genre_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: spotlight_works; Type: TABLE; Schema: lib; Owner: postgres
--

CREATE TABLE lib.spotlight_works (
    serial integer NOT NULL,
    book_id integer,
    cover_id text
);


ALTER TABLE lib.spotlight_works OWNER TO postgres;

--
-- Name: spotlight_works_serial_seq; Type: SEQUENCE; Schema: lib; Owner: postgres
--

ALTER TABLE lib.spotlight_works ALTER COLUMN serial ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME lib.spotlight_works_serial_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: authors authors_pkey; Type: CONSTRAINT; Schema: lib; Owner: postgres
--

ALTER TABLE ONLY lib.authors
    ADD CONSTRAINT authors_pkey PRIMARY KEY (author_id);


--
-- Name: book_genres book_genres_pkey; Type: CONSTRAINT; Schema: lib; Owner: postgres
--

ALTER TABLE ONLY lib.book_genres
    ADD CONSTRAINT book_genres_pkey PRIMARY KEY (genre_id, book_id);


--
-- Name: book_instance book_instance_pkey; Type: CONSTRAINT; Schema: lib; Owner: postgres
--

ALTER TABLE ONLY lib.book_instance
    ADD CONSTRAINT book_instance_pkey PRIMARY KEY (instance_id);


--
-- Name: books books_pkey; Type: CONSTRAINT; Schema: lib; Owner: postgres
--

ALTER TABLE ONLY lib.books
    ADD CONSTRAINT books_pkey PRIMARY KEY (book_id);


--
-- Name: genres genres_pkey; Type: CONSTRAINT; Schema: lib; Owner: postgres
--

ALTER TABLE ONLY lib.genres
    ADD CONSTRAINT genres_pkey PRIMARY KEY (genre_id);


--
-- Name: spotlight_works spotlight_works_book_id_key; Type: CONSTRAINT; Schema: lib; Owner: postgres
--

ALTER TABLE ONLY lib.spotlight_works
    ADD CONSTRAINT spotlight_works_book_id_key UNIQUE (book_id);


--
-- Name: spotlight_works spotlight_works_cover_id_key; Type: CONSTRAINT; Schema: lib; Owner: postgres
--

ALTER TABLE ONLY lib.spotlight_works
    ADD CONSTRAINT spotlight_works_cover_id_key UNIQUE (cover_id);


--
-- Name: spotlight_works spotlight_works_pkey; Type: CONSTRAINT; Schema: lib; Owner: postgres
--

ALTER TABLE ONLY lib.spotlight_works
    ADD CONSTRAINT spotlight_works_pkey PRIMARY KEY (serial);


--
-- Name: spotlight_works limit_spotlight; Type: TRIGGER; Schema: lib; Owner: postgres
--

CREATE TRIGGER limit_spotlight AFTER INSERT ON lib.spotlight_works FOR EACH STATEMENT EXECUTE FUNCTION lib.delete_oldest_spotlight();


--
-- Name: book_instance status_due_trigger; Type: TRIGGER; Schema: lib; Owner: postgres
--

CREATE TRIGGER status_due_trigger BEFORE INSERT OR UPDATE ON lib.book_instance FOR EACH ROW EXECUTE FUNCTION public.enforce_null_due();


--
-- Name: book_genres book_genres_book_id_fkey; Type: FK CONSTRAINT; Schema: lib; Owner: postgres
--

ALTER TABLE ONLY lib.book_genres
    ADD CONSTRAINT book_genres_book_id_fkey FOREIGN KEY (book_id) REFERENCES lib.books(book_id) ON DELETE CASCADE;


--
-- Name: book_genres book_genres_genre_id_fkey; Type: FK CONSTRAINT; Schema: lib; Owner: postgres
--

ALTER TABLE ONLY lib.book_genres
    ADD CONSTRAINT book_genres_genre_id_fkey FOREIGN KEY (genre_id) REFERENCES lib.genres(genre_id) ON DELETE CASCADE;


--
-- Name: book_instance book_instance_book_id_fkey; Type: FK CONSTRAINT; Schema: lib; Owner: postgres
--

ALTER TABLE ONLY lib.book_instance
    ADD CONSTRAINT book_instance_book_id_fkey FOREIGN KEY (book_id) REFERENCES lib.books(book_id) ON DELETE CASCADE;


--
-- Name: books fk_author; Type: FK CONSTRAINT; Schema: lib; Owner: postgres
--

ALTER TABLE ONLY lib.books
    ADD CONSTRAINT fk_author FOREIGN KEY (author_id) REFERENCES lib.authors(author_id) ON DELETE CASCADE;


--
-- Name: spotlight_works spotlight_works_book_id_fkey; Type: FK CONSTRAINT; Schema: lib; Owner: postgres
--

ALTER TABLE ONLY lib.spotlight_works
    ADD CONSTRAINT spotlight_works_book_id_fkey FOREIGN KEY (book_id) REFERENCES lib.books(book_id);


--
-- Name: SCHEMA lib; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON SCHEMA lib TO nodeuser;


--
-- Name: TABLE authors; Type: ACL; Schema: lib; Owner: postgres
--

GRANT ALL ON TABLE lib.authors TO nodeuser;


--
-- Name: TABLE book_genres; Type: ACL; Schema: lib; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE lib.book_genres TO nodeuser;


--
-- Name: TABLE book_instance; Type: ACL; Schema: lib; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE lib.book_instance TO nodeuser;


--
-- Name: TABLE books; Type: ACL; Schema: lib; Owner: postgres
--

GRANT ALL ON TABLE lib.books TO nodeuser;


--
-- Name: TABLE genres; Type: ACL; Schema: lib; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE lib.genres TO nodeuser;


--
-- Name: TABLE spotlight_works; Type: ACL; Schema: lib; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE lib.spotlight_works TO nodeuser;


--
-- PostgreSQL database dump complete
--


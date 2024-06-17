--
-- PostgreSQL database dump
--

-- Dumped from database version 15.3
-- Dumped by pg_dump version 15.3

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
-- Name: lib; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA lib;


--
-- Name: book_status; Type: TYPE; Schema: lib; Owner: -
--

CREATE TYPE lib.book_status AS ENUM (
    'Available',
    'Maintenance',
    'Loaned',
    'Reserved'
);


--
-- Name: delete_oldest_spotlight(); Type: FUNCTION; Schema: lib; Owner: -
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


--
-- Name: enforce_null_due(); Type: FUNCTION; Schema: lib; Owner: -
--

CREATE FUNCTION lib.enforce_null_due() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	if new.status::text ilike 'Available' then
		new.due_back = null;
	end if;
return new;
end;

$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: authors; Type: TABLE; Schema: lib; Owner: -
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


--
-- Name: authors_author_id_seq; Type: SEQUENCE; Schema: lib; Owner: -
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
-- Name: book_genres; Type: TABLE; Schema: lib; Owner: -
--

CREATE TABLE lib.book_genres (
    genre_id integer NOT NULL,
    book_id integer NOT NULL
);


--
-- Name: book_instance; Type: TABLE; Schema: lib; Owner: -
--

CREATE TABLE lib.book_instance (
    book_id integer NOT NULL,
    instance_id integer NOT NULL,
    imprint text NOT NULL,
    due_back date DEFAULT now(),
    status lib.book_status DEFAULT 'Maintenance'::lib.book_status NOT NULL,
    book_instance_url text GENERATED ALWAYS AS (('/catalog/inventory/'::text || (instance_id)::text)) STORED
);


--
-- Name: book_instance_instance_id_seq; Type: SEQUENCE; Schema: lib; Owner: -
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
-- Name: books; Type: TABLE; Schema: lib; Owner: -
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
END) STORED,
    index_title text GENERATED ALWAYS AS (
CASE
    WHEN ("left"(title, 4) ~~* 'the '::text) THEN ("substring"(title, 5) || ', The'::text)
    ELSE title
END) STORED
);


--
-- Name: books_book_id_seq; Type: SEQUENCE; Schema: lib; Owner: -
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
-- Name: genres; Type: TABLE; Schema: lib; Owner: -
--

CREATE TABLE lib.genres (
    genre_id integer NOT NULL,
    name text NOT NULL,
    genre_url text GENERATED ALWAYS AS (('/catalog/genre/'::text || (genre_id)::text)) STORED
);


--
-- Name: genres_genre_id_seq; Type: SEQUENCE; Schema: lib; Owner: -
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
-- Name: spotlight_works; Type: TABLE; Schema: lib; Owner: -
--

CREATE TABLE lib.spotlight_works (
    serial integer NOT NULL,
    book_id integer,
    cover_id text
);


--
-- Name: spotlight_works_serial_seq; Type: SEQUENCE; Schema: lib; Owner: -
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
-- Data for Name: authors; Type: TABLE DATA; Schema: lib; Owner: -
--

COPY lib.authors (author_id, first_name, last_name, dob, dod, bio) FROM stdin;
1	J. R. R.	Tolkien	1892-01-03	1973-09-02	John Ronald Reuel Tolkien (1892-1973) was a major scholar of the English language, specialising in Old and Middle English. Twice Professor of Anglo-Saxon (Old English) at the University of Oxford, he also wrote a number of stories, including most famously The Hobbit (1937) and The Lord of the Rings (1954-1955), which are set in a pre-historic era in an invented version of the world which he called by the Middle English name of Middle-earth. This was peopled by Men (and women), Elves, Dwarves, Trolls, Orcs (or Goblins) and of course Hobbits. He has regularly been condemned by the Eng. Lit. establishment, with honourable exceptions, but loved by literally millions of readers worldwide.\n\nIn the 1960s he was taken up by many members of the nascent "counter-culture" largely because of his concern with environmental issues. In 1997 he came top of three British polls, organised respectively by Channel 4 / Waterstone's, the Folio Society, and SFX, the UK's leading science fiction media magazine, amongst discerning readers asked to vote for the greatest book of the 20th century. \n\n([Source][1])\n\n\n  [1]: http://www.tolkiensociety.org/tolkien/biography.html
5	F. Scott	Fitzgerald	1896-09-24	1940-12-21	Francis Scott Key Fitzgerald was an American author of novels and short stories, whose works are evocative of the Jazz Age, a term he coined himself. He is widely regarded as one of the twentieth century's greatest writers. Fitzgerald is considered a member of the "Lost Generation" of the Twenties. He finished four novels, *This Side of Paradise*, *The Beautiful and Damned*, *Tender Is the Night* and his most famous, the celebrated classic, *The Great Gatsby*. A fifth, unfinished novel, *The Love of the Last Tycoon* was published posthumously. Fitzgerald also wrote many short stories that treat themes of youth and promise along with despair and age. ([Wikipedia][1])\n\n\n  [1]: http://en.wikipedia.org/wiki/F._Scott_Fitzgerald
6	James	Joyce	1882-02-02	1941-01-13	James Augustine Aloysius Joyce was an Irish novelist and poet. He contributed to the modernist avant-garde and is regarded as one of the most influential and important authors of the 20th century.\n\nJoyce is best known for Ulysses (1922), a landmark work in which the episodes of Homer's Odyssey are paralleled in an array of contrasting literary styles, perhaps most prominent among these the stream of consciousness technique he utilised. Other well-known works are the short-story collection Dubliners (1914), and the novels A Portrait of the Artist as a Young Man (1916) and Finnegans Wake (1939). His other writings include three books of poetry, a play, occasional journalism and his published letters. [(Wikipedia][1])\n\n\n  [1]: https://en.wikipedia.org/wiki/James_Joyce
7	J. D.	Salinger	1919-01-01	2010-01-27	The New Yorker has made a series of Salinger's short stories available online: http://www.newyorker.com/online/blogs/backissues/2010/01/postscript-j-d-salinger.html
8	George	Orwell	1903-06-25	1950-01-21	George Orwell, originally born as Eric Arthur Blair, was an English novelist and journalist. His work is marked by keen intelligence and wit, a profound awareness of social injustice, an intense, revolutionary opposition to totalitarianism, a passion for clarity in language and a belief in democratic socialism. ([Source][1].)\n\n[1]:https://en.wikipedia.org/wiki/George_Orwell
3	Kurt	Vonnegut	1922-11-11	2007-04-11	Kurt Vonnegut, born in 1922 in Indianapolis, Indiana, was an American novelist, essayist, and satirist whose works challenged conventional norms and explored themes of human folly, absurdity, and the destructive potential of technology and bureaucracy. After serving in World War II and surviving the bombing of Dresden as a prisoner of war, Vonnegut drew on these experiences to craft his distinctive narrative style marked by dark humor and moral urgency. His novels, including "Slaughterhouse-Five," "Cat's Cradle," and "Breakfast of Champions," often blurred the lines between science fiction, social commentary, and memoir, earning him a reputation as a countercultural literary icon. Vonnegut's wit, skepticism towards authority, and empathy for the human condition resonated deeply with readers, cementing his legacy as one of the most influential American writers of the 20th century.
9	Harper	Lee	1926-04-28	2016-02-19	Nelle Harper Lee was an American novelist. She wrote the 1960 novel To Kill a Mockingbird that won the 1961 Pulitzer Prize and became a classic of modern American literature. Lee received numerous accolades and honorary degrees, including the Presidential Medal of Freedom in 2007 which was awarded for her contribution to literature. She assisted her close friend Truman Capote in his research for the book In Cold Blood (1966). Capote was the basis for the character Dill Harris in To Kill a Mockingbird.
11	Emily	Brontë	1818	1848	Emily Jane Brontë was an English novelist and poet, now best remembered for her novel [Wuthering Heights][1], a classic of English literature. Emily was the second eldest of the three surviving Brontë sisters, between Charlotte and Anne. She published under the androgynous pen name Ellis Bell. ([Source][2].)\n\n\n  [1]: http://upstream.openlibrary.org/works/OL10427528W/Wuthering_Heights\n  [2]: http://en.wikipedia.org/wiki/Emily_Bronte
12	Miguel de Cervantes	Saavedra	1547-09-29	1616-04-23	Miguel de Cervantes Saavedra was a Spanish novelist, poet, and playwright. His magnum opus, Don Quixote, often considered the first modern novel, is a classic of Western literature and is regularly regarded among the best novels ever written. His work is considered among the most important in all of literature. His influence on the Spanish language has been so great that Spanish is often called *la lengua de Cervantes* (The language of Cervantes). He has been dubbed *el Príncipe de los Ingenios* - the Prince of Wits. ([Source][1].)\n\n\n  [1]: http://en.wikipedia.org/wiki/Miguel_de_Cervantes
13	Leo	Tolstoy	1828-09-09	1910-11-20	Count **Lev Nikolayevich Tolstoy** (Russian: **Лев Николаевич Толстой**, 9 September 1828 – 20 November 1910), usually referred to in English as **Leo Tolstoy**, was a Russian writer. He is regarded as one of the greatest and most influential authors of all time. Tolstoy's notable works include the novels *War and Peace* (1869) and *Anna Karenina* (1878), often cited as pinnacles of realist fiction, and two of the greatest books of all time.
14	Joseph	Heller	1923-05-01	1999-12-12	An American satirical novelist, short story writer and playwright.
15	Charlotte	Brontë	1816	1855-01-01	Charlotte Brontë was an English novelist, the eldest of the three Brontë sisters whose novels are English literature standards. Under the pen name Currer Bell, she wrote Jane Eyre.  ([Source][1].)\n\n[1]: http://en.wikipedia.org/wiki/Charlotte_Brontë\n\nHer sisters, Anne and Emily, first published their works as Acton and Ellis Bell.
16	William	Faulkner	1897-09-25	1962-07-06	William Faulkner was a Nobel Prize-winning American  author. One of the most influential writers of the 20th century, his reputation is based on his novels, novellas  and short stories. He was also a published poet and an occasional screenwriter. ([Source][1].)\n\n[1]:http://en.wikipedia.org/wiki/William_Faulkner
17	Lewis	Carroll	1832-01-27	1898-01-14	Lewis Carroll is well known throughout the world as the author of  Alice's Adventures in Wonderland and  Through the Looking-Glass. Behind the famous pseudonym was Charles Lutwidge Dodgson, a mathematical lecturer at Oxford University with remarkably diverse talents. ([Source][1].)\n\n\n  [1]: http://lewiscarrollsociety.org.uk/pages/lewiscarroll/life.html
18	Joseph	Conrad	1857-12-03	1924-08-03	Joseph Conrad was a Polish-born British novelist, who became a British subject in 1886. He is regarded as one of the greatest novelists in English though he did not speak the language fluently until he was in his twenties (and then always with a marked Polish accent). He wrote stories and novels, predominantly with a nautical or seaboard setting, that depict trials of the human spirit by the demands of duty and honor. ([Source][1].)\n\n[1]:https://en.wikipedia.org/wiki/Joseph_Conrad
37	Truman	Capote	1924-09-30	1984-08-25	**Truman Capote** was an American writer, many of whose short stories, novels, plays, and nonfiction are recognized literary classics, including the novella *Breakfast at Tiffany's* (1958) and *In Cold Blood* (1965), which he labeled a "nonfiction novel".
19	Toni	Morrison	1931-02-18	2019-08-05	Toni Morrison is a Nobel Prize and Pulitzer Prize-winning American author, editor, and professor. Her novels are known for their epic themes, vivid dialogue, and richly detailed black characters. Among her best known novels are *The Bluest Eye*, *Song of Solomon*, and *Beloved*. ([Source][1].)\n\n[1]:https://en.wikipedia.org/wiki/Toni_Morrison
20	H. G.	Wells	1866-09-21	1946-08-13	Herbert George Wells was an English author, best known for his work in the science fiction genre. He was also a prolific writer in many genres, including contemporary novels, history, politics and social commentary.
21	Mary Wollstonecraft	Shelley	1797-08-30	1851-02-01	Mary Wollstonecraft Shelley was a British novelist, short story writer, dramatist, essayist, biographer, and travel writer, best known for her Gothic novel Frankenstein: or, The Modern Prometheus (1818). She also edited and promoted the works of her husband, the Romantic poet and philosopher Percy Bysshe Shelley. Her father was the political philosopher  William Godwin, and her mother was the philosopher and feminist Mary Wollstonecraft. ([Source][1].)\n\n[1]: https://en.wikipedia.org/wiki/Mary_Shelley
23	Jack	Kerouac	1922-03-12	1969-10-21	Jack Kerouac was an American novelist and poet of French-Canadian ancestry.\n\nHe is considered a literary iconoclast and, alongside William S. Burroughs and Allen Ginsberg, a pioneer of the Beat Generation Kerouac is recognized for his method of spontaneous prose. Thematically, his work covers topics such as Catholic spirituality, jazz, promiscuity, Buddhism, drugs, poverty, and travel. He became an underground celebrity and, with other beats, a progenitor of the hippie movement, although he remained antagonistic toward some of its politically radical elements.
24	Aldous	Huxley	1894-07-26	1963-11-22	Aldous Leonard Huxley (26 July 1894 – 22 November 1963) was an English writer and philosopher. He wrote nearly 50 books, both novels and non-fiction works, as well as wide-ranging essays, narratives, and poems.
25	Jonathan	Swift	1667-11-30	1745-10-19	Jonathan Swift was an Irish satirist, essayist, political pamphleteer (first for the Whigs, then for the Tories), poet and cleric who became Dean of St. Patrick's, Dublin. He is remembered for works such as Gulliver's Travels, A Modest Proposal, A Journal to Stella, Drapier's Letters, The Battle of the Books, An Argument Against Abolishing Christianity, and A Tale of a Tub. \n\nSource and more information: https://en.wikipedia.org/wiki/Jonathan_Swift
26	Victor	Hugo	1802-02-26	1885-05-22	Victor-Marie Hugo was a French poet, playwright, novelist, essayist, visual artist, statesman, human rights activist and exponent of the Romantic movement in France.\n\nIn France, Hugo's literary fame comes first from his poetry but also rests upon his novels and his dramatic achievements. Among many volumes of poetry, Les Contemplations and La Légende des siècles stand particularly high in critical esteem, and Hugo is sometimes identified as the greatest French poet. Outside France, his best-known works are the novels Les Misérables and Notre-Dame de Paris (known in English also as The Hunchback of Notre-Dame).\n\nThough a committed conservative royalist when he was young, Hugo grew more liberal as the decades passed; he became a passionate supporter of republicanism, and his work touches upon most of the political and social issues and artistic trends of his time. He is buried in the Panthéon.\n\n([Source][1])\n\n\n  [1]: http://en.wikipedia.org/wiki/Victor_Hugo
28	Chinua	Achebe	1930	2013	Africa's most famous and illustrious black novelist. Nigerian born writer of powerful fiction, poetry, literary criticism, and children's books.
29	Alice	Walker	1944	\N	An American novelist, short-story writer, poet, essayist, and activist.
38	Daniel	Defoe	1661	1731-04-24	Daniel Defoe, born Daniel Foe, was an English writer, journalist, and pamphleteer, who gained enduring fame for his novel Robinson Crusoe. Defoe is notable for being one of the earliest proponents of the novel, as he helped to popularise the form in Britain, and is even referred to by some as among the founders of the English novel. A prolific and versatile writer, he wrote more than 500 books, pamphlets, and journals on various topics (including politics, crime, religion, marriage, psychology and the supernatural). He was also a pioneer of economic journalism. ([Source][1])\n\n\n  [1]: http://en.wikipedia.org/wiki/Daniel_Defoe
47	Frank	Herbert	1920-10-08	1986-02-11	Real name: Franklin Patrick Herbert Jr.
31	Nathaniel	Hawthorne	1804-07-04	1864-05-19	Nathaniel Hawthorne was an American novelist and short story writer.\n\nNathaniel Hawthorne was a 19th century American novelist and short story writer. He is seen as a key figure in the development of American literature for his tales of the nation's colonial history.\n\nShortly after graduating from Bowdoin College, Hathorne changed his name to Hawthorne. Hawthorne anonymously published his first work, a novel titled Fanshawe, in 1828. In 1837, he published Twice-Told Tales and became engaged to Sophia Peabody the next year. He worked at a Custom House and joined a Transcendentalist Utopian community, before marrying Peabody in 1842. The couple moved to The Old Manse in Concord, Massachusetts, later moving to Salem, the Berkshires, then to The Wayside in Concord. The Scarlet Letter was published in 1850, followed by a succession of other novels. A political appointment took Hawthorne and family to Europe before returning to The Wayside in 1860. Hawthorne died on May 19, 1864, leaving behind his wife and their three children.\n\nMuch of Hawthorne's writing centers around New England and many feature moral allegories with a Puritan inspiration. His work is considered part of the Romantic movement and includes novels, short stories, and a biography of his friend, the United States President Franklin Pierce.
32	Anne	Frank	1929-06-12	1945	German-born Dutch Jewish diarist and Holocaust victim.
33	Rachel	Carson	1907-05-27	1964	Biologist Rachel Louise Carson began her career with the U.S. Fish and Wildlife Service but achieved fame and social influence with publication of such popular books as The Sea Around Us (1951) and Silent Spring (1962). ([Source][1].)\n\n\n  [1]: http://www.flickr.com/photos/smithsonian/3359709268/
34	Henry	James	1843-04-15	1916-02-28	Henry James, was an American writer, regarded as one of the key figures of 19th-century literary realism. He was the son of Henry James, Sr., a clergyman, and the brother of philosopher and psychologist William James and diarist Alice James.  ([Source][1].)\n\n[1]:http://en.wikipedia.org/wiki/Henry_James
35	Margaret Eleanor	Atwood	1939-11-18	\N	Margaret Eleanor Atwood, OC is a Canadian writer. A prolific poet, novelist, literary critic, feminist and activist, she has received national and international recognition for her writing.\n\nATWOOD, whose work has been published in over forty countries, is the author of more than fifty books of fiction, poetry, and critical essays. In addition to The Handmaid's Tale, now a successful MGM-Hulu television series currently preparing its fourth season, her novels include Cat's Eye, shortlisted for the Booker Prize; Alias Grace, which won the Giller Prize in Canada and the Premio Mondello in Italy; The Blind Assassin, winner of the 2000 Booker Prize; Oryx and Crake, shortlisted for the 2003 Booker Prize; The Penelopiad; The Heart Goes Last; Hag-seed; and The Testaments, a sequel to The Handmaid's Tale, published in September, 2019. She lives in Toronto some of the time.
36	Henry David	Thoreau	1817-07-12	1862-05-06	Henry David Thoreau (born David Henry Thoreau) was an American author, poet, naturalist, tax resister, development critic, surveyor, historian, philosopher, and leading transcendentalist. He is best known for his book Walden, a reflection upon simple living in natural surroundings, and his essay, Civil Disobedience, an argument for individual resistance to civil government in moral opposition to an unjust state.\n\nThoreau's books, articles, essays, journals, and poetry total over 20 volumes. Among his lasting contributions were his writings on natural history and philosophy, where he anticipated the methods and findings of ecology and environmental history, two sources of modern day environmentalism. His literary style interweaves close natural observation, personal experience, pointed rhetoric, symbolic meanings, and historical lore; while displaying a poetic sensibility, philosophical austerity, and "Yankee" love of practical detail. He was also deeply interested in the idea of survival in the face of hostile elements, historical change, and natural decay; at the same time imploring one to abandon waste and illusion in order to discover life's true essential needs.\n\n([Source][1])\n\n\n  [1]: https://en.wikipedia.org/wiki/Henry_David_Thoreau
39	Sylvia	Plath	1932-10-27	1963-02-11	Sylvia Plath was an American poet, novelist, children's author, and short story author.\n\nSylvia Plath was born in Boston, Massachusetts, in 1932 and educated at Smith College and Newham College, Cambridge. There she met the poet Ted Hughs, whom she married in 1956. The couple settled permanently in England, and they had two children, a son and a daughter, before separating in 1962. She suffered from clinical depression for most of her adulthood, and lost her life to it in 1963.
41	Anthony	Burgess	1917-02-25	1993-11-22	John Anthony Burgess Wilson, who published under the name Anthony Burgess, was an English writer and composer.\n\nAlthough Burgess was primarily a comic writer, his dystopian satire *A Clockwork Orange* remains his best-known novel. In 1971, it was adapted into a controversial film by Stanley Kubrick, which Burgess said was chiefly responsible for the popularity of the book. Burgess produced numerous other novels, including the Enderby quartet, and Earthly Powers. He wrote librettos and screenplays, including the 1977 television mini-series Jesus of Nazareth. He worked as a literary critic for several publications, including The Observer and The Guardian, and wrote studies of classic writers, notably James Joyce. A versatile linguist, Burgess lectured in phonetics, and translated Cyrano de Bergerac, Oedipus Rex, and the opera Carmen, among others.\n\nBurgess also composed over 250 musical works; he considered himself as much a composer as an author, although he achieved considerably more success in writing.
42	Walt	Whitman	1819-05-31	1892-03-26	Walt Whitman was an American  poet, essayist, journalist, and humanist. He was a part of the transition between Transcendentalism and realism, incorporating both views in his works. Whitman is among the most influential poets in the American canon, often called the father of free verse.[1]  His work was very controversial in its time, particularly his poetry collection Leaves of Grass, which was described as obscene for its overt sexuality. ([Source][1].)\n\n[1]:https://en.wikipedia.org/wiki/Walt_Whitman
43	Oscar	Wilde	1854-10-16	1900-11-30	An Irish writer, poet, and prominent aesthete.\n\nOscar Fingal O'Flahertie Wills Wilde was an Irish playwright, poet, and author of numerous short stories, and one novel. Known for his biting wit, and a plentitude of aphorisms, he became one of the most successful playwrights of the late Victorian era in London, and one of the greatest celebrities of his day. Several of his plays continue to be widely performed, especially The Importance of Being Earnest.\n\nAs the result of a widely covered series of trials, Wilde suffered a dramatic downfall and was imprisoned for two years hard labour after being convicted of "gross indecency" with other men. After Wilde was released from prison he set sail for Dieppe by the night ferry. He never returned to Ireland or Britain, and died in poverty.
44	Ken	Kesey	1935	2001	KEN KESEY was born in La Junta, Colorado, but his family later moved to Springfield, Oregon, where he attended public schools, and later the University of Oregon at Eugene. He has received the Woodrow Wilson scholarship to Stanford University and a Saxton Fellowship, and won the Fred Lowe Scholarship awarded to the outstanding wrestler in the Northwest. Mr. Kesey was king of the Merry Pranksters, a group which traveled the West Coast staging happenings; as a leader of this group, Mr. Kesey appeared as subject and star in the bestseller, THE ELECTRIC KOOL-AID ACID TEST, by Tom Wolfe.\nAt present he is "scratching his athlete's foot on his farm in Oregon, watching his kids and blueberries grow."\n\nPhoto: By <span title="must have been published or publicly displayed outside Wikipedia">Source</span> (<a href="//en.wikipedia.org/wiki/Wikipedia:Non-free_content_criteria#4" title="Wikipedia:Non-free content criteria">WP:NFCC#4</a>), <a href="//en.wikipedia.org/wiki/File:Ken_Kesey,_American_author,_1935-2001.jpg" title="Fair use of copyrighted material in the context of Ken Kesey">Fair use</a>, <a href="https://en.wikipedia.org/w/index.php?curid=54571568">Link</a>
45	E. B.	White	1899-07-11	1985-10-01	Elwyn Brooks "E. B." White was an American writer. A long-time contributor to "The New Yorker" magazine, he also wrote many famous books for both adults and children, such as the popular Charlotte's Web and Stuart Little, and co-authored a widely used writing guide, The Elements of Style, popularly known by its authors' names, as "Strunk & White."
46	Ray	Bradbury	1920-08-22	2012-06-05	Ray Bradbury is one of those rare individuals whose writing has changed the way people think. His more than five hundred published works -- short stories, novels, plays, screenplays, television scripts, and verse -- exemplify the American imagination at its most creative. \n\nOnce read, his words are never forgotten. His best-known and most beloved books, *The Martian Chronicles*, *The Illustrated Man*, *Fahrenheit 451* and *Something Wicked This Way Comes*, are masterworks that readers carry with them over a lifetime. His timeless, constant appeal to audiences young and old has proven him to be one of the truly classic authors of the 20th Century -- and the 21st. \n\nIn recognition of his stature in the world of literature and the impact he has had on so many for so many years, Bradbury was awarded the National Book Foundation's 2000 Medal for Distinguished Contribution to American Letters, an the National Medal of Arts in 2004. \n\n([Source][1])\n\n\n  [1]: http://www.raybradbury.com/about.html
48	Malcolm	Lowry	1909-07-28	1957-06-26	Clarence Malcolm Lowry was a British poet and novelist who was best known for his novel, Under the Volcano.\n\nSource and more information: http://en.wikipedia.org/wiki/Malcolm_Lowry
50	Franz	Kafka	1883-07-03	1924-06-03	Franz Kafka is one of the most important and influential fiction writers of the early 20th century; a novelist and writer of short stories whose works, only after his death, came to be regarded as one of the major achievements of 20th century literature. ([Source][1].)\n\n[1]:https://en.wikipedia.org/wiki/Franz_Kafka
52	Maya	Angelou	1928-04-04	2014-05-28	Maya Angelou (born Marguerite Annie Johnson) was an American poet, memoirist, and civil rights activist. She published seven autobiographies, three books of essays, and several books of poetry, and was credited with a list of plays, movies, and television shows spanning over 50 years. She received dozens of awards and more than 50 honorary degrees.\n\nShe became a poet and writer after a series of occupations as a young adult, including fry cook, prostitute, nightclub dancer and performer, cast member of the opera Porgy and Bess, coordinator for the Southern Christian Leadership Conference, and journalist in Egypt and Ghana during the decolonization of Africa. She was an actor, writer, director, and producer of plays, movies, and public television programs. In 1982, she earned the first lifetime Reynolds Professorship of American Studies at Wake Forest University in Winston-Salem, North Carolina. She was active in the Civil Rights movement, and worked with Martin Luther King, Jr. and Malcolm X.\n\nSource: Wikipedia
53	Jack	London	1876-01-12	1916-11-22	John Griffith London (born John Griffith Chaney; January 12, 1876 – November 22, 1916) was an American novelist, journalist, and social activist. A pioneer in the world of commercial magazine fiction, he was one of the first writers to become a worldwide celebrity and earn a large fortune from writing. He was also an innovator in the genre that would later become known as science fiction.\n\nHis most famous works include *The Call of the Wild* and *White Fang*, both set in the Klondike Gold Rush, as well as the short stories "To Build a Fire", "An Odyssey of the North", and "Love of Life". He also wrote about the South Pacific in stories such as "The Pearls of Parlay", and "The Heathen".\n\nLondon was part of the radical literary group "The Crowd" in San Francisco and a passionate advocate of unionization, workers' rights, socialism, and eugenics. He wrote several works dealing with these topics, such as his dystopian novel The Iron Heel, his non-fiction exposé *The People of the Abyss*, *The War of the Classes*, and *Before Adam*.\n\n**Source**: [Jack London](https://en.wikipedia.org/wiki/Jack_London) on Wikipedia.
54	Cormac	McCarthy	1933-07-20	2023-06-13	Cormac McCarthy (born Charles Joseph McCarthy Jr.) is an American writer who has written twelve novels, two plays, five screenplays, and three short stories, spanning the Western and postapocalyptic genres. He is known for his graphic depictions of violence and his unique writing style, recognizable by a sparse use of punctuation and attribution. McCarthy is widely regarded as one of the greatest contemporary American writers.
55	John Kennedy	Toole	1937	1969	John Kennedy Toole (December 17, 1937 – March 26, 1969) was an American novelist from New Orleans, Louisiana, whose posthumously published novel *A Confederacy of Dunces* won the Pulitzer Prize for Fiction and was a big success. He also wrote *The Neon Bible.* Although several people in the literary world felt his writing skills were praiseworthy, Toole's novels were rejected during his lifetime. After suffering from paranoia and depression due in part to these failures, he died by suicide at the age of 31.
81	Joe	Abercrombie	1974-12-31	\N	Joseph Edward Abercrombie is a British fantasy writer and film editor. He is the author of The First Law trilogy, as well as other fantasy books in the same setting and a trilogy of young adult novels. His novel Half a King won the 2015 Locus Award for best young adult book.\n\nSource: https://en.wikipedia.org/wiki/Joe_Abercrombie
109	Brian	Christian	1984	\N	\N
56	Stephen	King	1947-09-21	\N	Stephen Edwin King (born September 21, 1947) is an American author of horror, supernatural fiction, suspense, crime, science-fiction, and fantasy novels. His books have sold more than 350 million copies, and many have been adapted into films, television series, miniseries, and comic books. King has published 63 novels, including seven under the pen name Richard Bachman, and five non-fiction books. He has also written approximately 200 short stories, most of which have been published in book collections.\n\nKing has received Bram Stoker Awards, World Fantasy Awards, and British Fantasy Society Awards. In 2003, the National Book Foundation awarded him the Medal for Distinguished Contribution to American Letters. He has also received awards for his contribution to literature for his entire bibliography, such as the 2004 World Fantasy Award for Life Achievement and the 2007 Grand Master Award from the Mystery Writers of America. In 2015, he was awarded with a National Medal of Arts from the U.S. National Endowment for the Arts for his contributions to literature. He has been described as the "King of Horror", a play on his surname and a reference to his high standing in pop culture.
57	Ursula K. Le	Guin	1929-10-21	2018-01-22	"As of 2010, Ursula K. Le Guin has published twenty-one novels, eleven volumes of short stories, three collections of essays, twelve books for children, six volumes of poetry and four of translation, and has received many awards: Hugo, Nebula, National Book Award, PEN-Malamud, etc. Her recent publications include a volume of poetry, Incredible Good Fortune, the novel Lavinia, and an essay collection, Cheek by Jowl. She lives in Portland, Oregon." - [source][1]\n\n\n  [1]: http://www.ursulakleguin.com/Biography-70Word.html
58	C. S.	Lewis	1898-11-29	1963-11-22	Clive Staples Lewis was an Irish-born British novelist, academic, medievalist, literary critic, essayist, lay theologian and Christian apologist.
59	John	Steinbeck	1902-02-27	1968-12-20	John Steinbeck was an American writer. He wrote the Pulitzer Prize-winning novel *The Grapes of Wrath* (1939) and the novella *Of Mice and Men* (1937). He wrote a total of 27 books, including 16 novels, six non-fiction books, and five collections of short stories. In 1962, Steinbeck received the Nobel Prize for Literature ([Source][1]).\n\n[1]:https://en.wikipedia.org/wiki/John_Steinbeck
60	Robert Louis	Stevenson	1850-11-13	1894-12-03	Robert Louis Stevenson (born Robert Lewis Balfour Stevenson; 13 November 1850 – 3 December 1894) was a Scottish novelist, essayist, poet and travel writer. He is best known for works such as Treasure Island, Strange Case of Dr Jekyll and Mr Hyde, Kidnapped and A Child's Garden of Verses.
61	Hermann	Hesse	1877-07-02	1962-08-09	Hermann Karl Hesse (2 July 1877 – 9 August 1962) was a German-Swiss poet, novelist, and painter. His best-known works include *Demian, Steppenwolf, Siddhartha,* and *The Glass Bead Game,* each of which explores an individual's search for authenticity, self-knowledge and spirituality. In 1946, he received the Nobel Prize in Literature.
62	Charles	Dickens	1812-02-07	1870-06-09	Charles Dickens, was the most popular English novelist of the Victorian era, and one of the most popular of all time. He created some of literature's most iconic characters, with the theme of social reform running throughout his work. The continuing popularity of his novels and short stories is such that they have never gone out of print. ([Source][1].)\n\n[1]:http://en.wikipedia.org/wiki/Charles_Dickens
63	Walter	Scott	1771-08-15	1832-09-21	Sir Walter Scott, 1st Baronet, was a prolific Scottish historical novelist and poet, popular throughout Europe during his time. Scott has been said to be particularly associated with Toryism, though several passages in Tales of a Grandfather display a liberal, progressive and Unionist outlook on Scotland's history.\n\nScott was the first English-language author to have a truly international career in his lifetime, with many contemporary readers in Europe, Australia, and North America. His novels and poetry are still read, and many of his works remain classics of both English-language literature and of Scottish literature. Famous titles include Ivanhoe, Rob Roy, The Lady of The Lake, Waverley, The Heart of Midlothian and The Bride of Lammermoor.\n\n([Source][1])\n\n\n  [1]: http://en.wikipedia.org/wiki/Walter_Scott
79	China	Miéville	1972-09-06	\N	China Tom Miéville (pronounced /ˈtʃaɪnə miˈeɪvəl/; born 6 September 1972 in Norwich) is an award-winning English fantasy fiction writer. He is fond of describing his work as "weird fiction" (after early 20th century pulp and horror writers such as H. P. Lovecraft), and belongs to a loose group of writers sometimes called New Weird who consciously attempt to move fantasy away from commercial, genre clichés of Tolkien epigones. He is also active in left-wing politics as a member of the Socialist Workers Party. He has stood for the House of Commons for the Socialist Alliance, and published a book on Marxism and international law. He teaches creative writing at Warwick University. ([Wikipedia][1])\n\n\n  [1]: http://en.wikipedia.org/wiki/China_Miéville
67	James	Baldwin	1924-08-02	1987-11-30	James Arthur Baldwin was an American novelist, writer, playwright, poet, essayist and civil rights activist. Most of Baldwin's work deals with racial and sexual issues in the mid-20th century in the United States. His novels are notable for the personal way in which they explore questions of identity as well as the way in which they mine complex social and psychological pressures related to being black and homosexual well before the social, cultural or political equality of these groups was improved.\n\nSource and more information: https://en.wikipedia.org/wiki/James_Baldwin
70	Flann	O'Brien	1911-10-05	1966-04-01	Brian O'Nolan was an Irish novelist and satirist, best known for his novels At Swim-Two-Birds and The Third Policeman written under the nom de plume Flann O'Brien. He also wrote the novel An Béal Bocht as well as many satirical columns in the Irish Times under the name Myles na gCopaleen. He was born in Strabane, County Tyrone.\n\nMost of O'Nolan's writings were occasional pieces published in periodicals, which explains why his work has only recently come to enjoy the considered attention of literary scholars. O'Nolan was also notorious for his prolific use and creation of pseudonyms for much of his writing, including short stories, essays, and letters to editors, which has rendered a complete cataloging of his writings an almost impossible task—he allegedly would write letters to the Editor of the Irish Times complaining about his own articles published in that newspaper, for example in his regular Cruiskeen Lawn column, which gave rise to rampant speculation as to whether the author of a published letter existed or not. Not surprisingly, little of O'Nolan's pseudonymous activity has been verified.\n\nA key feature of O'Nolan's personal situation was his status as an Irish government civil servant, who, as a result of his father's relatively early death, was obliged to support ten siblings, including an older brother who was an unsuccessful writer. Given the desperate poverty of Ireland in the 1930s to 1960s, a job as a civil servant was considered prestigious, being both secure and pensionable with a reliable cash income in a largely agrarian economy.\n\nThe Irish civil service has been, since the Irish Civil War, fairly strictly apolitical: Civil Service Regulations and the service’s internal culture generally prohibit Civil Servants above the level of clerical officer from publicly expressing political views. As a practical matter, this meant that writing in newspapers on current events was, during O'Nolan's career, generally prohibited without departmental permission on an article-by-article, publication-by-publication basis. This fact alone contributed to O'Nolan's use of pseudonyms, though he had started to create character-authors even in his pre-civil service writings.\n\nIn reality, that O'Nolan was Flann O'Brien and Myles na gCopaleen was an open secret, largely disregarded by his colleagues, who found his writing very entertaining; this was a function of the makeup of the civil service, which recruited leading graduates by competitive examination—it was an erudite and relatively liberal body in the Ireland of the 1930s to 1970s. Nonetheless, had O'Nolan forced the issue, by using one of his known pseudonyms or his own name for an article that seriously upset politicians, consequences would likely have followed—hence the acute pseudonym problem in attributing his work today.\n\nSource and more information: http://en.wikipedia.org/wiki/Brian_O%27Nolan
80	J. K.	Rowling	1965-07-31	\N	Joanne "Jo" Murray, OBE (née Rowling), better known under the pen name J. K. Rowling, is a British author best known as the creator of the Harry Potter fantasy series, the idea for which was conceived whilst on a train trip from Manchester to London in 1990. The Potter books have gained worldwide attention, won multiple awards, sold more than 400 million copies, and been the basis for a popular series of films.
69	Pearl S.	Buck	1892-06-26	1973-03-06	Pearl S. Buck had always lived in China except for the time she spent in the United States when she was being educated. She studied at Randolph-Macon College and at Cornell University. She taught at the University of Nanking and at the Government University in Nanking under two national regimes. She lived in Nanking during the 1930s.\r\n*The Good Earth* was Mrs. Buck's second published novel. *East Wind: West Wind* appeared under the John Day imprint in 1930. She contributed articles and stories to various magazines, among them *The Atlantic Monthly, The Nation*, and *Asia*.
68	Philip K.	Dick	1928-12-16	1982-03-02	Philip Kindred Dick was an American novelist, short story writer, and essayist whose published work during his lifetime was almost entirely in the science fiction genre. Dick explored sociological, political and metaphysical themes in novels dominated by monopolistic corporations, authoritarian governments, and altered states. In his later works, Dick's thematic focus strongly reflected his personal interest in metaphysics and theology. He often drew upon his own life experiences and addressed the nature of drug abuse, paranoia and schizophrenia, and transcendental experiences in novels such as A Scanner Darkly and VALIS.\r\n\r\nSource and more information: [Wikipedia (EN)](http://en.wikipedia.org/wiki/Philip_K._Dick)
65	William	Gibson	1948-03-17	\N	William Ford Gibson is an American-Canadian writer who has been called the "noir prophet" of the cyberpunk subgenre of science fiction. Gibson coined the term "cyberspace" in his short story "Burning Chrome" and later popularized the concept in his debut novel, *Neuromancer* (1984). In envisaging cyberspace, Gibson created an iconography for the information age before the ubiquity of the Internet in the 1990s. He is also credited with predicting the rise of reality television and with establishing the conceptual foundations for the rapid growth of virtual environments such as video games and the Web. ([Source][1])\r\n\r\n  [1]: http://en.wikipedia.org/wiki/William_Gibson\r\n  [2]: http://www.flickr.com/photos/fredarmitage/1057613629/
66	Tim	O'Brien	1946-10-01	\N	William Timothy O'Brien (born October 1, 1946) is an American novelist. He is best known for his book *The Things They Carried* (1990), a collection of linked semi-autobiographical stories inspired by O'Brien's experiences in the Vietnam War. In 2010, the New York Times described O'Brien's book as a Vietnam classic. In addition, he is known for his war novel, *Going After Cacciato* (1978), also about wartime Vietnam, and later novels about postwar lives of veterans.\r\n\r\nO'Brien has held the endowed chair at the MFA program of Texas State University–San Marcos every other academic year since 2003–2004 (2003–2004, 2005–2006, 2007–2008, 2009–2010, and 2011–2012). \r\n\r\nSource: https://en.wikipedia.org/wiki/Tim_O%27Brien_(author)
71	Wilkie	Collins	1824-01-08	1889-09-23	William Wilkie Collins (8 January 1824 – 23 September 1889) was an English novelist, playwright and short story writer best known for *The Woman in White* (1859) and *The Moonstone* (1868). The last has been called the first modern English detective novel. Born to the family of a painter, William Collins, in London, he grew up in Italy and France, learning French and Italian. He began work as a clerk for a tea merchant. After his first novel, Antonina, appeared in 1850, he met Charles Dickens, who became a close friend and mentor. Some of Collins's works appeared first in Dickens's journals *All the Year Round* and *Household Words* and they collaborated on drama and fiction. Collins achieved financial stability and an international following with his best known works in the 1860s, but began suffering from gout. Taking opium for the pain grew into an addiction. In the 1870s and 1880s his writing quality declined with his health. Collins was critical of the institution of marriage: he split his time between Caroline Graves and his common-law wife Martha Rudd, with whom he had three children.\n\n**Source**: [Wilkie Collins](https://en.wikipedia.org/wiki/Wilkie_Collins) on Wikipedia.
72	Paulo	Coelho	1947-08-24	\N	Paulo Coelho, born and raised in Rio de Janeiro, Brazil, is a Brazilian novelist known for employing rich symbolism in his depictions of the often spiritually motivated journeys taken by his characters. Coelho dropped out of law school in 1970 and traveled through South America, Mexico, North Africa, and Europe. In 1972 he returned home and began writing pop and rock music lyrics with Raul Seixas, a well-known Brazilian singer and songwriter. He worked for Polygram and CBS Records until 1980, when he embarked on new travels in Europe and Africa.\n\nIt was during this trip that he walked the route of Santiago de Compostela, which formed the basis of his first book, *O diário de um mago* (1987), which was published in English as *The Diary of a Magus* in 1992 and was reissued as *The Pilgrimage* in 1995. In 1988 Coelho published *O alquimista* (*The Alchemist*), which ultimately became an international best-seller. His other notable works include *The Valkyries*, *Eleven Minutes*, *Manual of The Warrior of Light*, *Manuscript Found in Accra*, *The Devil and Miss Prym*, *The Fifth Mountain*, *Veronika Decides to Die*, and *The Zahir*.\n\nSource: [Britannica](https://www.britannica.com/biography/Paulo-Coelho)
74	Stephen	Hawking	1942-01-08	2018-03-14	A British theoretical physicist and cosmologist. Researcher & explorer of black holes and the space-time continum.
76	Terry	Pratchett	1948-04-28	2015-03-12	Sir Terence David John Pratchett, OBE more commonly known as Terry Pratchett, was an English novelist, known for his frequently comical work in the fantasy genre. He is best-known for his popular and long-running Discworld series of comic fantasy novels. Pratchett's first novel, *The Carpet People*, was published in 1971, and since his first Discworld novel (*The Colour of Magic*) was published in 1983, he has written two books a year on average.\n\nPratchett was the UK's best-selling author of the 1990s, and as of December 2007 had sold more than 55 million books worldwide, with translations made into 36 languages.\n\nHe is currently the second most-read writer in the UK, and seventh most-read non-US author in the US. In 2001 he won the Carnegie Medal for his young adult novel *The Amazing Maurice and his Educated Rodents*.
77	Susanna	Clarke	1959-11-01	\N	Susanna Mary Clarke (born 1 November 1959) is an English author known for her debut novel *Jonathan Strange & Mr Norrell* (2004), a Hugo Award-winning alternative history. Clarke began *Jonathan Strange* in 1993 and worked on it during her spare time. For the next decade, she published short stories from the *Strange* universe, but it was not until 2003 that Bloomsbury bought her manuscript and began work on its publication. The novel became a best-seller. \n\n**Source**: [Susanna Clarke](https://en.wikipedia.org/wiki/Susanna_Clarke) on Wikipedia.
78	Neil	Gaiman	1960-11-10	\N	Neil Richard MacKinnon Gaiman born Neil Richard Gaiman, 10 November 1960) is an English author of short fiction, novels, comic books, graphic novels, audio theatre, and films. His notable works include the comic book series The Sandman and novels Stardust, American Gods, Coraline, and The Graveyard Book. He has won numerous awards, including the Hugo, Nebula, and Bram Stoker awards, as well as the Newbery and Carnegie medals. He is the first author to win both the Newbery and the Carnegie medals for the same work, The Graveyard Book (2008). In 2013, The Ocean at the End of the Lane was voted Book of the Year in the British National Book Awards.
108	Lyanda Lynn	Haupt	\N	\N	\N
75	Thomas	Malory	\N	\N	English writer, author of ''Le Morte d'Arthur''
82	Robert	Jordan	1948-10-17	2007-09-16	James Oliver Rigney, Jr., better known by his pen name Robert Jordan, was an American author of epic fantasy. He is best known for The Wheel of Time series, which comprises 14 books and a prequel novel. He is one of the several writers who have written 7 original Conan the Barbarian novels that are highly acclaimed to this day. Rigney also wrote historical fiction under his pseudonym Reagan O'Neal, a western as Jackson O'Reilly, and dance criticism as Chang Lung. Additionally, he ghostwrote an "international thriller" that is still believed to have been written by someone else. \n- Wikipedia
83	Richard	Adams	1920-05-09	2016-12-24	Richard Adams was born in Berkshire, England, in 1920, and studied history at Bradfield and Worcester College, Oxford. He is the author of nineteen books, including the bestselling and award-winning *Watership Down*, his first book.
84	Jacqueline	Carey	1964-10-09	\N	American writer, primarily of fantasy fiction.
85	Glen	Cook	1944-07-09	\N	Glen Cook was born in New York City.  He began writing in grade school, and in high school he wrote for his school's newspaper.  After high school, he spent time in the United States Navy and later worked his way through college, leaving little time for writing.  In 1970 he attended the Clarion Writer's Workshop and began his writing career.  At the same time he worked at a General Motors light truck assembly plant, a second occupation he kept until his retirement from GM.  His first published novel, The Heirs of Babylon, was published in 1973.  He is best know for three fantasy fiction series, the Black Company series about an elite mercenary unit, and the Garrett P.I. series, about a hardboiled detective Garrett.  He lives with his wife, Carol, in St. Louis, Missouri.
86	Terry	Brooks	1944-01-08	\N	Terence Dean Brooks (born January 8, 1944) is an American writer of fantasy fiction. He writes mainly epic fantasy, and has also written two movie novelizations. He has written 23 New York Times bestsellers during his writing career, and has over 21 million copies of his books in print. He is one of the biggest-selling living fantasy writers.
88	Roald	Dahl	\N	\N	Roald Dahl was a British novelist, short story writer, and screenwriter.\n\nBorn in north Cardiff, Wales, to Norwegian parents, Dahl served in the Royal Air Force during the Second World War, in which he became a flying ace and intelligence agent. He rose to prominence in the 1940s with works for both children and adults, and became one of the world's bestselling authors. His short stories are known for their unexpected endings, and his children's books for their unsentimental, often very dark humour. ([Source][1].)\n\n\n  [1]: http://en.wikipedia.org/wiki/Roald_Dahl
90	Vonda N.	McIntyre	1948-08-28	2019-04-01	Vonda N. McIntyre was raised on the east coast of the United States and in The Hague, Netherlands, and then in Seattle in the early 1960s. In 1970 she earned a biology degree from the University of Washington. She also attended the Clarion Writers Workshop. She went to the University of Washington to pursue a master's degree in genetics.\n\nIn 1973, McIntyre won a Nebula Award for the novelette "Of Mist, and Grass, and Sand". In 1975, her first novel, *The Exile Waiting*, was published. She has also written several Star Trek and Star Wars novels.\n\nVonda McIntyre died at her home in Seattle, Washington of pancreatic cancer on April 1, 2019, aged 70.
91	Samantha	Shannon	1991	\N	British author of dystopian and fantasy fiction.
92	Leigh	Bardugo	1975-04-06	\N	Leigh was born in Jerusalem, grew up in Southern California, and graduated from Yale University. These days she lives and writes in Los Angeles. \n([source][1])\n\n\n  [1]: https://www.leighbardugo.com/about/
87	Madeline	Miller	1978-07-24	\N	Madeline Miller was born in Boston and grew up in New York City and Philadelphia. She attended Brown University, where she earned her BA and MA in Classics. For the last ten years she has been teaching and tutoring Latin, Greek and Shakespeare to high school students. She also studied in the Dramaturgy department at Yale School of Drama, where she focused on the adaptation of classical texts to modern forms. She currently lives near Philadelphia, PA.
94	Patricia A.	McKillip	1948	\N	Patricia Anne McKillip is an American author of fantasy and science fiction novels. She grew up in Oregon and England.  She received a BA in English in 1971 and an MA in 1973.  She is a past winner of the World Fantasy Award and Locus Award, and she lives in Oregon. \n\nMcKillip's stories usually take place in a setting similar to the Middle Ages. There are forests, castles, and lords or kings, minstrels, tinkers and wizards. Her writing usually puts her characters in situations involving mysterious powers that they don't understand.
95	Anne	Rice	1941-10-04	2021	Anne Rice was born on 04 October 1941 in New Orleans, Louisiana, USA. She was the second of four daughters of Irish Catholic parents, Katherine "Kay" Allen and Howard O'Brien. In 1961, she married Stan Rice, who passed away in 2002. They had two children, Christopher (1978) and Michele (1966-1972). She started to published in 1970s, and became a published phenomenon. Her books have sold nearly 100 million copies, making her one of the most widely read authors in modern history.
96	Susan	Cooper	1935	\N	Susan Mary Cooper (born 23 May 1935) is an English author of children's books. She is best known for The Dark Is Rising, a contemporary fantasy series set in England and Wales, which incorporates British mythology, such as the Arthurian legends, and Welsh folk heroes. For that work, in 2012 she won the lifetime Margaret A. Edwards Award from the American Library Association, recognizing her contribution to writing for teens. In the 1970s two of the five novels were named the year's best English-language book with an "authentic Welsh background" by the Welsh Books Council. [Wikipedia]
97	Robert M.	Sapolsky	1957	\N	Robert Maurice Sapolsky (born 1957) is an American scientist and author. He is currently professor of Biological Sciences, and Professor of Neurology and Neurological Sciences, and by courtesy, Neurosurgery, at Stanford University. In addition, he is a research associate at the National Museums of Kenya.\n--From Wikipedia
98	Adam	Higginbotham	1968	\N	Author and journalist in New York City.
99	Randall	Munroe	1984-10-17	\N	Randall Patrick Munroe (born October 17, 1984) is an American cartoonist, author, engineer, scientific theorist, and the creator of the webcomic xkcd. He and the webcomic have developed a large fanbase, and shortly after graduating from college, he became a professional webcomic artist.\n\n**Source**: [Randall Munroe](https://en.wikipedia.org/wiki/Randall_Munroe) on Wikipedia.
103	Daniel	Kahneman	1934-03-05	2024	Israeli-American psychologist and economist notable for his work on the psychology of judgment and decision-making, as well as behavioral economics.
105	Stephen E	Ambrose	1936-01-10	2002-10-13	Stephen Edward Ambrose was an American historian and biographer of U.S. Presidents Dwight D. Eisenhower and Richard Nixon. He was a longtime professor of history at the University of New Orleans and the author of many best selling volumes of American popular history.\n\n**Source**: [Stephen E. Ambrose](https://en.wikipedia.org/wiki/Stephen_E._Ambrose) on Wikipedia.
100	Erich	Gamma	\N	\N	\N
93	Markus	Zusak	1975	\N	Markus Zusak was born in 1975 and is the author of five books, including the international bestseller, The Book Thief, which is translated into more than forty languages. First released in 2005, The Book Thief has spent more than a decade on the New York Times bestseller list, and still remains there to this day.\r\n\r\nsource: http://www.zusakbooks.com
111	Mihaly	Csikszentmihalyi	1934	2021	Hungarian psychologist Mihaly Csikszentmihalyi was the Distinguished Professor of Psychology and Management at Claremont Graduate University. He is noted for his work in the study of happiness and creativity, but is best known as the architect of the notion of flow, a highly focused mental state. \n\nMartin Seligman, former president of the American Psychological Association, described Csikszentmihalyi as the world's leading researcher on positive psychology.\n\nCsikszentmihalyi once said: "Repression is not the way to virtue. When people restrain themselves out of fear, their lives are by necessity diminished. Only through freely chosen discipline can life be enjoyed and still kept within the bounds of reason." (Wikipedia)
112	Daniel	Brown	1951	\N	Daniel James Brown is a technical writer and editor and writer of narrative nonfiction.
113	Robert	Kurson	\N	\N	Robert Kurson is the author of four New York Times bestsellers, including his 2004 debut, Shadow Divers, the true story of two Americans who discovered a World War II German U-boat sunk 60 miles off the coast of New Jersey. Kurson began his career as an attorney, graduating from Harvard Law School and practicing real estate law. Kurson’s professional writing career began at the Chicago Sun-Times, where he started as a data entry clerk. In 2000, Esquire published “My Favorite Teacher,” his first magazine story, which became a finalist for a National Magazine Award. He moved from the Sun-Times to Chicago Magazine, then to Esquire, where he won a National Magazine Award and was a contributing editor for years. His other New York Times bestsellers include Crashing Through (2007), Pirate Hunters (2015), and his latest, Rocket Men (2018), which tells the astonishing story of Apollo 8, mankind’s first journey to the Moon. He lives in Chicago.\n([source][1])\n\n\n  [1]: https://www.robertkurson.com/about/
114	Malcolm	Gladwell	1963-09-03	\N	Malcolm Timothy Gladwell is an English-born Canadian journalist, bestselling author, and speaker. He has been a staff writer for The New Yorker since 1996.
115	Neil deGrasse	Tyson	1958-10-05	\N	Born in Manhattan, New York, he earned his doctorate in astrophysics in 1991 from Columbia University. He is best known in the popular media as the host of "Origins" a mini series on PBS and "Cosmos: A Spacetime Odyssey" on FOX television network and the National Geographic channel on cable TV.
117	Jeannette	Walls	1960-04-21	\N	Jeannette Walls is a writer and journalist. Born in Phoenix, Arizona, she graduated with honors from Barnard College, the women's college affiliated with Columbia University.
118	Siddhartha	Mukherjee	1970	\N	Siddhartha Mukherjee (born 21 July 1970) is an Indian-American physician, biologist, oncologist, and author.
119	Dave	Eggers	1970-03-12	\N	Dave Eggers is the author of six previous books, including his most recent, Zeitoun, a nonfiction account of a Syrian-American immigrant and his extraordinary experience during Hurricane Katrina and What Is the What, a finalist for the 2006 National Book Critics Circle Award. That book, about Valentino Achak Deng, a survivor of the civil war in southern Sudan, gave birth to the Valentino Achak Deng Foundation, run by Mr. Deng and dedicated to building secondary schools in southern Sudan. Eggers is the founder and editor of McSweeney’s, an independent publishing house based in San Francisco that produces a quarterly journal, a monthly magazine (The Believer), and Wholphin, a quarterly DVD of short films and documentaries. In 2002, with Nínive Calegari he co-founded 826 Valencia, a nonprofit writing and tutoring center for youth in the Mission District of San Francisco. Local communities have since opened sister 826 centers in Chicago, Los Angeles, Brooklyn, Ann Arbor, Seattle, and Boston. In 2004, Eggers taught at the University of California-Berkeley Graduate School of Journalism, and there, with Dr. Lola Vollen, he co-founded Voice of Witness, a series of books using oral history to illuminate human rights crises around the world. A native of Chicago, Eggers graduated from the University of Illinois with a degree in journalism. He now lives in the San Francisco Bay Area with his wife and two children.\n\n[Source][1]\n\n\n  [1]: http://www.mcsweeneys.net/pages/about-dave-eggers
154	Philip A.	Roth	1933	2018	American novelist and satirist.
157	John	Milton	1608-12-09	1674-11-08	John Milton was an English poet, author, polemicist and civil servant for the Commonwealth of England. He is best known for his epic poem Paradise Lost. \n([Source][1].)\n\n\n[1]: http://en.wikipedia.org/wiki/John_Milton
120	Walter	Isaacson	1952-05-20	\N	Walter Isaacson, the CEO of the Aspen Institute, has been chairman of CNN and the managing editor of Time magazine. He is the author of Steve Jobs; Einstein: His Life and Universe; Benjamin Franklin: An American Life; and Kissinger: A Biography, and the coauthor of The Wise Men: Six Friends and the World They Made. He lives in Washington, DC.\n[(Source)][1]\n\n\n  [1]: http://authors.simonandschuster.com/Walter-Isaacson/697650
121	Douglas J.	Preston	1956-05-31	\N	American journalist and author.
122	Christopher	McDougall	1962	\N	Trained as a foreign correspondent for the Associated Press, Christopher McDougall covered wars in Rwanda and Angola before writing his international bestseller, Born to Run. His fascination with the limits of human potential led him to create the Outside magazine web series, “Art of the Hero.”\n--chrismcdougall.com
123	Paul	Kalanithi	1977-04-01	2015-03-09	Paul Sudhir Arul Kalanithi (April 1, 1977 – March 9, 2015) was an American neurosurgeon and writer. His book When Breath Becomes Air is a memoir about his life and illness with stage IV metastatic lung cancer. It was posthumously published by Random House in January 2016.
126	Rebecca	Skloot	1972-09-19	\N	Rebecca Skloot is an award winning science writer whose work has appeared in The New York Times Magazine; O, The Oprah Magazine; Discover; and many other publications. She specializes in narrative science writing and has explored a wide range of topics, including goldfish surgery, tissue ownership rights, race and medicine, food politics, and packs of wild dogs in Manhattan. She has worked as a correspondent for WNYC’s Radiolab and PBS’s Nova ScienceNOW.\n\nSource: Goodreads.com
127	Simon	Singh	1964-09-19	\N	Simon Lehna Singh, MBE is a British popular science author, theoretical and particle physicist.
129	S. E	Hinton	1950-07-22	\N	Susan Eloise Hinton published her first book, *The Outsiders*, at the age of 17. Her publisher suggested she publish under her initials instead of her feminine so that book reviewers would not dismiss the novel because its author was female, and she continued to publish using her initials because of the success of her first book and because she did not want to be famous.\n\nIn 1979, Hinton was the first recipient of the Margaret Edwards Award, presented by the Young Adult Library Services Association, a division of the ALA for work which depicts the experiences and emotions of teenagers and is widely accepted by young people. That same year, The Outsiders was named best novel by the New York Times in 1979.\n\nHinton currently resides in Tulsa, Oklahoma with her husband.
131	Mark	Haddon	1962-09-26	\N	English writer and illustrator.
134	Shirley	Jackson	1916-12-14	1965-08-08	Shirley Hardie Jackson (December 14, 1916 – August 8, 1965) was an American writer, known primarily for her works of horror and mystery.\n\n**Source**: [Shirley Jackson](https://en.wikipedia.org/wiki/Shirley_Jackson) on Wikipedia.
135	Scott	Turow	1949-04-12	\N	Scott Frederick Turow (born April 12, 1949) is an American author and lawyer.
155	Tina	Fey	1970-05-18	\N	An American actress, comedian, writer and producer.
124	Stephanie	Foo	\N	\N	\N
128	Seth M.	Siegel	\N	\N	\N
130	Anthony	Brandt	\N	\N	\N
132	Erin	Kelly	1976	\N	\N
133	Maureen	Johnson	1973	\N	Author of children's literature.
125	Bryan	Stevenson	\N	\N	Bryan Stevenson is the executive director of the Equal Justice Initiative in Montgomery, Alabama, and a professor of law at New York University School of Law. He has won relief for dozens of condemned prisoners, argued five times before the Supreme Court, and won national acclaim for his work challenging bias against the poor and people of color. He has received numerous awards, including the MacArthur Foundation “Genius” Grant.\r\n\r\nSource: http://bryanstevenson.com/the-author/
137	Agatha	Christie	1890-09-15	1976-01-12	Agatha Mary Clarissa Miller was born in Torquay, Devon, in the United Kingdom, the daughter of a wealthy American stockbroker. Her father died when she was eleven years old. Her mother taught her at home, encouraging her to write at a very young age. At the age of 16, she went to Mrs. Dryden's finishing school in Paris to study singing and piano. In 1914, at age 24, she married Colonel Archibald Christie, an aviator in the Royal Flying Corps. While he went away to war, she worked as a nurse and wrote her first novel, The Mysterious Affair at Styles (1920), which wasn't published until four years later. When her husband came back from the war, they had a daughter. In 1928 she divorced her husband, who had been having an affair. In 1930, she married Sir Max Mallowan, an archaeologist and a Catholic. She was happy in the early years of her second marriage, and did not divorce her husband despite his many affairs. She travelled with her husband's job, and set several of her novels set in the Middle East. Most of her other novels were set in a fictionalized Devon, where she was born.\n\nAgatha Christie is credited with developing the "cozy style" of mystery, which became popular in, and ultimately defined, the Golden Age of fiction in England in the 1920s and '30s, an age of which she is considered to have been Queen. In all, she wrote over 66 novels, numerous short stories and screenplays, and a series of romantic novels using the pen name Mary Westmacott. She was the single most popular mystery writer of all time. In 1971 she was made a Dame Commander of the Order of the British Empire.
138	Gillian	Flynn	1971-02-24	\N	Flynn, who lives in Chicago, grew up in Kansas City, Missouri. She graduated at the University of Kansas, and qualified for a Master's degree from Northwestern University.
139	Stieg	Larsson	1954-08-15	2004-11-09	Lisbeth Salander is wanted for a triple murder. All three victims are connected to a trafficking expose about to be published in Mikael Blomqvists magazine Millenium, and Lisbeths fingerprints are on the weapon.\n\nLisbeth vanishes to avoid capture by the justice. Mikael, not believing the police, is despairingly trying to clear her name, using all his resources and the staff of his magazine. During this process, Mikael discovers Lisbeths past, a terrible story of abuse and traumatizing experiences growing up in the Swedish care system.\n\nWhen he eventually finds her, it’s only to discover that she is far more entangled in his initial investigation of the sex industry than he could ever imagine.\n([source][1])\n\n\n  [1]: http://stieglarsson.com/the-girl-who-played-with-fire/
140	John	Grisham	1955-02-08	\N	Long before his name became synonymous with the modern legal thriller, he was working 60-70 hours a week at a small Southaven, Mississippi, law practice, squeezing in time before going to the office and during courtroom recesses to work on his hobby—writing his first novel.\n\nBorn on February 8, 1955 in Jonesboro, Arkansas, to a construction worker and a homemaker, John Grisham as a child dreamed of being a professional baseball player. Realizing he didn’t have the right stuff for a pro career, he shifted gears and majored in accounting at Mississippi State University. After graduating from law school at Ole Miss in 1981, he went on to practice law for nearly a decade in Southaven, specializing in criminal defense and personal injury litigation. In 1983, he was elected to the state House of Representatives and served until 1990.\n\nOne day at the DeSoto County courthouse, Grisham overheard the harrowing testimony of a twelve-year-old rape victim and was inspired to start a novel exploring what would have happened if the girl’s father had murdered her assailants. Getting up at 5 a.m. every day to get in several hours of writing time before heading off to work, Grisham spent three years on A Time to Kill and finished it in 1987. Initially rejected by many publishers, it was eventually bought by Wynwood Press, who gave it a modest 5,000 copy printing and published it in June 1988.\n\nThat might have put an end to Grisham’s hobby. However, he had already begun his next book, and it would quickly turn that hobby into a new full-time career—and spark one of publishing’s greatest success stories. The day after Grisham completed A Time to Kill, he began work on another novel, the story of a hotshot young attorney lured to an apparently perfect law firm that was not what it appeared. When he sold the film rights to The Firm to Paramount Pictures for $600,000, Grisham suddenly became a hot property among publishers, and book rights were bought by Doubleday. Spending 47 weeks on The New York Times bestseller list, The Firm became the bestselling novel of 1991.\n\nThe successes of The Pelican Brief, which hit number one on the New York Times bestseller list, and The Client, which debuted at number one, confirmed Grisham’s reputation as the master of the legal thriller. Grisham’s success even renewed interest in A Time to Kill, which was republished in hardcover by Doubleday and then in paperback by Dell. This time around, it was a bestseller.\n\nSince first publishing A Time to Kill in 1988, Grisham has written one novel a year (his other books are The Firm, The Pelican Brief, The Client, The Chamber, The Rainmaker, The Runaway Jury, The Partner, The Street Lawyer, The Testament, The Brethren, A Painted House, Skipping Christmas, The Summons, The King of Torts, Bleachers, The Last Juror, The Broker, Playing for Pizza, The Appeal, and The Associate) and all of them have become international bestsellers. There are currently over 250 million John Grisham books in print worldwide, which have been translated into 29 languages. Nine of his novels have been turned into films (The Firm, The Pelican Brief, The Client, A Time to Kill, The Rainmaker, The Chamber, A Painted House, The Runaway Jury, and Skipping Christmas), as was an original screenplay, The Gingerbread Man. The Innocent Man (October 2006) marked his first foray into non-fiction, and Ford County (November 2009) was his first short story collection.\n\nGrisham lives with his wife Renee and their two children Ty and Shea. The family splits their time between their Victorian home on a farm in Mississippi and a plantation near Charlottesville, VA.\n\nGrisham took time off from writing for several months in 1996 to return, after a five-year hiatus, to the courtroom. He was honoring a commitment made before he had retired from the law to become a full-time writer: representing the family of a railroad brakeman killed when he was pinned between two cars. Preparing his case with the same passion and dedication as his books’ protagonists, Grisham successfully argued his clients’ case, earning them a jury award of $683,500—the biggest verdict of his career.\n\nWhen he’s not writing, Grisham devotes time to charitable causes, including most recently his Rebuild The Coast Fund, which raised 8.8 million dollars for Gulf Coast relief in the wake of Hurricane Katrina. He also keeps up with his greatest passion: baseball. The man who dreamed of being a professional baseball player now serves as the local Little League commissioner. The six ballfields he built on his property have played host to over 350 kids on 26 Little League teams.
142	James	Ellroy	1948-03-04	\N	Lee Earle "James" Ellroy is an American crime fiction writer and essayist. Ellroy has become known for a telegrammatic prose style in his most recent work, wherein he frequently omits connecting words and uses only short, staccato sentences, and in particular for the novels *The Black Dahlia* (1987), *The Big Nowhere* (1988), *L.A. Confidential* (1990), *White Jazz* (1992), *American Tabloid* (1995), *The Cold Six Thousand* (2001), and *Blood's a Rover* (2009). *-- Wikipedia*
144	Ali	Hazelwood	\N	\N	Italian neuroscientist and writer of romance novels.
146	Lisa	Kleypas	1964	\N	Lisa Kleypas is the author of sixteen historical romance novels that have been published in twelve languages. After graduating from Wellesley College with a political science degree, she published her first novel at the age twenty-one. Her books have appeared on many bestseller lists, including the New York Times and Publishers Weekly. Lisa lives in Texas with her husband, Gregory, and their two children, Griffin and Lindsay.
151	Halldór	Laxness	1902	1998	Icelandic author of satirical works.
152	Stella	Gibbons	1902-01-05	1989-12-19	Humorist author and social satirist.
153	Paul	Murray	1975	\N	Irish novelist who authored the novels An Evening of Long Goodbyes, Skippy Dies, The Mark and the Void, and The Bee Sting.
145	Colleen	Hoover	1979-12-11	\N	Colleen Hoover is the #1 New York Times and International bestselling author of multiple novels and novellas. She lives in Texas with her husband and their three boys. She is the founder of The Bookworm Box, a non-profit book subscription service and bookstore in Sulphur Springs, Texas.
159	T. S.	Eliot	1888-09-26	1965-01-04	T[homas]. S[tearns]. Eliot was an American poet, playwright, and literary critic, arguably the most important English-language poet of the 20th century.[3] His first notable publication, The Love Song of J. Alfred Prufrock, begun in February 1910 and published in Chicago in June 1915, is regarded as a masterpiece of the modernist movement.[4] It was followed by some of the best-known poems in the English language, including Gerontion (1920), The Waste Land (1922), The Hollow Men (1925), Ash Wednesday (1930), Old Possum's Book of Practical Cats (1939), and Four Quartets (1945). He is also known for his seven plays, particularly Murder in the Cathedral (1935) and The Cocktail Party (1949). He was awarded the Nobel Prize in Literature and the Order of Merit in 1948.  ([Source][1].)\n\n\n[1]:https://en.wikipedia.org/wiki/T._S._Eliot
161	Leonard	Cohen	1934-09-21	2016-11-07	Canadian poet and singer-songwriter.
163	C. S.	Forester	1899-08-27	1966-04-02	Cecil Scott Forester, an Englishman, was born in Cairo in 1899, the son of a British army officer. He was educated in London, and for a time he studied medicine. After a World War I stint in the infantry, however, he decided to be a poet. This was a shortlived pursuit and he soon turned to biography and fiction. He then wrote many best-selling novels—African Queen and The General among them—before he wrote the first of his Hornblower stories in 1937. That first book was Beat to Quarters, chronologically the fifth volume in tracing the career of Hornblower. In 1940 Forester moved to Berkeley, California, where he lived for many years between his World War II and postwar travels. In April of 1966, while writing Hornblower and the Crisis, C. S. Forester died. Today, the popularity of his writing still continues to grow, and the names of both Forester and Hornblower have become synonymous with the greatest names in naval literature.
164	James	Hilton	1900-09-09	1954-12-20	James Hilton was an English novelist best remembered for several best-sellers, including Lost Horizon and Goodbye, Mr. Chips. He also wrote Hollywood screenplays.\nSource: Wikipedia
166	Laura	Hillenbrand	1967-05-15	\N	Laura Hillenbrand is an American author of books and magazine articles. Her two best-selling nonfiction books, Seabiscuit: An American Legend and Unbroken: A World War II Story of Survival, Resilience, and Redemption have sold over 10 million copies, and each was adapted for film.\n\nSource: Wikipedia
168	David G.	McCullough	1933-07-07	2022	David Gaub McCullough has been widely acclaimed as a “master of the art of narrative history.” He is twice winner of the Pulitzer Prize, twice winner of the National Book Award, and has received the Presidential Medal of Freedom, the nation’s highest civilian award.
170	Richard Phillips	Feynman	1918	1988	Richard Phillips Feynman was an American theoretical physicist known for his work in the path integral formulation of quantum mechanics, the theory of quantum electrodynamics, and the physics of the superfluidity of supercooled liquid helium, as well as in particle physics for which he proposed the parton model. For his contributions to the development of quantum electrodynamics, Feynman, jointly with Julian Schwinger and Sin-Itiro Tomonaga, received the Nobel Prize in Physics in 1965.\n- Wikipedia
171	Bill	Bryson	1951-12-08	\N	"William McGuire "Bill" Bryson is a best-selling Anglo-American author of humorous books on travel, as well as books on the English language and science." - Wikipedia
160	Lawrence	Ferlinghetti	\N	\N	\N
162	W. H	Hudson	1841	1922	\N
165	Anthony	Hope	1863	1933	\N
169	Edmund	Morris	\N	\N	\N
172	Ruth	Wariner	\N	\N	\N
173	Ted	Kerasote	\N	\N	\N
174	Amanda	Lindhout	\N	\N	\N
167	Trevor	Noah	1984-02-20	\N	Trevor Noah is a South African comedian, television host, writer, producer, political commentator, and actor.
175	Frank	McCourt	1930-08-19	2009-07-19	Francis "Frank" McCourt was an Irish-American teacher and author. McCourt was born in Brooklyn; however, his family returned to their native Ireland in 1934.\n\nHe received the Pulitzer Prize (1997) and National Book Critics Circle Award (1996) for his memoir Angela's Ashes (1996), which details his childhood as a poor Irish Catholic in Limerick. He is also the author of 'Tis (1999), which continues the narrative of his life, picking up from the end of the previous book and focusing on life as a new immigrant in America. Teacher Man (2005), detailed the challenges of being a young, uncertain teacher who must impart knowledge to his students. His works are often part of the syllabus in high schools. In 2002 he was awarded an honorary degree from the University of Western Ontario. He died of melanoma, the deadliest form of skin cancer, at the age of 78.\n\nSource: Goodreads.com
176	Temple	Grandin	1947-08-29	\N	An American doctor of animal science and professor at Colorado State University, bestselling author, and consultant to the livestock industry on animal behavior.
182	Mark	Twain	1835-11-30	1910-04-21	Mark Twain, born Samuel Langhorne Clemens, was a prolific American author and humorist. Twain is best known for his novels Adventures of Huckleberry Finn  (1884), which has been called "the Great American Novel", and The Adventures of Tom Sawyer  (1876). He is extensively quoted. Twain was a friend to presidents, artists, industrialists, and European royalty. ([Source][1].) \n\n[1]:http://en.wikipedia.org/wiki/Mark_Twain
184	Vladimir Vladimirovich	Nabokov	1899-04-22	1977-07-02	Vladimir Vladimirovich Nabokov (Russian: Влади́мир Влади́мирович Набо́ков; 23 April [O.S. 10 April] 1899c – 2 July 1977) was a multilingual Russian-American novelist and short story writer. Nabokov wrote his first nine novels in Russian, then rose to international prominence as a master English prose stylist. He also made contributions to entomology and had an interest in chess problems.\n\nNabokov's *Lolita* (1955) is frequently cited as among his most important novels and is his most widely known, exhibiting the love of intricate word play and synesthetic detail that characterised all his works. The novel was ranked at #4 in the list of the Modern Library 100 Best Novels. *Pale Fire* (1962) was ranked at #53 on the same list. His memoir entitled *Speak, Memory* was listed #8 on the Modern Library nonfiction list. ([Source][1].)\n\n[1]:https://en.wikipedia.org/wiki/Vladimir_Nabokov
185	Julia	Child	1912-08-15	2004-08-13	Julia Carolyn Child was an American chef, author, and television personality. She is recognized for bringing French cuisine to the American public with her debut cookbook, Mastering the Art of French Cooking, and her subsequent television programs, the most notable of which was The French Chef, which premiered in 1963.\n(Wikipedia, Julia Child)
187	Willie	Nelson	1933	\N	\N
188	Thomas	Merton	1915	1968	Thomas Merton (January 31, 1915 – December 10, 1968) was a 20th century American Catholic writer. A Trappist monk of the Abbey of Gethsemani, Kentucky, he was a poet, social activist and student of comparative religion. In 1949, he was ordained to the priesthood and given the name Father Louis.\n\nMerton wrote more than 70 books, mostly on spirituality, social justice and a quiet pacifism, as well as scores of essays and reviews, including his best-selling autobiography, The Seven Storey Mountain (1948), which sent scores of disillusioned World War II veterans, students, and even teen-agers flocking to monasteries across US, and was also featured in National Review's list of the 100 best non-fiction books of the century.\n\nMerton was a keen proponent of interfaith understanding. He pioneered dialogue with prominent Asian spiritual figures, including the Dalai Lama, D.T. Suzuki, the Japanese writer on the Zen tradition, and the Vietnamese monk Thich Nhat Hanh. Merton has also been the subject of several biographies.
191	Andy	Weir	1972-06-16	\N	Andy Weir built a career as a software engineer until the success of his first published novel, THE MARTIAN, allowed him to live out his dream of writing fulltime. He is a lifelong space nerd and a devoted hobbyist of subjects such as relativistic physics, orbital mechanics, and the history of manned spaceflight. He also mixes a mean cocktail. He lives in California.
178	Dumas	Malone	1892	1986	\N
179	Allan W.	Eckert	\N	\N	\N
199	Carl	Sagan	1934-11-09	1996-12-20	Carl Sagan was an American Pulitzer-prize winning author and astrophysicist. Sagan is the author of more than 600 publications.
192	Neal	Stephenson	1959-10-31	\N	Neal Town Stephenson (born October 31, 1959) is an American writer and game designer known for his works of speculative fiction. His novels have been categorized as science fiction, historical fiction, cyberpunk, postcyberpunk, and baroque.\r\n\r\nStephenson's work explores subjects such as mathematics, cryptography, linguistics, philosophy, currency, and the history of science. He also writes non-fiction articles about technology in publications such as *Wired*. He has also written novels with his uncle, George Jewsbury ("J. Frederick George"), under the collective pseudonym Stephen Bury.\r\n\r\nStephenson has worked part-time as an advisor for Blue Origin, a company (funded by Jeff Bezos) developing a manned sub-orbital launch system, and is also a cofounder of Subutai Corporation, whose first offering is the interactive fiction project *The Mongoliad*. He is currently Magic Leap's Chief Futurist.
193	Michael	Crichton	1942-10-23	2008-11-04	An American writer and filmmaker.
197	Alfred	Bester	1913-12-18	1987-09-30	Alfred Bester was an American science fiction author, TV and radio scriptwriter, magazine editor and scripter for comic strips and comic books. Though successful in all these fields, he is best remembered for his science fiction, including The Demolished Man, winner of the inaugural Hugo Award in 1953. - Wikipedia
198	Dan	Simmons	1948-04-04	\N	Dan Simmons (born April 4, 1948) is an American science fiction and horror writer. He is the author of the *Hyperion Cantos* and the *Ilium*/*Olympos* cycles, among other works which span the science fiction, horror, and fantasy genres, sometimes within a single novel. A typical example of Simmons' intermingling of genres is *Song of Kali* (1985), winner of the World Fantasy Award. He also writes mysteries and thrillers, some of which feature the continuing character Joe Kurtz.\n\n**Source**: [Dan Simmons](https://en.wikipedia.org/wiki/Dan_Simmons) on Wikipedia.
200	Iain M.	Banks	1954-02-16	2013-06-09	Iain Banks was a Scottish author. He wrote mainstream fiction under the name Iain Banks and science fiction (including the popular [The Culture](https://openlibrary.org/subjects/series:imb_the_culture) series) as Iain M. Banks. In 2008, *The Times* named Banks in their list of "The 50 greatest British writers since 1945". *--Wikipedia*
201	Anthony	Doerr	1973	\N	Anthony Doerr was born and raised in Cleveland, Ohio. He is the author of the story collections The Shell Collector and Memory Wall, the memoir Four Seasons in Rome, and the novels About Grace and All the Light We Cannot See, which was awarded the 2015 Pulitzer Prize for fiction and the 2015 Andrew Carnegie Medal for Excellence in Fiction.\n\nDoerr’s short stories and essays have won four O. Henry Prizes and been anthologized in The Best American Short Stories, New American Stories, The Best American Essays, The Scribner Anthology of Contemporary Fiction, and lots of other places. His work has been translated into over forty languages and won the Barnes & Noble Discover Prize, the Rome Prize, the New York Public Library’s Young Lions Award, a Guggenheim Fellowship, an NEA Fellowship, an Alex Award from the American Library Association, the National Magazine Award for Fiction, four Pushcart Prizes, two Pacific Northwest Book Awards, four Ohioana Book Awards, the 2010 Story Prize, which is considered the most prestigious prize in the U.S. for a collection of short stories, and the Sunday Times EFG Short Story Award, which is the largest prize in the world for a single short story. All the Light We Cannot See was a #1 New York Times bestseller, and remained on the hardcover fiction bestseller list for 134 consecutive weeks.\n\nDoerr lives in Boise, Idaho with his wife and two sons. A number of media interviews with him are collected here. Though he is often asked, as far as he knows he is not related to the late writer Harriet Doerr.\n([source][1])\n\n\n  [1]: http://anthonydoerr.com/biography/
194	Emily St. John	Mandel	1979	\N	\N
195	Stanisław	Lem	1921-09-12	2006-03-27	\N
4	William	Styron	1925	2006	\N
27	Margaret	Mitchell	1900-11-08	1949-08-16	\N
156	Tom	Robbins	1936	\N	\N
102	Marc	Reisner	\N	\N	\N
104	Johann	Hari	1979-01-21	\N	\N
106	Richard Lloyd	Parry	\N	\N	\N
107	Kate	Moore	\N	\N	\N
136	Thomas	Harris	1940-04-11	\N	\N
141	Raymond	Chandler	1888	1959	\N
143	Alexandria	Bellefleur	\N	\N	\N
147	Josie	Silver	\N	\N	\N
148	Paul	Beatty	\N	\N	\N
149	George	Saunders	1958	\N	\N
150	Lionel	Shriver	\N	\N	\N
180	E.B.	Sledge	\N	\N	\N
181	M. T.	Anderson	1968-11-04	\N	\N
186	Antonia	White	1899	1980	\N
189	David	Niven	1910	1983	\N
190	Eddie	Jaku	\N	\N	\N
64	Isaac	Asimov	1920-01-02	1992-04-06	Asimov was born sometime between October 4, 1919 and January 2, 1920 in Petrovichi in Smolensk Oblast, RSFSR (now Russia), the son of a Jewish family of millers.  Although his exact date of birth is uncertain, Asimov himself celebrated it on January 2.  His family emigrated to Brooklyn, New York and opened a candy store when he was three years old.  He taught himself to read at the age of five. He began reading the science fiction pulp magazines that his family's store carried. Around the age of eleven, he began to write his own stories, and by age nineteen, he was selling them to the science fiction magazines. He graduated from Columbia University in 1939. He married Gertrude Blugerman in 1942.  During World War II he worked as a civilian at the Philadelphia Navy Yard's Naval Air Experimental Station.  After the war, he returned to Columbia University and earned a Ph.D. in biochemistry in 1948.  He then joined the faculty of the Boston University School of Medicine until 1958, when he became a full-time writer. His first novel, Pebble in the Sky, was published in 1950. He and his wife divorced in 1973, and he married Janet O. Jeppson the same year. He was a highly prolific writer, having written or edited more than 500 books and an estimated 9,000 letters and postcards.
10	Jane	Austen	1775-12-16	1817-07-18	Jane Austen was an English writer. Although Austen was widely read in her lifetime, she published her works anonymously. The most urgent preoccupations of her bright, young heroines are courtship and marriage. Austen herself never married. Her best-known books include *Pride and Prejudice* (1813) and *Emma* (1816). Virginia Woolf called Austen "the most perfect artist among women."
110	Tom	DeMarco	1940-08-20	\N	American software engineer, author, and consultant. (source: https://www.wikidata.org/wiki/Q93115).
49	Arthur Conan	Doyle	1859	1930	Sir Arthur Ignatius Conan Doyle KStJ, DL (22 May 1859 – 7 July 1930) was a Scottish writer and physician, most noted for creating the fictional detective Sherlock Holmes and writing stories about him which are generally considered milestones in the field of crime fiction.\r\n\r\nHe is also known for writing the fictional adventures of a second character he invented, Professor Challenger, and for popularizing the mystery of the Mary Celeste. He was a prolific writer whose other works include fantasy and science fiction stories, plays, romances, poetry, non-fiction and historical novels.[1]\r\n\r\n\r\n  [1]: https://en.wikipedia.org/wiki/Arthur_Conan_Doyle
101	David	Graeber	1961-02-12	2020-09-02	As an assistant professor and associate professor of anthropology at Yale from 1998–2007, David Rolfe Graeber specialized in theories of value and social theory. The university's decision not to rehire him when he would otherwise have become eligible for tenure sparked an academic controversy, and a petition with more than 4,500 signatures. He went on to become, from 2007–13, Reader in Social Anthropology at Goldsmiths, University of London. ([Source](https://en.wikipedia.org/wiki/David_Graeber))
40	Bram	Stoker	1847-11-08	1912-04-20	Abraham "Bram" Stoker, born in 1847 in Dublin, Ireland, was an Irish author best known for his Gothic novel "Dracula," published in 1897. Educated at Trinity College Dublin, Stoker began his career as a civil servant and journalist before finding success as a writer. "Dracula," inspired by Eastern European folklore and the historical figure Vlad the Impaler, introduced the iconic vampire Count Dracula to the world and established many conventions of modern vampire fantasy. Stoker's other works include novels, short stories, and non-fiction, but it is "Dracula" that cemented his legacy as a master of horror literature, influencing countless adaptations in film, television, and literature. Bram Stoker's contribution to the horror genre continues to captivate audiences and inspire creators worldwide, solidifying him as one of the most enduring figures in Gothic fiction.
196	Robert A.	Heinlein	1907-07-07	1988-05-08	Robert Anson Heinlein was an American science fiction writer. Often called "the dean of science fiction writers", he was one of the most popular, influential, and controversial authors of the genre. He set a high standard for science and engineering plausibility and helped to raise the genre's standards of literary quality. He was one of the first writers to break into mainstream, general magazines such as The Saturday Evening Post, in the late 1940s, with unvarnished science fiction. He was among the first authors of bestselling, novel-length science fiction in the modern, mass-market era. For many years, Heinlein, Isaac Asimov, and Arthur C. Clarke were known as the "Big Three" of science fiction. (http://en.wikipedia.org/wiki/Robert_A._Heinlein)
2	Ernest	Hemingway	1899-07-21	1961-07-02	Ernest Miller Hemingway was an American writer and journalist. During his lifetime he wrote and had published seven novels; six collections of short stories; and two works of non-fiction. Since his death three novels, four collections of short stories, and three non-fiction autobiographical works have been published. Hemingway received the Nobel Prize in Literature in 1954.\r\n\r\nHemingway was born and raised in Oak Park, Illinois. After high school he worked as a reporter but within months he left for the Italian front to be an ambulance driver in World War I. He was seriously injured and returned home within the year. He married his first wife Hadley Richardson in 1922 and moved to Paris, where he worked as a foreign correspondent. During this time Hemingway met, and was influenced by, writers and artists of the 1920s expatriate community known as the "Lost Generation". In 1924 Hemingway wrote his first novel, The Sun Also Rises.\r\n\r\nIn the late 1920s, Hemingway divorced Hadley, married his second wife Pauline Pfeiffer, and moved to Key West, Florida. In 1937 Hemingway went to Spain as a war correspondent to cover the Spanish Civil War. After the war he divorced Pauline, married his third wife Martha Gellhorn, wrote For Whom the Bell Tolls, and moved to Cuba. Hemingway covered World War II in Europe and he was present at Operation Overlord. Later he was in Paris during the liberation of Paris. After the war, he divorced again, married his fourth wife Mary Welsh Hemingway, and wrote Across the River and Into the Trees. Two years later, The Old Man and the Sea was published in 1952. Nine years later, after moving from Cuba to Idaho, he committed suicide in the summer of 1961.\r\n\r\nHemingway produced most of his work between the mid 1920s and the mid 1950s, though a number of unfinished works were published posthumously. Hemingway's distinctive writing style is characterized by economy and understatement, and had a significant influence on the development of twentieth-century fiction writing. His protagonists are typically stoical men who exhibit an ideal described as "grace under pressure." Many of his works are now considered classics of American literature. During his lifetime, Hemingway's popularity peaked after the publication of The Old Man and the Sea.\r\n\r\n\r\nSource and more information: https://en.wikipedia.org/wiki/Ernest_Hemingway
73	Thomas	Hobbes	1588-04-05	1679-12-04	Thomas Hobbes, in some older texts Thomas Hobbs of Malmsbury, was an English philosopher, remembered today for his work on political philosophy. His 1651 book Leviathan established the foundation for most of Western political philosophy from the perspective of social contract theory.\r\n\r\nHobbes also contributed to a diverse array of fields, including history, geometry, physics of gases, theology, ethics, general philosophy, and political science. His account of human nature as self-interested cooperation has proved to be an enduring theory in the field of philosophical anthropology. He was one of the main philosophers who founded materialism. [1]\r\n\r\n\r\n  [1]: http://en.wikipedia.org/wiki/Thomas_Hobbes
116	Jon	Krakauer	1954-04-12	\N	Jon Krakauer (April 12,1954) is an American writer, journalist, and mountaineer, well-known for outdoor and mountain-climbing writing. In 2003, he ventured into the field of investigative journalism.\r\n\r\nSource: [Jon Krakauer](https://en.wikipedia.org/wiki/Jon_Krakauer) on Wikipedia.
89	R. F.	Kuang	\N	\N	Rebecca F. Kuang is a Chinese-American fantasy writer. Her first novel, *The Poppy War*, was released in 2018, followed by the sequels *The Dragon Republic* in 2019 and *The Burning God* in 2020. Kuang has won the Compton Crook Award, the Crawford Award, and the 2020 Astounding Award for Best New Writer, along with being a finalist for the Nebula, Locus, World Fantasy, The Kitschies, and British Fantasy awards for her first novel. \r\n\r\nSource: [R. F. Kuang](https://en.wikipedia.org/wiki/R._F._Kuang) on Wikipedia.
30	Daphne Du	Maurier	1907-05-13	1989-04-19	Daphne du Maurier was born on 13 May 1907 in London, England, United Kingdom, the second of three daughters of Muriel Beaumont, an actress and maternal niece of William Comyns Beaumont, and Sir Gerald du Maurier, the prominent actor-manager, son of the author and Punch cartoonist George du Maurier, who created the character of Svengali in the novel Trilby. She was also the cousin of the Llewelyn Davies boys, who served as J.M. Barrie's inspiration for the characters in the play Peter Pan, or The Boy Who Wouldn't Grow Up. As a young child, she met many of the brightest stars of the theatre, thanks to the celebrity of her father. These connections helped her in establishing her literary career, and she published some of her early stories in Beaumont's Bystander magazine. Her first novel, The Loving Spirit, was published in 1931, and she continued writing successfull gothic novels in addition to biographies and other non-fiction books. Alfred Hitchcock was a fan of her novels and short stories, and adapted some of these to films: Jamaica Inn (1939), Rebecca (1940), and The Birds (1963). Other of her works adapted were Frenchman's Creek (1942), Hungry Hill (1943), My Cousin Rachel (1951), and "Don't Look Now" (1973). She was named a Dame of the British Empire.
158	Shel	Silverstein	\N	\N	Shel Silverstein, born in 1930 in Chicago, Illinois, was a versatile and immensely creative figure in American literature and the arts. Known primarily as a beloved children's author and illustrator, Silverstein's career encompassed much more: he was also a poet, singer-songwriter, and playwright. His iconic works include "The Giving Tree," a poignant story about selflessness and love, and "Where the Sidewalk Ends," a collection of whimsical poems cherished by generations. Silverstein's distinctive style combined wit, empathy, and a keen understanding of human nature, making his work resonate with both children and adults alike. His legacy endures through his timeless contributions to literature, music, and artistry, marking him as a truly unique and influential voice in American culture.
177	Bruce	Springsteen	1949-09-23	\N	Bruce Springsteen, born in 1949 in Long Branch, New Jersey, is a legendary American singer-songwriter and musician whose career spans over five decades. Known affectionately as "The Boss," Springsteen emerged in the 1970s with his distinctive blend of rock, folk, and Americana, capturing the struggles and dreams of working-class America. His albums such as "Born to Run," "Darkness on the Edge of Town," and "Born in the U.S.A." are iconic for their powerful storytelling and anthemic quality. Springsteen's music often explores themes of blue-collar life, redemption, and social justice, earning him critical acclaim and a devoted global fanbase. Beyond music, he has also written a bestselling memoir, performed in sold-out concerts worldwide, and remains a cultural icon revered for his authenticity and unwavering commitment to his craft.
183	Irving	Stone	1903-07-14	1989-08-26	Irving Stone, born in 1903 in San Francisco, California, was an American writer known for his biographical novels that vividly portrayed the lives of historical figures. After studying at the University of California, Berkeley and working briefly as a schoolteacher, Stone turned to writing full-time. He gained acclaim for his meticulously researched novels, which include "Lust for Life" (1934) about Vincent van Gogh, "The Agony and the Ecstasy" (1961) about Michelangelo, and "The Passions of the Mind" (1971) about Sigmund Freud. Stone's approach blended fictional narrative with factual biography, bringing to life the inner struggles and achievements of his subjects with empathy and detail. His works not only became bestsellers but also contributed to popularizing historical figures and making their stories accessible to a broader audience. Irving Stone's dedication to biographical storytelling left a lasting impact on literature, influencing how historical figures are perceived and remembered.
51	John	Updike	1932-03-18	2009-01-27	John Updike, born in 1932 in Reading, Pennsylvania, was an acclaimed American novelist, short story writer, poet, and critic whose prolific literary career spanned over five decades. Known for his keen observations of middle-class America and his exquisite prose style, Updike's works often delved into the complexities of suburban life, relationships, and the human condition. He gained widespread recognition for his Rabbit series, starting with "Rabbit, Run" (1960), which followed the life of Harry "Rabbit" Angstrom through four novels and earned Updike two Pulitzer Prizes for Fiction. Beyond the Rabbit series, Updike published numerous novels, short stories, essays, and poems that explored themes of identity, religion, and the passage of time with a meticulous attention to detail and a deep psychological insight. His literary achievements established him as one of the preeminent American writers of his generation, celebrated for his lyrical prose, intellectual curiosity, and ability to capture the nuances of contemporary American life.
22	Virginia	Woolf	1882-01-25	1941-03-28	Virginia Woolf, born in 1882 in London, England, was a pioneering English writer, essayist, and modernist thinker whose works revolutionized the literary landscape of the early 20th century. Alongside her husband Leonard Woolf, she played a central role in the Bloomsbury Group, a circle of intellectuals and artists who challenged Victorian norms and embraced new ideas in art, literature, and philosophy. Woolf's writing is characterized by its innovative narrative techniques and exploration of the inner lives and psychology of her characters, often delving into themes of gender, identity, and the complexities of human relationships. Her notable novels include "Mrs. Dalloway," "To the Lighthouse," and "Orlando," each showcasing her mastery of stream-of-consciousness narrative and her ability to capture the subtleties of human emotions and experiences. Woolf's influence extended beyond literature as a feminist icon and advocate for women's rights, leaving an indelible mark on both modernist literature and feminist discourse. Her tragic death in 1941 marked the end of a brilliant literary career, but her legacy continues to inspire generations of writers and readers worldwide.
\.


--
-- Data for Name: book_genres; Type: TABLE DATA; Schema: lib; Owner: -
--

COPY lib.book_genres (genre_id, book_id) FROM stdin;
12	61
2	61
3	61
2	3
3	3
4	3
3	4
12	1
5	1
2	1
2	2
8	2
3	2
25	6
26	6
2	6
3	6
2	7
3	7
2	8
3	8
25	9
13	9
2	9
3	9
25	10
2	10
3	10
2	11
8	11
3	11
2	12
3	12
25	14
2	14
3	14
2	19
3	19
25	20
23	20
2	20
17	20
5	20
2	21
8	21
9	21
3	21
2	22
3	22
8	22
9	24
7	24
2	24
2	25
8	25
3	25
10	25
2	26
3	26
25	27
13	27
7	27
2	27
2	28
11	28
22	28
25	29
8	29
2	29
2	31
3	31
8	31
6	31
2	32
8	32
3	32
25	34
2	34
3	34
8	34
7	34
2	35
8	35
11	35
6	35
26	36
2	36
8	36
6	36
14	37
18	37
2	40
3	40
8	40
12	42
24	42
25	42
9	44
18	44
10	44
2	45
12	45
9	46
2	46
3	46
6	46
26	47
2	47
8	47
3	47
6	47
25	48
24	48
2	48
24	51
21	51
25	54
23	54
5	54
2	54
2	56
7	56
2	57
24	57
3	57
2	59
10	59
25	60
2	60
9	60
3	60
4	60
2	62
3	62
8	62
15	63
2	63
3	63
5	63
26	64
8	64
2	64
12	65
11	65
17	65
2	65
2	66
8	66
9	66
3	66
2	67
4	67
22	67
9	68
2	68
25	69
5	69
7	69
2	69
11	69
3	72
2	72
12	73
13	73
7	73
2	73
2	74
9	74
7	74
11	74
2	75
9	75
7	75
8	88
23	106
2	119
18	152
10	170
2	187
14	205
2	225
12	143
18	143
25	58
2	58
10	58
15	203
18	203
23	93
5	106
5	120
18	153
9	170
4	187
14	206
25	23
2	23
7	23
2	228
7	228
5	93
2	106
10	120
18	154
18	171
22	187
18	206
23	192
2	192
21	192
2	189
24	90
2	93
2	107
2	120
22	189
10	171
14	207
7	227
2	182
4	182
25	77
25	103
4	93
5	107
18	121
18	155
2	172
18	207
2	227
2	226
7	226
23	103
5	103
2	103
2	77
25	92
22	93
5	108
24	122
18	156
11	172
5	115
2	115
8	115
9	115
8	77
23	92
5	94
2	94
10	108
18	122
2	157
10	172
2	162
10	162
15	213
18	213
13	105
5	105
2	105
9	105
3	77
2	92
2	95
2	108
18	123
25	157
20	124
18	209
7	229
2	76
8	76
24	76
18	38
18	124
2	78
5	92
5	95
18	125
18	158
6	174
14	209
2	229
21	195
6	78
5	70
2	70
17	70
2	96
18	126
12	158
2	174
18	210
7	230
14	219
8	78
17	96
18	127
10	159
5	175
25	191
14	210
2	230
21	194
2	79
9	96
18	128
2	159
2	175
21	191
7	231
23	71
5	71
2	71
17	71
7	79
5	97
2	110
18	129
6	175
2	191
2	231
25	16
5	16
2	16
3	16
13	80
2	97
5	110
18	130
8	175
7	232
14	218
18	218
2	80
9	97
5	111
18	131
2	161
6	176
2	232
2	178
6	178
11	80
16	97
8	111
18	132
17	161
2	176
7	233
25	53
2	53
9	53
4	53
7	80
23	98
2	111
18	133
10	161
21	193
2	233
5	52
2	52
22	52
6	52
8	39
3	39
6	39
14	81
5	98
5	112
7	234
2	81
3	98
7	112
18	134
2	234
8	81
2	98
2	112
18	135
2	163
2	196
19	81
5	99
5	113
18	136
11	163
2	179
12	196
14	215
18	215
18	81
17	99
2	113
18	137
10	163
4	179
2	82
2	99
5	114
10	138
2	164
22	179
15	214
18	214
3	82
2	100
10	114
18	138
9	164
2	180
2	198
18	91
8	82
5	100
2	114
18	139
10	164
24	180
12	198
13	50
2	50
7	50
5	101
18	140
3	180
12	199
14	217
20	217
14	208
18	208
2	101
20	141
2	181
2	199
2	84
5	102
18	141
2	166
4	181
18	200
15	216
18	216
24	84
2	102
18	142
11	166
15	200
2	235
7	235
8	84
5	116
10	166
14	201
18	220
2	165
10	165
22	85
2	116
2	167
4	183
18	201
14	220
13	43
23	43
2	43
9	43
2	85
2	117
18	144
11	167
2	183
15	202
18	221
2	169
10	169
11	169
10	86
5	117
18	145
10	167
25	184
18	202
2	160
10	160
2	17
22	17
4	17
2	86
5	104
5	118
2	168
4	184
14	223
25	109
5	109
2	109
9	109
17	109
2	33
8	33
3	33
13	87
2	104
2	118
18	146
11	168
2	184
18	223
2	83
7	83
2	87
9	118
18	147
10	168
2	185
15	204
18	204
12	224
12	13
25	13
2	13
3	13
3	87
6	118
18	148
4	185
7	224
2	89
3	89
9	87
8	118
18	149
22	185
2	224
25	55
13	55
2	55
7	55
2	88
5	119
18	150
22	186
12	205
7	225
2	30
8	30
6	30
11	30
13	41
2	41
3	41
11	41
24	88
12	106
10	119
18	151
2	170
2	186
18	205
13	225
25	190
2	190
22	190
4	190
8	75
\.


--
-- Data for Name: book_instance; Type: TABLE DATA; Schema: lib; Owner: -
--

COPY lib.book_instance (book_id, instance_id, imprint, due_back, status) FROM stdin;
1	1	Darien Publishing	\N	Available
3	2	ABC Publishing	2024-06-10	Reserved
50	3	Galapagos	\N	Available
50	5	Simone & Scrivener	2024-07-24	Loaned
50	6	Piper-Tollens	2024-07-18	Reserved
187	7	Folio, Ltd.	2024-06-24	Loaned
210	8	Morgana Press	2025-05-11	Reserved
56	9	Folio, Ltd.	\N	Available
62	10	Troubadour	\N	Available
62	11	Troubadour	\N	Available
180	12	Folio, Ltd.	2026-04-19	Maintenance
127	13	Teller Timber & Pulp	2025-12-12	Reserved
57	14	Knott	\N	Available
176	15	Piper-Tollens	\N	Available
34	16	Picayune Publishing	\N	Available
207	17	Magellan House	2025-11-09	Loaned
25	18	Galapagos	2025-07-27	Loaned
70	19	Magellan House	\N	Available
200	20	Knott	\N	Available
62	21	Magellan House	2025-06-29	Loaned
218	22	Knott	2026-04-11	Reserved
152	23	Knott	2025-10-24	Reserved
163	24	SPQR Publications	2025-08-14	Reserved
181	25	Piper-Tollens	2025-11-28	Loaned
131	26	Maximillion Manuscripts	2024-12-31	Reserved
152	27	SPQR Publications	\N	Available
210	28	Galapagos	2025-07-15	Reserved
202	29	Piper-Tollens	\N	Available
105	30	Simone & Scrivener	\N	Available
59	31	Morgana Press	2025-08-07	Loaned
56	32	Bay City Press	2026-05-31	Loaned
215	33	SPQR Publications	2024-07-22	Maintenance
179	34	Maximillion Manuscripts	\N	Available
200	35	Hatchet Books	2024-08-09	Reserved
97	36	Folio, Ltd.	2025-08-25	Reserved
29	37	Simone & Scrivener	2025-01-03	Reserved
148	38	Troubadour	\N	Available
142	39	Simone & Scrivener	2025-01-14	Maintenance
203	40	Simone & Scrivener	\N	Available
67	41	Bay City Press	\N	Available
190	42	Picayune Publishing	\N	Available
110	43	Hatchet Books	\N	Available
176	44	Simone & Scrivener	2026-02-03	Maintenance
36	45	Maximillion Manuscripts	\N	Available
12	46	Piper-Tollens	\N	Available
88	47	Knott	2025-04-16	Loaned
199	48	Galapagos	2024-07-15	Loaned
120	49	Hatchet Books	\N	Available
70	50	Magellan House	2026-06-15	Loaned
52	51	Morgana Press	2026-03-14	Maintenance
187	52	Bay City Press	2024-10-20	Loaned
81	53	Folio, Ltd.	\N	Available
110	54	Morgana Press	2026-06-07	Loaned
35	55	Teller Timber & Pulp	\N	Available
176	56	Simone & Scrivener	2024-06-17	Loaned
214	57	Galapagos	2024-11-29	Maintenance
201	58	Folio, Ltd.	\N	Available
206	59	Galapagos	2024-10-25	Loaned
21	60	Folio, Ltd.	\N	Available
163	61	Picayune Publishing	2025-05-04	Loaned
67	62	Folio, Ltd.	\N	Available
58	63	Troubadour	2024-09-15	Loaned
179	64	Hatchet Books	2024-07-20	Reserved
42	65	Galapagos	\N	Available
30	66	Bay City Press	2024-11-01	Reserved
110	68	Piper-Tollens	2025-01-28	Reserved
116	69	Maximillion Manuscripts	2025-03-06	Loaned
71	70	Magellan House	\N	Available
182	71	Hatchet Books	2024-12-30	Reserved
11	72	Maximillion Manuscripts	2025-05-07	Reserved
149	73	Galapagos	2026-04-05	Reserved
6	74	Bay City Press	2026-04-14	Reserved
64	75	Morgana Press	2025-06-07	Loaned
12	76	Morgana Press	\N	Available
208	77	Picayune Publishing	2024-09-23	Maintenance
174	78	Picayune Publishing	2025-05-01	Maintenance
156	79	Magellan House	2026-05-19	Loaned
12	82	Knott	2026-04-19	Maintenance
25	83	Magellan House	2024-11-26	Maintenance
9	84	Galapagos	2025-07-07	Reserved
101	85	Magellan House	\N	Available
90	86	Simone & Scrivener	2026-06-05	Loaned
111	87	SPQR Publications	\N	Available
164	88	Picayune Publishing	2026-03-23	Reserved
84	89	Simone & Scrivener	2025-11-27	Maintenance
81	91	Troubadour	2024-08-17	Maintenance
123	92	Knott	2025-08-04	Loaned
33	93	Magellan House	\N	Available
33	94	Teller Timber & Pulp	2025-06-15	Loaned
28	95	Maximillion Manuscripts	2025-07-13	Reserved
7	96	Galapagos	2024-12-18	Maintenance
114	97	Morgana Press	\N	Available
189	98	Piper-Tollens	2026-06-14	Reserved
28	99	Bay City Press	2024-09-21	Loaned
219	100	Picayune Publishing	2025-02-05	Maintenance
183	101	Morgana Press	2025-08-22	Loaned
218	102	Knott	2026-04-11	Reserved
161	103	Morgana Press	2025-01-06	Maintenance
207	104	Teller Timber & Pulp	2026-02-18	Loaned
153	105	Troubadour	2025-09-25	Loaned
185	106	Knott	2025-06-29	Reserved
124	107	Picayune Publishing	2026-03-17	Reserved
81	108	Troubadour	2025-09-03	Loaned
56	109	Troubadour	2025-01-03	Loaned
109	110	Galapagos	2025-07-13	Reserved
99	111	Bay City Press	2026-04-28	Reserved
128	112	Hatchet Books	2025-09-24	Loaned
31	113	Maximillion Manuscripts	\N	Available
175	114	Maximillion Manuscripts	2026-02-26	Loaned
45	115	Maximillion Manuscripts	2025-05-24	Reserved
139	116	Morgana Press	2025-06-09	Reserved
20	118	Troubadour	2026-03-27	Loaned
178	119	Picayune Publishing	2025-02-17	Maintenance
123	120	Simone & Scrivener	2026-01-26	Reserved
12	121	Hatchet Books	2025-12-30	Maintenance
203	122	Morgana Press	2026-02-12	Maintenance
37	123	Hatchet Books	2026-04-15	Reserved
98	124	Maximillion Manuscripts	2024-12-17	Maintenance
224	125	Simone & Scrivener	2025-11-21	Reserved
105	126	Teller Timber & Pulp	2025-10-10	Maintenance
89	127	Galapagos	2026-05-18	Reserved
194	128	Troubadour	2024-07-16	Maintenance
80	129	Galapagos	2025-11-26	Loaned
48	130	Galapagos	\N	Available
152	132	Knott	2024-07-20	Maintenance
149	133	SPQR Publications	2025-10-17	Maintenance
17	134	Bay City Press	2024-11-04	Reserved
189	135	Knott	\N	Available
72	136	Knott	2025-01-27	Reserved
154	137	Folio, Ltd.	\N	Available
135	138	Troubadour	2024-06-27	Loaned
152	139	Maximillion Manuscripts	2024-08-07	Loaned
171	140	Simone & Scrivener	2026-05-16	Loaned
61	141	Teller Timber & Pulp	2024-07-16	Maintenance
110	142	SPQR Publications	2025-12-16	Maintenance
165	143	Folio, Ltd.	2025-11-21	Loaned
142	144	Hatchet Books	2026-03-27	Reserved
140	145	Simone & Scrivener	2025-03-22	Loaned
148	146	Teller Timber & Pulp	2024-11-13	Reserved
81	147	Morgana Press	2026-01-18	Maintenance
85	148	Galapagos	2025-11-13	Reserved
64	149	SPQR Publications	2025-03-25	Loaned
90	150	Galapagos	2025-11-16	Reserved
172	152	Piper-Tollens	2025-09-19	Reserved
124	153	Morgana Press	2025-05-26	Loaned
146	154	Picayune Publishing	\N	Available
200	155	Galapagos	2024-09-02	Maintenance
36	156	Folio, Ltd.	2026-04-21	Maintenance
57	157	Bay City Press	\N	Available
4	158	Bay City Press	2024-10-21	Reserved
42	159	Piper-Tollens	2024-08-13	Loaned
13	160	Troubadour	2025-09-22	Loaned
60	161	Bay City Press	2024-07-23	Maintenance
210	162	Bay City Press	2024-12-25	Loaned
182	163	Troubadour	\N	Available
134	164	Hatchet Books	2026-05-24	Loaned
82	165	Bay City Press	2026-01-05	Maintenance
102	166	Maximillion Manuscripts	2026-04-20	Reserved
119	167	Simone & Scrivener	2025-05-23	Maintenance
18	168	Troubadour	2026-03-12	Reserved
66	169	Morgana Press	2024-09-10	Reserved
83	170	Troubadour	2025-05-21	Maintenance
68	171	Galapagos	2025-02-18	Loaned
205	172	Teller Timber & Pulp	\N	Available
220	173	Knott	2024-08-04	Reserved
191	174	SPQR Publications	2024-10-12	Reserved
156	175	Morgana Press	2026-04-28	Maintenance
14	176	Simone & Scrivener	2024-09-10	Loaned
180	177	Bay City Press	2025-05-17	Reserved
147	178	Picayune Publishing	2024-11-25	Loaned
204	179	Troubadour	\N	Available
67	180	Picayune Publishing	2025-01-05	Maintenance
99	181	Teller Timber & Pulp	2025-03-04	Loaned
16	182	Troubadour	2025-01-03	Loaned
216	183	Magellan House	\N	Available
166	184	Hatchet Books	2025-08-06	Reserved
82	185	Teller Timber & Pulp	2025-04-29	Maintenance
159	186	Galapagos	2025-10-02	Loaned
179	187	Knott	2024-09-02	Maintenance
42	188	Troubadour	2025-06-20	Maintenance
107	189	Teller Timber & Pulp	2026-05-06	Maintenance
10	190	Maximillion Manuscripts	2026-04-27	Loaned
94	191	Folio, Ltd.	2026-01-15	Maintenance
132	192	Bay City Press	\N	Available
31	193	Piper-Tollens	\N	Available
89	194	Hatchet Books	2026-04-13	Loaned
150	195	Piper-Tollens	2026-06-12	Maintenance
1	196	Folio, Ltd.	2025-01-20	Reserved
213	197	Knott	\N	Available
78	198	Galapagos	2025-10-04	Loaned
154	199	SPQR Publications	2025-05-14	Reserved
131	200	Hatchet Books	2025-03-06	Reserved
11	201	Picayune Publishing	\N	Available
203	202	Teller Timber & Pulp	2025-02-20	Maintenance
224	203	Hatchet Books	2025-10-08	Maintenance
119	204	Maximillion Manuscripts	\N	Available
64	205	Knott	2025-10-19	Maintenance
22	206	Folio, Ltd.	\N	Available
53	207	Galapagos	2024-10-30	Loaned
96	208	Morgana Press	2024-09-14	Loaned
60	209	Knott	\N	Available
216	210	Picayune Publishing	\N	Available
156	211	Galapagos	2025-12-07	Maintenance
53	212	Morgana Press	2026-02-21	Loaned
108	213	Simone & Scrivener	2025-03-05	Loaned
146	214	Morgana Press	2025-06-13	Maintenance
11	215	Folio, Ltd.	2025-05-14	Reserved
208	216	Knott	2025-07-11	Reserved
109	217	Piper-Tollens	2024-08-05	Loaned
169	218	Teller Timber & Pulp	\N	Available
135	219	Troubadour	\N	Available
55	220	Magellan House	2025-08-08	Reserved
144	221	Knott	2026-06-01	Loaned
100	222	Bay City Press	\N	Available
17	223	Knott	2026-01-10	Reserved
203	224	Hatchet Books	\N	Available
149	225	Galapagos	\N	Available
203	226	Folio, Ltd.	\N	Available
196	227	Maximillion Manuscripts	2025-10-21	Maintenance
149	228	Simone & Scrivener	\N	Available
111	229	Picayune Publishing	\N	Available
105	230	Maximillion Manuscripts	2024-09-06	Reserved
206	231	Picayune Publishing	\N	Available
141	232	Morgana Press	2024-08-02	Loaned
28	233	Knott	2025-01-17	Maintenance
100	234	Hatchet Books	2026-03-26	Reserved
7	235	Knott	2024-10-30	Loaned
198	236	Hatchet Books	\N	Available
162	237	Maximillion Manuscripts	\N	Available
65	238	Maximillion Manuscripts	\N	Available
161	239	Simone & Scrivener	\N	Available
219	240	Magellan House	\N	Available
181	241	Maximillion Manuscripts	\N	Available
19	242	Teller Timber & Pulp	\N	Available
61	243	Simone & Scrivener	2025-11-08	Maintenance
144	244	Morgana Press	2025-11-28	Maintenance
40	245	Simone & Scrivener	2024-08-25	Maintenance
107	246	SPQR Publications	2024-09-08	Loaned
182	247	Morgana Press	2025-04-23	Maintenance
125	248	Hatchet Books	2025-09-30	Reserved
110	249	Picayune Publishing	\N	Available
59	250	Bay City Press	2026-04-16	Maintenance
179	251	Teller Timber & Pulp	2025-03-23	Loaned
56	252	Hatchet Books	2025-06-25	Loaned
45	253	Teller Timber & Pulp	2025-06-09	Maintenance
79	254	SPQR Publications	2025-02-15	Reserved
209	255	Magellan House	2025-12-03	Loaned
87	256	Morgana Press	2024-12-12	Reserved
54	257	Magellan House	2025-11-23	Loaned
109	258	Folio, Ltd.	2025-09-04	Reserved
118	259	Knott	2026-06-13	Loaned
176	260	Magellan House	2025-03-19	Maintenance
96	261	Morgana Press	2024-10-15	Reserved
99	262	Galapagos	2025-08-01	Reserved
136	263	Knott	2024-11-05	Maintenance
181	264	SPQR Publications	2025-09-26	Loaned
149	265	Bay City Press	\N	Available
112	266	Hatchet Books	2024-12-14	Maintenance
76	267	Folio, Ltd.	\N	Available
147	268	Picayune Publishing	\N	Available
82	269	Picayune Publishing	2024-07-23	Reserved
201	270	SPQR Publications	2025-10-10	Reserved
3	271	SPQR Publications	\N	Available
32	272	Maximillion Manuscripts	2025-06-09	Reserved
130	273	Galapagos	\N	Available
116	274	Piper-Tollens	2025-03-10	Reserved
210	275	Bay City Press	2024-07-29	Reserved
92	276	Picayune Publishing	2025-01-29	Loaned
157	277	Magellan House	2025-09-09	Maintenance
205	278	Hatchet Books	2025-05-14	Maintenance
104	279	Knott	2025-04-22	Reserved
179	280	Morgana Press	2024-07-14	Reserved
110	281	Simone & Scrivener	2025-03-23	Reserved
67	282	Troubadour	2025-07-12	Loaned
113	283	Morgana Press	2026-01-22	Loaned
116	284	Morgana Press	\N	Available
130	285	Piper-Tollens	2025-01-09	Maintenance
136	286	Knott	2025-04-28	Reserved
171	287	SPQR Publications	2025-10-01	Reserved
184	288	Picayune Publishing	\N	Available
119	289	Simone & Scrivener	2024-07-04	Reserved
134	290	Knott	\N	Available
191	291	Knott	2025-01-20	Reserved
56	292	Maximillion Manuscripts	2025-06-30	Loaned
40	293	Morgana Press	2026-01-12	Maintenance
150	294	Morgana Press	2024-11-04	Loaned
1	295	Bay City Press	2024-10-21	Maintenance
194	296	SPQR Publications	2025-02-17	Loaned
71	297	Folio, Ltd.	2025-08-14	Reserved
115	299	Galapagos	2025-07-14	Loaned
118	300	Simone & Scrivener	\N	Available
50	301	Magellan House	2024-10-31	Maintenance
113	302	Troubadour	2024-07-18	Maintenance
181	303	Folio, Ltd.	2025-11-10	Maintenance
24	304	Troubadour	\N	Available
34	305	Simone & Scrivener	\N	Available
195	306	Teller Timber & Pulp	2024-07-22	Loaned
20	307	Picayune Publishing	2025-08-07	Loaned
159	308	Troubadour	\N	Available
139	309	Morgana Press	\N	Available
195	310	Morgana Press	2024-06-17	Maintenance
6	312	Bay City Press	2025-08-08	Reserved
51	313	Galapagos	2024-11-26	Reserved
176	314	Folio, Ltd.	2024-09-26	Maintenance
14	315	Folio, Ltd.	2025-05-23	Loaned
205	316	Bay City Press	2026-05-13	Maintenance
122	317	Bay City Press	2024-08-07	Loaned
159	318	Piper-Tollens	2024-11-06	Maintenance
113	319	Piper-Tollens	2025-10-30	Maintenance
103	320	Magellan House	2025-05-20	Maintenance
19	321	Hatchet Books	\N	Available
44	322	Troubadour	2025-01-27	Maintenance
74	323	SPQR Publications	2024-11-22	Loaned
107	324	Galapagos	\N	Available
166	325	Bay City Press	2026-05-01	Reserved
131	326	Teller Timber & Pulp	2024-08-17	Reserved
147	327	Picayune Publishing	2025-11-11	Maintenance
3	328	Galapagos	2025-02-07	Maintenance
152	329	Troubadour	2024-09-23	Loaned
185	330	Morgana Press	2025-10-07	Maintenance
201	331	Maximillion Manuscripts	\N	Available
159	332	Teller Timber & Pulp	2026-02-11	Maintenance
42	333	Troubadour	2025-12-25	Loaned
174	334	SPQR Publications	2024-10-16	Maintenance
143	336	Picayune Publishing	2025-11-13	Maintenance
182	337	Troubadour	2026-01-21	Reserved
54	338	Knott	\N	Available
134	340	Piper-Tollens	2025-02-13	Reserved
103	341	Simone & Scrivener	2024-10-06	Loaned
37	342	Morgana Press	2024-11-01	Reserved
91	343	Starscape Publishing	\N	Available
91	344	Cosmic Press	2024-10-24	Loaned
\.


--
-- Data for Name: books; Type: TABLE DATA; Schema: lib; Owner: -
--

COPY lib.books (book_id, author_id, isbn, title, summary) FROM stdin;
6	5	9780199536405	The Great Gatsby	Here is a novel, glamorous, ironical, compassionate – a marvelous fusion into unity of the curious incongruities of the life of the period – which reveals a hero like no other – one who could live at no other time and in no other place. But he will live as a character, we surmise, as long as the memory of any reader lasts.\r\n\r\n"There was something gorgeous about him, some heightened sensitivity to the promises of life.... It was an extraordinary gift for hope, a romantic readiness such as I have never found in any other person and which it is not likely I shall ever find again."\r\n\r\nIt is the story of this Jay Gatsby who came so mysteriously to West Egg, of his sumptuous entertainments, and of his love for Daisy Buchanan – a story that ranges from pure lyrical beauty to sheer brutal realism, and is infused with a sense of the strangeness of human circumstance in a heedless universe.\r\n\r\nIt is a magical, living book, blended of irony, romance, and mysticism.
7	6	9781613821176	Ulysses	Written over a seven-year period, from 1914 to 1921, this book has survived bowdlerization, legal action and controversy. The novel deals with the events of one day in Dublin, 16th June 1904, now known as "Bloomsday". The principal characters are Stephen Dedalus, Leopold Bloom and his wife Molly. Ulysses has been labelled dirty, blasphemous and unreadable. In a famous 1933 court decision, Judge John M. Woolsey declared it an emetic book-although he found it not quite obscene enough to disallow its importation into the United States-and Virginia Woolf was moved to decry James Joyce's "cloacal obsession". None of these descriptions, however, do the slightest justice to the novel. To this day it remains the modernist masterpiece, in which the author takes both Celtic lyricism and vulgarity to splendid extremes. It is funny, sorrowful, and even (in its own way) suspenseful. And despite the exegetical industry that has sprung up in the last 75 years, Ulysses is also a compulsively readable book.
4	4	0394461096	Sophie's Choice	The gripping, unforgettable story of Stingo, a 22-year-old writer; Sophie, a Polish-Catholic beauty who survived the Nazi concentration camp at Auschwitz; and Nathan, her mercurial lover. The three friends share magical, heart-warming times until doom overtakes them as Sophie's and Nathan's darkest secrets are revealed.
1	1	0544422848	The Hobbit	The Hobbit is a tale of high adventure, undertaken by a company of dwarves in search of dragon-guarded gold. A reluctant partner in this perilous quest is Bilbo Baggins, a comfort-loving unambitious hobbit, who surprises even himself by his resourcefulness and skill as a burglar.\r\n\r\nEncounters with trolls, goblins, dwarves, elves, and giant spiders, conversations with the dragon, Smaug, and a rather unwilling presence at the Battle of Five Armies are just some of the adventures that befall Bilbo.\r\n\r\nBilbo Baggins has taken his place among the ranks of the immortals of children’s fiction. Written by Professor Tolkien for his children, The Hobbit met with instant critical acclaim when published.
3	3	0808520695	Cat's Cradle	Cat's Cradle is Kurt Vonnegut's satirical commentary on modern man and his madness. An apocalyptic tale of this planet's ultimate fate, it features a midget as the protagonist, a complete, original theology created by a calypso singer, and a vision of the future that is at once blackly fatalistic and hilariously funny. A book that left an indelible mark on an entire generation of readers, Cat's Cradle is one of the twentieth century's most important works -- and Vonnegut at his very best.
2	2	0684717972	A Farewell to Arms	A Farewell to Arms is about a love affair between the expatriate American Henry and Catherine Barkley against the backdrop of the First World War, cynical soldiers, fighting and the displacement of populations. The publication of A Farewell to Arms cemented Hemingway's stature as a modern American writer, became his first best-seller, and is described by biographer Michael Reynolds as "the premier American war novel from that debacle World War I."
8	7	0316769533	The Catcher in the Rye	Story of Holden Caufield with his idiosyncrasies, penetrating insight, confusion, sensitivity and negativism. Holden, knowing he is to be expelled from school, decides to leave early. He spends three days in New York City and tells the story of what he did and suffered there.
25	22	0156907380	To the Lighthouse	This novel is an extraordinarily poignant evocation of a lost happiness that lives on in the memory. For years now the Ramsays have spent every summer in their holiday home in Scotland, and they expect these summers will go on forever.In this, her most autobiographical novel, Virginia Woolf captures the intensity of childhood longing and delight, and the shifting complexity of adult relationships. From an acute awareness of transcience, she creates an enduring work of art.
9	8	6257245885	Nineteen Eighty-Four	Nineteen Eighty-Four: A Novel, often referred to as 1984, is a dystopian social science fiction novel by the English novelist George Orwell (the pen name of Eric Arthur Blair). It was published on 8 June 1949 by Secker & Warburg as Orwell's ninth and final book completed in his lifetime. Thematically, Nineteen Eighty-Four centres on the consequences of totalitarianism, mass surveillance, and repressive regimentation of persons and behaviours within society. Orwell, himself a democratic socialist, modelled the authoritarian government in the novel after Stalinist Russia. More broadly, the novel examines the role of truth and facts within politics and the ways in which they are manipulated.
10	9	0613054490	To Kill a Mockingbird	One of the best-loved stories of all time, To Kill a Mockingbird has been translated into more than 40 languages, sold more than 30 million copies worldwide, served as the basis for an enormously popular motion picture, and voted one of the best novels of the 20th century by librarians across the United States. A gripping, heart-wrenching, and wholly remarkable tale of coming-of-age in a South poisoned by virulent prejudice, it views a world of great beauty and savage inequities through the eyes of a young girl, as her father -- a crusading local lawyer -- risks everything to defend a black man unjustly accused of a terrible crime.\r\n\r\nLawyer Atticus Finch defends Tom Robinson -- a black man charged with the rape of a white girl. Writing through the young eyes of Finch's children Scout and Jem, Harper Lee explores with rich humor and unswerving honesty the irrationality of adult attitudes toward race and class in small-town Alabama during the mid-1930s Depression years. The conscience of a town steeped in prejudice, violence, and hypocrisy is pricked by the stamina and quiet heroism of one man's struggle for justice. But the weight of history will only tolerate so much.
11	10	1949611256	Pride and Prejudice	Pride and Prejudice is an 1813 novel of manners written by Jane Austen. The novel follows the character development of Elizabeth Bennet, the dynamic protagonist of the book who learns about the repercussions of hasty judgments and comes to appreciate the difference between superficial goodness and actual goodness.\n\nMr. Bennet, owner of the Longbourn estate in Hertfordshire, has five daughters, but his property is entailed and can only be passed to a male heir. His wife also lacks an inheritance, so his family faces becoming very poor upon his death. Thus, it is imperative that at least one of the girls marry well to support the others, which is a motivation that drives the plot.
12	11	9798708126900	Wuthering Heights	Wuthering Heights is an 1847 novel by Emily Brontë, initially published under the pseudonym Ellis Bell. It concerns two families of the landed gentry living on the West Yorkshire moors, the Earnshaws and the Lintons, and their turbulent relationships with Earnshaw's adopted son, Heathcliff. The novel was influenced by Romanticism and Gothic fiction.
14	13	0736639845	Anna Karenina	Described by William Faulkner as the best novel ever written and by Fyodor Dostoevsky as “flawless,” Anna Karenina tells of the doomed love affair between the sensuous and rebellious Anna and the dashing officer, Count Vronsky. Tragedy unfolds as Anna rejects her passionless marriage and thereby exposes herself to the hypocrisies of society. Set against a vast and richly textured canvas of nineteenth-century Russia, the novel's seven major characters create a dynamic imbalance, playing out the contrasts of city and country life and all the variations on love and family happiness.
18	15	9781561035366	Jane Eyre	The novel is set somewhere in the north of England. Jane's childhood at Gateshead Hall, where she is emotionally and physically abused by her aunt and cousins; her education at Lowood School, where she acquires friends and role models but also suffers privations and oppression; her time as the governess of Thornfield Hall, where she falls in love with her Byronic employer, Edward Rochester; her time with the Rivers family, during which her earnest but cold clergyman cousin, St John Rivers, proposes to her. Will she or will she not marry him?
19	16	5170720653	The Sound and the Fury	In many ways this was an experimental novel, using several differing narrative styles. Divided into four parts, the author relates the same episodes from four different viewpoints, using a different style for each. The story concerns various members of a Southern family, once wealthy landowners but now struggling to maintain their reputation.
20	17	9780880889025	Alice's Adventures in Wonderland	Alice's Adventures in Wonderland (commonly Alice in Wonderland) is an 1865 English children's novel by Lewis Carroll. A young girl named Alice falls through a rabbit hole into a fantasy world of anthropomorphic creatures. It is seen as an example of the literary nonsense genre.\n\nOne of the best-known works of Victorian literature, its narrative, structure, characters and imagery have had huge influence on popular culture and literature, especially in the fantasy genre.
21	18	9753204760	Heart of Darkness	Heart of Darkness (1899) is a novella by Polish-English novelist Joseph Conrad, about a voyage up the Congo River into the Congo Free State, in the heart of Africa, by the story's narrator Charles Marlow. Marlow tells his story to friends aboard a boat anchored on the River Thames. Joseph Conrad is one of the greatest English writers, and Heart of Darkness is considered his best.  His readers are brought to face our psychological selves to answer, ‘Who is the true savage?’. Originally published in 1902, Heart of Darkness remains one of this century’s most enduring works of fiction. Written several years after Joseph Conrad’s grueling sojourn in the Belgian Congo, the novel is a complex meditation on colonialism, evil, and the thin line between civilization and barbarity.
22	19	0394535979	Beloved	Toni Morrison--author of Song of Solomon and Tar Baby--is a writer of remarkable powers: her novels, brilliantly acclaimed for their passion, their dazzling language and their lyric and emotional force, combine the unassailable truths of experience and emotion with the vision of legend and imagination. It is the story--set in post-Civil War Ohio--of Sethe, an escaped slave who has risked death in order to wrench herself from a living death; who has lost a husband and buried a child; who has borne the unthinkable and not gone mad: a woman of "iron eyes and backbone to match." Sethe lives in a small house on the edge of town with her daughter, Denver, her mother-in-law, Baby Suggs, and a disturbing, mesmerizing intruder who calls herself Beloved. Sethe works at "beating back the past," but it is alive in all of them. It keeps Denver fearful of straying from the house. It fuels the sadness that has settled into Baby Suggs' "desolated center where the self that was no self made its home." And to Sethe, the past makes itself heard and felt incessantly: in memories that both haunt and soothe her...in the arrival of Paul D ("There was something blessed in his manner. Women saw him and wanted to weep"), one of her fellow slaves on the farm where she had once been kept...in the vivid and painfully cathartic stories she and Paul D tell each other of their years in captivity, of their glimpses of freedom...and, most powerfully, in the apparition of Beloved, whose eyes are expressionless at their deepest point, whose doomed childhood belongs to the hideous logic of slavery and who, as daughter, sister and seductress, has now come from the "place over there" to claim retribution for what she lost and for what was taken from her. Sethe's struggle to keep Beloved from gaining full possession of her present--and to throw off the long, dark legacy of her past--is at the center of this profoundly affecting and startling novel. But its intensity and resonance of feeling, and the boldness of its narrative, lift it beyond its particulars so that it speaks to our experience as an entire nation with a past of both abominable and ennobling circumstance. In Beloved, Toni Morrison has given us a great American novel. Toni Morrison was awarded the 1988 Pulitzer Prize in Literature for Beloved.
24	21	9944184934	Frankenstein or The Modern Prometheus	*Frankenstein; or, The Modern Prometheus* is an 1818 novel written by English author Mary Shelley. Frankenstein tells the story of Victor Frankenstein, a young scientist who creates a sapient creature in an unorthodox scientific experiment. Shelley started writing the story when she was 18, and the first edition was published anonymously in London on 1 January 1818, when she was 20. Her name first appeared in the second edition, which was published in Paris in 1821.
23	20	9781101084571	The Invisible Man	This book is the story of Griffin, a scientist who creates a serum to render himself invisible, and his descent into madness that follows.
26	23	0060755334	On The Road	Described as everything from a "last gasp" of romantic fiction to a founding text of the Beat Generation movement, this story amounts to a nonfiction novel (as critics were later to describe some works).  Unpublished writer buddies wander from coast to coast in search of whatever they find, eager for experience.  Kerouac's spokesman is Sal Paradise (himself) and real-life friend Neal Casady appears as Dean Moriarty.
27	24	958877361X	Brave New World	Originally published in 1932, this outstanding work of literature is more crucial and relevant today than ever before. Cloning, feel-good drugs, antiaging programs, and total social control through politics, programming, and media -- has Aldous Huxley accurately predicted our future? With a storyteller's genius, he weaves these ethical controversies in a compelling narrative that dawns in the year 632 AF (After Ford, the deity). When Lenina and Bernard visit a savage reservation, we experience how Utopia can destroy humanity. A powerful work of speculative fiction that has enthralled and terrified readers for generations, Brave New World is both a warning to be heeded and thought-provoking yet satisfying entertainment. - Container.
28	25	9781973876571	Gulliver's Travels	A parody of traveler’s tales and a satire of human nature, “Gulliver’s Travels” is Jonathan Swift’s most famous work which was first published in 1726. An immensely popular tale ever since its original publication, “Gulliver’s Travels” is the story of its titular character, Lemuel Gulliver, a man who loves to travel. A series of four journeys are detailed in which Gulliver finds himself in a number of amusing and precarious situations. In the first voyage, Gulliver is imprisoned by a race of tiny people, the Lilliputians, when following a shipwreck he is washed upon the shores of their island country. In his second voyage Gulliver finds himself abandoned in Brobdingnag, a land of giants, where he is exhibited for their amusement. In his third voyage, Gulliver once again finds himself marooned; fortunately he is rescued by the flying island of Laputa, a kingdom devoted to the arts of music and mathematics. He subsequently travels to the surrounding lands of Balnibarbi, Luggnagg, Glubbdubdrib, and Japan. Finally in his last voyage, when he is set adrift by a mutinous crew, he finds himself in the curious Country of the Houyhnhnms. Through the various experiences of Gulliver, Swift brilliantly satirizes the political and cultural environment of his time in addition to creating a lasting and enchanting tale of fantasy. This edition is illustrated by Milo Winter and includes an introduction by George R. Dennis.
29	26	9798664079494	Les Misérables	In this story of the trials of the peasant Jean Valjean--a man unjustly imprisoned, baffled by destiny, and hounded by his nemesis, the magnificently realized, ambiguously malevolent police detective Javert--Hugo achieves the sort of rare imaginative resonance that allows a work of art to transcend its genre.
31	2	0099908506	The Sun Also Rises	Hemingway's profile of the Lost Generation captures life among the expatriates on Paris' Left Bank during the 1920s, the brutality of bullfighting in Spain, and the moral and spiritual dissolution of a generation.
30	27	9787204061792	Gone With the Wind	Margaret Mitchell's monumental epic of the South won a Pulitzer Prize, gave rise to the most popular motion picture of our time, and inspired a sequel that became the fastest selling novel of the century. It is one of the most popular books ever written: more than 28 million copies of the book have been sold in more than 37 countries. Today, more than 60 years after its initial publication, its achievements are unparalleled, and it remains the most revered American saga and the most beloved work by an American writer.
32	28	0449208109	Things Fall Apart	Things Fall Apart is the debut novel by Nigerian author Chinua Achebe, first published in 1958. It depicts pre-colonial life in the southeastern part of Nigeria and the arrival of Europeans during the late 19th century. It is seen as the archetypal modern African novel in English, and one of the first to receive global critical acclaim. It is a staple book in schools throughout Africa and is widely read and studied in English-speaking countries around the world. The novel was first published in the UK in 1962 by William Heinemann Ltd, and became the first work published in Heinemann's African Writers Series.\r\n\r\nThe novel follows the life of Okonkwo, an Igbo ("Ibo" in the novel) man and local wrestling champion in the fictional Nigerian clan of Umuofia. The work is split into three parts, with the first describing his family, personal history, and the customs and society of the Igbo, and the second and third sections introducing the influence of European colonialism and Christian missionaries on Okonkwo, his family, and the wider Igbo community.\r\n\r\nThings Fall Apart was followed by a sequel, No Longer at Ease (1960), originally written as the second part of a larger work along with Arrow of God (1964). Achebe states that his two later novels A Man of the People (1966) and Anthills of the Savannah (1987), while not featuring Okonkwo's descendants, are spiritual successors to the previous novels in chronicling African history.
34	3	0440339065	Slaughterhouse-Five	Slaughterhouse-Five is one of the world's great anti-war books. Centering on the infamous fire-bombing of Dresden, Billy Pilgrim's odyssey through time reflects the mythic journey of our own fractured lives as we search for meaning in what we are afraid to know.
35	30	9780380486038	Rebecca	With these words, the reader is ushered into an isolated gray stone mansion on the windswept Cornish coast, as the second Mrs. Maxim de Winter recalls the chilling events that transpired as she began her new life as the young bride of a husband she barely knew. For in every corner of every room were phantoms of a time dead but not forgotten—a past devotedly preserved by the sinister housekeeper, Mrs. Danvers: a suite immaculate and untouched, clothing laid out and ready to be worn, but not by any of the great house's current occupants. With an eerie presentiment of evil tightening her heart, the second Mrs. de Winter walked in the shadow of her mysterious predecessor, determined to uncover the darkest secrets and shattering truths about Maxim's first wife—the late and hauntingly beautiful Rebecca.
36	31	1562549367	The Scarlet Letter	A stark and allegorical tale of adultery, guilt, and social repression in Puritan New England, The Scarlet Letter is a foundational work of American literature. Nathaniel Hawthorne's exploration of the dichotomy between the public and private self, internal passion and external convention, gives us the unforgettable Hester Prynne, who discovers strength in the face of ostracism and emerges as a heroine ahead of her time.
47	2	0736657010	For Whom the Bell Tolls	High in the pine forests of the Spanish Sierra, a guerrilla band prepares to blow up a vital bridge. Robert Jordan, a young American volunteer, has been sent to handle the dynamiting. There, in the mountains, he finds the dangers and the intense comradeship of war. And there he discovers Maria, a young woman who has escaped from Franco's rebels.
127	102	0140178244	Cadillac desert	"Beautifully written and meticulously researched."—St. Louis Post-Dispatch. This updated study of the economics, politics, and ecology of water covers more than a century of public and private desert reclamation in the American West.
187	154	9780553207798	Portnoy's Complaint	Though is caused outrage and controversy at the time of its publication Roth’s comic novel of sexual obsession and frustration is now widely regarded as one of the best novels of the twentieth century.
198	164	0688146562	Lost Horizon	Following a plane crash, Conway, a British consul; his deputy; a missionary; and an American financier find themselves in the enigmatic snow-capped mountains of uncharted Tibet. Here they discover a seemingly perfect hidden community where they are welcomed with gracious hospitality. Intrigued by its mystery, the travellers set about discovering the secret hidden at the shimmering heart of Shangri-La.
83	68	0345350472	Do Androids Dream of Electric Sheep?	It was January 2021, and Rick Deckard had a license to kill.\r\nSomewhere among the hordes of humans out there, lurked several rogue androids. Deckard's assignment--find them and then..."retire" them. Trouble was, the androids all looked exactly like humans, and they didn't want to be found.
37	32	0141007214	The Diary of a Young Girl- Anne Frank	The Diary of a Young Girl, also known as The Diary of Anne Frank, is a book of the writings from the Dutch-language diary kept by Anne Frank while she was in hiding for two years with her family during the Nazi occupation of the Netherlands. The family was apprehended in 1944, and Anne Frank died of typhus in the Bergen-Belsen concentration camp in 1945. Anne's diaries were retrieved by Miep Gies and Bep Voskuijl. Miep gave them to Anne's father, Otto Frank, the family's only survivor, just after the Second World War was over.
40	16	1789505062	As I Lay Dying	Written in stream-of-consciousness style with multiple narrators, the story follows a journey wherein the family of a dead woman try to transport her body to her birthplace in Mississippi in accordance with her wishes. When a ford across a river is flooded they are forced to take a roundabout route and it becomes a desperate race to complete their mission before the body begins to decompose.
42	36	1095033859	Walden	Walden first published in 1854 as Walden; or, Life in the Woods) is a book by American transcendentalist writer Henry David Thoreau. The text is a reflection upon the author's simple living in natural surroundings. The work is part personal declaration of independence, social experiment, voyage of spiritual discovery, satire, and—to some degree—a manual for self-reliance.\n\nWalden details Thoreau's experiences over the course of two years, two months, and two days in a cabin he built near Walden Pond amidst woodland owned by his friend and mentor Ralph Waldo Emerson, near Concord, Massachusetts.\n\nThoreau makes precise scientific observations of nature as well as metaphorical and poetic uses of natural phenomena. He identifies many plants and animals by both their popular and scientific names, records in detail the color and clarity of different bodies of water, precisely dates and describes the freezing and thawing of the pond, and recounts his experiments to measure the depth and shape of the bottom of the supposedly "bottomless" Walden Pond.\n\n(Source: [Wikipedia](https://en.wikipedia.org/wiki/Walden))
44	37	0140026827	In Cold Blood	On November 15, 1959, in the small town of Holcomb, Kansas, four members of the Clutter family were savagely murdered by blasts from a shotgun held a few inches from their faces. There was no apparent motive for the crime, and there were almost no clues.
45	38	9781582790466	Robinson Crusoe	The Life and Strange Surprising Adventures of Robinson Crusoe, Of York, Mariner: Who lived Eight and Twenty Years, all alone in an un-inhabited Island on the Coast of America, near the Mouth of the Great River of Oroonoque; Having been cast on Shore by Shipwreck, wherein all the Men perished but himself. With An Account how he was at last as strangely deliver'd by Pyrates.
46	39	0571081789	The Bell Jar	The Bell Jar is the only novel written by American poet Sylvia Plath. It is an intensely realistic and emotional record of a successful and talented young woman's descent into madness.
38	33	0395683300	Silent Spring	This account of the effects of pesticides on the environment launched the environmental movement in America.
39	34	014023957X	The Portrait of a Lady	An American heiress just arrived in Europe is high-spirited and independent, she does not look to a man for fulfillment but intends to find it for herself.
48	2	0736651772	The Old Man and the Sea	*The Old Man and the Sea* is one of Hemingway's most enduring works. Told in language of great simplicity and power, it is the story of an old Cuban fisherman, down on his luck, and his supreme ordeal -- a relentless, agonizing battle with a giant marlin far out in the Gulf Stream. \n\nHere Hemingway recasts, in strikingly contemporary style, the classic theme of courage in the face of defeat, of personal triumph won from loss. Written in 1952, this hugely successful novella confirmed his power and presence in the literary world and played a large part in his winning the 1954 Nobel Prize for Literature.
51	42	9780312267902	Leaves of Grass	**Leaves of Grass** is a poetry collection by American poet Walt Whitman. First published in 1855, Whitman spent most of his professional life writing and rewriting *Leaves of Grass*, revising it multiple times until his death. There have been held to be either six or nine individual editions of Leaves of Grass, the count varying depending on how they are distinguished.[2] This resulted in vastly different editions over four decades—the first edition being a small book of twelve poems, and the last, a compilation of over 400. \n\n(Source: [Wikipedia](https://en.wikipedia.org/wiki/Leaves_of_Grass))
54	45	0060263865	Charlotte's Web	Charlotte's Web is a book of children's literature by American author E. B. White and illustrated by Garth Williams; it was published on October 15, 1952, by Harper & Brothers. The novel tells the story of a livestock pig named Wilbur and his friendship with a barn spider named Charlotte. When Wilbur is in danger of being slaughtered by the farmer, Charlotte writes messages praising Wilbur (such as "Some Pig") in her web in order to persuade the farmer to let him live.
56	47	1444738208	Dune	Set on the desert planet Arrakis, Dune is the story of the boy Paul Atreides, heir to a noble family tasked with ruling an inhospitable world where the only thing of value is the "spice" melange, a drug capable of extending life and enhancing consciousness. Coveted across the known universe, melange is a prize worth killing for...\n\nWhen House Atreides is betrayed, the destruction of Paul's family will set the boy on a journey toward a destiny greater than he could ever have imagined. And as he evolves into the mysterious man known as Muad'Dib, he will bring to fruition humankind's most ancient and unattainable dream.\n\nA stunning blend of adventure and mysticism, environmentalism and politics, Dune won the first Nebula Award, shared the Hugo Award, and formed the basis of what is undoubtedly the grandest epic in science fiction.
76	61	0811202925	Siddhartha	Hermann Hesse wrote Siddhartha after he traveled to India in the 1910s. It tells the story of a young boy who travels the country in a quest for spiritual enlightenment in the time of Guatama Buddha. It is a compact, lyrical work, which reads like an allegory about the finding of wisdom.
53	44	0670001619	One Flew Over the Cuckoo's Nest	One Flew Over the Cuckoo's Nest is a novel written by Ken Kesey. Set in an Oregon psychiatric hospital, the narrative serves as a study of institutional processes and the human mind; including a critique of psychiatry, and a tribute to individualistic principles.
52	43	1548859052	The Picture of Dorian Gray	The Picture of Dorian Gray is a philosophical novel by Irish writer Oscar Wilde. A shorter novella-length version was published in the July 1890 issue of the American periodical Lippincott’s Monthly Magazine. The novel-length version was published in April 1891.\r\n\r\n(Source: [Wikipedia](https://en.wikipedia.org/wiki/The_Picture_of_Dorian_Gray))
57	48	0060153679	Under the Volcano	It is the Day of the Dead. The fiesta in full swing. In the shadow of Popocatepeti ragged children beg coins to buy skulls made of chocolate...and the ugly pariah dogs roam the streets. Geoffrey Firmin, HM ex-consul, is drowning himself in liquor and Mescal, while his ex-wife and half brother look on powerless to help him. As the day wears on, it becomes apparent that Geoffrey must die. It is his only escape from a world he cannot understand. UNDER THE VOLCANO is one of the century's great undisputed masterpieces.
59	49	0425044211	The Hound of the Baskervilles	The Hound of the Baskervilles is the third of the four crime novels by British writer Arthur Conan Doyle featuring the detective Sherlock Holmes. Originally serialised in The Strand Magazine from August 1901 to April 1902, it is set in 1889 largely on Dartmoor in Devon in England's West Country and tells the story of an attempted murder inspired by the legend of a fearsome, diabolical hound of supernatural origin. Holmes and Watson investigate the case. This was the first appearance of Holmes since his apparent death in "The Final Problem", and the success of The Hound of the Baskervilles led to the character's eventual revival.\n\nOne of the most famous stories ever written, in 2003, the book was listed as number 128 of 200 on the BBC's The Big Read poll of the UK's "best-loved novel". In 1999, a poll of "Sherlockians" ranked it as the best of the four Holmes novels.
60	50	0393923207	The Metamorphosis	Metamorphosis (German: Die Verwandlung) is a novella written by Franz Kafka which was first published in 1915. One of Kafka's best-known works, Metamorphosis tells the story of salesman Gregor Samsa, who wakes one morning to find himself inexplicably transformed into a huge insect (German: ungeheueres Ungeziefer, lit. "monstrous vermin") and subsequently struggles to adjust to this new condition. The novella has been widely discussed among literary critics, with differing interpretations being offered. In popular culture and adaptations of the novella, the insect is commonly depicted as a cockroach.\n\nWith a length of about 70 printed pages over three chapters, it is the longest of the stories Kafka considered complete and published during his lifetime. The text was first published in 1915 in the October issue of the journal Die weißen Blätter under the editorship of René Schickele. The first edition in book form appeared in December 1915 in the series Der jüngste Tag, edited by Kurt Wolff.
62	19	0451083407	Song of Solomon	Milkman Dead was born shortly after a neighborhood eccentric hurled himself off a rooftop in a vain attempt at flight. For the rest of his life he, too, will be trying to fly. With this brilliantly imagined novel, Toni Morrison transfigures the coming-of-age story as audaciously as Saul Bellow or Gabriel García Márquez. As she follows Milkman from his rustbelt city to the place of his family’s origins, Morrison introduces an entire cast of strivers and seeresses, liars and assassins, the inhabitants of a fully realized black world.
63	22	359650547X	Orlando	In her most exuberant, most fanciful novel, Woolf has created a character liberated from the restraints of time and sex. Born in the Elizabethan Age to wealth and position, Orlando is a young nobleman at the beginning of the story-and a modern woman three centuries later.
196	162	1406560189	Green Mansions	A failed revolutionary attempt drives the hero of Hudson's novel to seek refuge in the primeval forests of south-western Venezuela. There, in the "green mansions" of the title, Abel encounters the wood-nymph Rima, the last survivor of a mysterious aboriginal race. The love that flowers between them is soon overshadowed by cruelty and sorrow. - Back cover.
61	51	7536601123	Rabbit, Run	Its hero is Harry “Rabbit” Angstrom, a onetime high-school basketball star who on an impulse deserts his wife and son. He is twenty-six years old, a man-child caught in a struggle between instinct and thought, self and society, sexual gratification and family duty—even, in a sense, human hard-heartedness and divine Grace. Though his flight from home traces a zigzag of evasion, he holds to the faith that he is on the right path, an invisible line toward his own salvation as straight as a ruler’s edge.
64	52	9780394558127	I Know Why the Caged Bird Sings	She was born Marguerite, but her brother Bailey nicknamed her Maya ("mine"). As little children they were sent to live with their grandmother in Stamps, Arkansas. Their early world revolved around this remarkable woman and the Store she ran for the black community. White people were more than strangers - they were from another planet. And yet, even unseen they ruled. \n\nThe Store was a microcosm of life: its orderly pattern was a comfort, even among the meanest frustrations. But then came the intruders - first in the form of taunting poorwhite children who were bested only by the grandmother's dignity. But as the awful, unfathomable mystery of prejudice intruded, so did the unexpected joy of a surprise visit by Daddy, the sinful joy of going to Church, the disappointments of a Depression Christmas.\n\nA visit to St. Louis and the Most Beautiful Mother in the World ended in tragedy - rape. Thereafter Maya refused to speak, except to the person closest to her, Bailey. Eventually, Maya and Bailey followed their mother to California. There, the formative phase of her life (as well as this book) comes to a close with the painful discovery of the true nature of her father, the emergence of a hard-won independence and - perhaps most important - a baby, born out of wedlock, loved and kept.\n\nSuperbly told, with the poet's gift for language and observation, and charged with the unforgetable emotion of remembered anguish and love - this remarkable autobiography by an equally remarkable black girl from Arkansas captures, indelibly, a world of which most Americans are shamefully ignorant.
65	53	167334951X	The Call of the Wild	As Buck, a mixed breed dog, is taken away from his home, instead of facing a feast for breakfast and the comforts of home, he faces the hardships of being a sled dog. Soon he lands in the wrong hands, being forced to keep going when it is too rough for him and the other dogs in his pack. He also fights the urges to run free with his ancestors, the wolves who live around where he is pulling the sled.
66	54	0330304496	Blood Meridian, or the Evening Redness in the West	An epic novel of the violence and depravity that attended America's westward expansion, Blood Meridian brilliantly subverts the conventions of the Western novel and the mythology of the "wild west." Based on historical events that took place on the Texas-Mexico border in the 1850s, it traces the fortunes of the Kid, a fourteen-year-old Tennesseean who stumbles into the nightmarish world where Indians are being murdered and the market for their scalps is thriving.
67	55	3129079912	A Confederacy of Dunces	A Confederacy of Dunces is an American comic masterpiece. John Kennedy Toole's hero is one Ignatius J. Reilly, "huge, obese, fractious, fastidious, a latter-day Gargantua, a Don Quixote of the French Quarter. His story bursts with wholly original characters, denizens of New Orleans' lower depths, incredibly true-to-life dialogue, and the zaniest series of high and low comic adventures."
69	20	1499181892	The Time Machine	The Time Traveller, a dreamer obsessed with traveling through time, builds himself a time machine and, much to his surprise, travels over 800,000 years into the future. He lands in the year 802701: the world has been transformed by a society living in apparent harmony and bliss, but as the Traveler stays in the future he discovers a hidden barbaric and depraved subterranean class. Wells's transparent commentary on the capitalist society was an instant bestseller and launched the time-travel genre.
84	69	0785749314	The Good Earth	This tells the poignant tale of a Chinese farmer and his family in old agrarian China. The humble Wang Lung glories in the soil he works, nurturing the land as it nurtures him and his family. Nearby, the nobles of the House of Hwang consider themselves above the land and its workers; but they will soon meet their own downfall.\n\nHard times come upon Wang Lung and his family when flood and drought force them to seek work in the city. The working people riot, breaking into the homes of the rich and forcing them to flee. When Wang Lung shows mercy to one noble and is rewarded, he begins to rise in the world, even as the House of Hwang falls.
73	20	0060791241	The War of the Worlds	The ultimate science fiction classic: for more than one hundred years, this compelling tale of the Martian invasion of Earth has enthralled readers with a combination of imagination and incisive commentary on the imbalance of power that continues to be relevant today. The style is revolutionary for its era, employing a sophisticated first and third person account of the events which is both personal and focused on the holistic downfall of Earth's society. The Martians, as evil, mechanical and unknown a threat they are, remain daunting in today's society, where, despite technology's mammoth advances, humanity's hegemony over Earth is yet to be called into question. In Well's introduction to the book, where the character discusses with the later deceased Ogilvy about astronomy and the possibility of alien life defeating the 'savage' (to them) nineteenth-century Britain, is he insinuating that this is the truth and fate of humanity? It's up to you to decide…
74	56	9780451098283	The Stand	One man escapes from a biological weapon facility after an accident, carrying with him the deadly virus known as Captain Tripps, a rapidly mutating flu that - in the ensuing weeks - wipes out most of the world's population. In the aftermath, survivors choose between following an elderly black woman to Boulder or the dark man, Randall Flagg, who has set up his command post in Las Vegas. The two factions prepare for a confrontation between the forces of good and evil.\n([source][1])\n\n\n  [1]: https://stephenking.com/library/novel/stand_the.html
75	60	0451528956	The Strange Case of Dr. Jekyll and Mr. Hyde	Stevenson’s famous gothic novella, first published in 1886, and filmed countless times is better known simply as Jekyll and Hyde. The first novel to toy with the idea of a split personality, it features the respectable Dr. Jekyll transforming himself into the evil Mr Hyde in a failed attempt to learn more about the duality of man.
71	58	0020442203	The Lion, the Witch and the Wardrobe	Four adventurous siblings—Peter, Susan, Edmund, and Lucy Pevensie—step through a wardrobe door and into the land of Narnia, a land frozen in eternal winter and enslaved by the power of the White Witch. But when almost all hope is lost, the return of the Great Lion, Aslan, signals a great change . . . and a great sacrifice.\r\n\r\nJourney into the land beyond the wardrobe! The Lion, the Witch and the Wardrobe is the second book in C. S. Lewis's classic fantasy series, which has been captivating readers of all ages for over sixty years. This is a stand-alone novel, but if you would like journey back to Narnia, read The Horse and His Boy, the third book in The Chronicles of Narnia.\r\n([source][1])\r\n\r\n\r\n  [1]: http://www.cslewis.com/us/books/hardcover/the-lion-the-witch-and-the-wardrobe/9780060234812/
72	59	9798373809313	Of Mice and Men	The second book in John Steinbeck’s labor trilogy, Of Mice and Men is a touching tale of two migrant laborers in search of work and eventual liberation from their social circumstances. Fiercely devoted to one another, George and Lennie plan to save up to finance their dream of someday owning a small piece of land. The pair seems unstoppable until tragedy strikes and their hopes come crashing down, forcing George to make a difficult decision regarding the welfare of his best friend.\n\nThe novel is set on a ranch in Soledad, CA. Author Frank Bergon recalls reading Of Mice and Men for the first time as a teenager living in the San Joaquin Valley and remembers how he saw “as if in a jolt of light the ordinary surroundings of [his] life become worthy of literature.” Steinbeck works to propagate the notion that meaningful stories emerge from the marginalized; that even those on the fringes of society can make deserving contributions to the literary canon.\n\nSource: http://www.steinbeck.org/about-john/his-works/\n\n\n
77	62	9780307290946	A Tale of Two Cities	A Tale of Two Cities is a historical novel published in 1859 by Charles Dickens, set in London and Paris before and during the French Revolution. The novel tells the story of the French Doctor Manette, his 18-year-long imprisonment in the Bastille in Paris, and his release to live in London with his daughter Lucie whom he had never met. The story is set against the conditions that led up to the French Revolution and the Reign of Terror. In the Introduction to the Encyclopedia of Adventure Fiction, critic Don D'Ammassa argues that it is an adventure novel because the protagonists are in constant danger of being imprisoned or killed.\n\nAs Dickens's best-known work of historical fiction, A Tale of Two Cities is said to be one of the best-selling novels of all time. In 2003, the novel was ranked 63rd on the BBC's The Big Read poll. The novel has been adapted for film, television, radio, and the stage, and has continued to influence popular culture.
78	63	0486436772	Ivanhoe	The father of the historical novel, Sir Walter Scott invented a literary form that has remained popular for over one hundred and fifty years. Infusing his works with romance, action, and suspense, he brought long-gone eras back to life with splendor and spectacle.Set in England just after the Third Crusade, Ivanhoe is the tale of Wilfrid, a young Saxon knight, and his love for the royal princess Rowena. With his father against their union, Wilfrid embarks on a series of adventures to prove his worth, finding himself in conflict against the Normans and the Templars, and allied with such larger-than-life figures as Robin Hood and Richard the Lion Hearted. A timeless story of courage, chivalry, and courtly love, Ivanhoe is a grand epic, and its place in classical literature is assured.
79	64	0008520038	Foundation	One of the great masterworks of science fiction, the Foundation novels of Isaac Asimov are unsurpassed for their unique blend of nonstop action, daring ideas, and extensive world-building. \n\nThe story of our future begins with the history of Foundation and its greatest psychohistorian: Hari Seldon.  For twelve thousand years the Galactic Empire has ruled supreme. Now it is dying.  Only Hari Seldon, creator of the revolutionary science of psychohistory, can see into the future--a dark age of ignorance, barbarism, and warfare that will last thirty thousand years. To preserve knowledge and save mankind, Seldon gathers the best minds in the Empire--both scientists and scholars--and brings them to a bleak planet at the edge of the Galaxy to serve as a beacon of hope for future generations. He calls his sanctuary the Foundation.\n\nBut soon the fledgling Foundation finds itself at the mercy of corrupt warlords rising in the wake of the receding Empire. And mankind's last best hope is faced with an agonizing choice: submit to the barbarians and live as slaves--or take a stand for freedom and risk total destruction.
80	65	0441007465	Neuromancer	The first of William Gibson's Sprawl trilogy, *Neuromancer* is the classic cyberpunk novel. The winner of the Hugo, Nebula, and Philip K. Dick Awards, *Neuromancer* was the first fully-realized glimpse of humankind’s digital future — a shocking vision that has challenged our assumptions about our technology and ourselves, reinvented the way we speak and think, and forever altered the landscape of our imaginations.\n\nHenry Dorsett Case was the sharpest data-thief in the business, until vengeful former employees crippled his nervous system. But now a new and very mysterious employer recruits him for a last-chance run. The target: an unthinkably powerful artificial intelligence orbiting Earth in service of the sinister Tessier-Ashpool business clan. With a dead man riding shotgun and Molly, mirror-eyed street-samurai, to watch his back, Case embarks on an adventure that ups the ante on an entire genre of fiction.\n\nHotwired to the leading edges of art and technology, *Neuromancer* is a cyberpunk, science fiction masterpiece — a classic that ranks with *1984* and *Brave New World* as one of the twentieth century’s most potent visions of the future.
81	66	039551598X	The Things They Carried	*The Things They Carried* (1990) is a collection of linked short stories by American novelist Tim O'Brien, about a platoon of American soldiers fighting on the ground in the Vietnam War. His third book about the war, it is based upon his experiences as a soldier in the 23rd Infantry Division.
82	67	0140184503	Go Tell It on the Mountain	In one of the greatest American classics, Baldwin chronicles a fourteen-year-old boy's discovery of the terms of his identity. Baldwin's rendering of his protagonist's spiritual, sexual, and moral struggle of self-invention opened new possibilities in the American language and in the way Americans understand themselves.\n\nWith lyrical precision, psychological directness, resonating symbolic power, and a rage that is at once unrelenting and compassionate, Baldwin tells the story of the stepson of the minister of a storefront Pentecostal church in Harlem one Saturday in March of 1935. Originally published in 1953, Baldwin said of his first novel, "Mountain is the book I had to write if I was ever going to write anything else."
85	70	0140181725	At Swim-Two-Birds	Flann O'Brien's first novel is a brilliant impressionistic jumble of ideas, mythology and nonsense. Operating on many levels it incorporates plots within plots, giving full rein to O'Brien's dancing intellect and Celtic wit. The undergraduate narrator lives with his uncle in Dublin, drinks too much with his friends and invents stories peopled with hilarious and unlikely characters, one of whom, in a typical O'Brien conundrum, creates a means by which women can give birth to full-grown people. Flann O'Brien's blend of farce, satire and fantasy result in a remarkable, astonishingly innovative book.
86	71	0822492202	The Moonstone	One of the first English detective novels, this mystery involves the disappearance of a valuable diamond, originally stolen from a Hindu idol, given to a young woman on her eighteenth birthday, and then stolen again. A classic of 19th-century literature.
87	54	0330447556	The Road	Cormac McCarthy's tenth novel, The Road, is his most harrowing yet deeply personal work. Some unnamed catastrophe has scourged the world to a burnt-out cinder, inhabited by the last remnants of mankind and a very few surviving dogs and fungi. The sky is perpetually shrouded by dust and toxic particulates; the seasons are merely varied intensities of cold and dampness. Bands of cannibals roam the roads and inhabit what few dwellings remain intact in the woods.\n\nThrough this nightmarish residue of America a haggard father and his young son attempt to flee the oncoming Appalachian winter and head towards the southern coast along carefully chosen back roads. Mummified corpses are their only benign companions, sitting in doorways and automobiles, variously impaled or displayed on pikes and tables and in cake bells, or they rise in frozen poses of horror and agony out of congealed asphalt. The boy and his father hope to avoid the marauders, reach a milder climate, and perhaps locate some remnants of civilization still worthy of that name. They possess only what they can scavenge to eat, and the rags they wear and the heat of their own bodies are all the shelter they have. A pistol with only a few bullets is their only defense besides flight. Before them the father pushes a shopping cart filled with blankets, cans of food and a few other assets, like jars of lamp oil or gasoline siphoned from the tanks of abandoned vehicles—the cart is equipped with a bicycle mirror so that they will not be surprised from behind.\n\nThrough encounters with other survivors brutal, desperate or pathetic, the father and son are both hardened and sustained by their will, their hard-won survivalist savvy, and most of all by their love for each other. They struggle over mountains, navigate perilous roads and forests reduced to ash and cinders, endure killing cold and freezing rainfall. Passing through charred ghost towns and ransacking abandoned markets for meager provisions, the pair battle to remain hopeful. They seek the most rudimentary sort of salvation. However, in The Road, such redemption as might be permitted by their circumstances depends on the boy’s ability to sustain his own instincts for compassion and empathy in opposition to his father’s insistence upon their mutual self-interest and survival at all physical and moral costs.\n\nThe Road was the winner of the 2006 Pulitzer Prize for Literature.\n([source][1])\n\n\n  [1]: https://www.cormacmccarthy.com/works/the-road/
88	72	0062502182	The Alchemist	Combining magic, mysticism, wisdom and wonder into an inspiring tale of self-discovery, The Alchemist has become a modern classic, selling millions of copies around the world and transforming the lives of countless readers across generations.\n\nPaulo Coelho's masterpiece tells the mystical story of Santiago, an Andalusian shepherd boy who yearns to travel in search of a worldly treasure. His quest will lead him to riches far different—and far more satisfying—than he ever imagined. Santiago's journey teaches us about the essential wisdom of listening to our hearts, of recognizing opportunity and learning to read the omens strewn along life's path, and, most importantly, to follow our dreams.
90	73	0672510278	Leviathan	Thomas Hobbes' Leviathan, from 1651, is one of the first and most influential arguments towards social contract. Written in the midst of the English Civil War, it concerns the structure of government and society and argues for strong central governance and the rule of an absolute sovereign as the way to avoid civil war and chaos.
92	75	9780393974645	Le Morte d'Arthur	**Le Morte d'Arthur** (originally spelled **Le Morte Darthur**, ungrammatical Middle French for "The Death of Arthur") is a 15th-century Middle English prose reworking by Sir Thomas Malory of tales about the legendary King Arthur, Guinevere, Lancelot, Merlin and the Knights of the Round Table—along with their respective folklore. In order to tell a "complete" story of Arthur from his conception to his death, Malory compiled, rearranged, interpreted and modified material from various French and English sources. Today, this is one of the best-known works of Arthurian literature. Many authors since the 19th-century revival of the legend have used Malory as their principal source. \n\n(Source: [Wikipedia](https://en.wikipedia.org/wiki/Le_Morte_d%27Arthur))
89	59	0434740020	East of Eden	Steinbeck considered East of Eden to be his masterpiece. In his journal, Journal of a Novel (often read as a companion to the novel) he notes that “this is the book I have always wanted and have worked and prayed to be able to write Set primarily in the Salinas Valley in the early twentieth century, the novel traces three generations of two families – the Trasks and the Hamiltons – as they grapple with the ever-present forces of good and evil. From this plot emerged some of Steinbeck’s most fascinating characters – many of whom are modeled after people in his own life.\r\n\r\nPart allegory, part autobiography, and part epic, East of Eden was an ambitious project from the start – a gift to Steinbeck’s sons that was meant to teach them about identity, grief, and what it means to be human. Tinged with biblical echoes of the fall of Adam and Eve and the rivalry of Cain and Abel, this sprawling saga has captivated audiences everywhere for generations. It is through the popularization of East of Eden that the Salinas Valley was truly transformed into “the valley of the world”; a place where everyone is able to find a piece of themselves in the golden, rolling hills.
70	57	950547072X	A Wizard of Earthsea	The first novel of Ursula K. Le Guin's must-read Earthsea Cycle. "The magic of Earthsea is primal; the lessons of Earthsea remain as potent, as wise, and as necessary as anyone could dream." (Neil Gaiman)\r\n\r\nGed was the greatest sorcerer in Earthsea, but in his youth he was the reckless Sparrowhawk. In his hunger for power and knowledge, he tampered with long-held secrets and loosed a terrible shadow upon the world.\r\n\r\nThis is the tumultuous tale of his testing, how he mastered the mighty words of power, tamed an ancient dragon, and crossed death's threshold to restore the balance.\r\n\r\nWith stories as perennial and universally beloved as The Chronicles of Narnia and The Lord of The Rings—but also unlike anything but themselves—Ursula K. Le Guin’s Earthsea novels are some of the most acclaimed and awarded works in literature. They have received accolades such as the National Book Award, a Newbery Honor, the Nebula Award, and many more honors, commemorating their enduring place in the hearts and minds of readers and the literary world alike.\r\n\r\nJoin the millions of fantasy readers who have explored these lands. As The Guardian put it: "Ursula Le Guin's world of Earthsea is a tangled skein of tiny islands cast on a vast sea. The islands' names pull at my heart like no others: Roke, Perilane, Osskil.
93	76	226611140X	The Colour of Magic	Terry Pratchett's profoundly irreverent novels are consistent number one bestsellers in England, where they have garnered him a revered position in the halls of parody next to Mark Twain, Kurt Vonnegut, Douglas Adams, and Carl Hiaasen.The Color of Magic is Terry Pratchett's maiden voyage through the now-legendary land of Discworld. This is where it all begins--with the tourist Twoflower and his wizard guide, Rincewind.
94	77	0765356155	Jonathan Strange and Mr. Norrell	Published in 2004, it is an alternative history set in 19th-century England around the time of the Napoleonic Wars. Its premise is that magic once existed in England and has returned with two men: Gilbert Norrell and Jonathan Strange. Centred on the relationship between these two men, the novel investigates the nature of "Englishness" and the boundaries between reason and unreason, Anglo-Saxon and Anglo-Dane, and Northern and Southern English cultural tropes/stereotypes. It has been described as a fantasy novel, an alternative history, and a historical novel. It inverts the Industrial Revolution conception of the North-South divide in England: in this book the North is romantic and magical, rather than rational and concrete.
95	78	0380973650	American Gods	American Gods (2001) is a fantasy novel by British author Neil Gaiman. The novel is a blend of Americana, fantasy, and various strands of ancient and modern mythology, all centering on the mysterious and taciturn Shadow.
96	78	8418637404	Coraline	When Coraline steps through a door to find another house strangely similar to her own (only better), things seem marvelous.\n\nBut there's another mother there, and another father, and they want her to stay and be their little girl. They want to change her and never let her go.\n\nCoraline will have to fight with all her wit and courage if she is to save herself and return to her ordinary life.
97	78	1401265197	The Sandman - Overture	Presents the Sandman's origin story from the birth of a galaxy to the moment that Morpheus is captured.\n\n set the standard for mature, lyrical fantasy in the modern comics era. Illustrated by an exemplary selection of the medium's most gifted artists, the series is a rich blend of modern and ancient mythology in which contemporary fiction, historical drama, and legend are seamlessly interwoven.\n\n*Overture* brings Gaiman's mesmerizing saga of the Sandman full circle, serving as both a prequel and a coda to the groundbreaking original series. Lushly illustrated by acclaimed artist J.H. Williams III, this stunning tale follows the King of Dreams as he travels across the universe--and into realms unbounded by time and space--on a fateful mission to prevent all of reality from unraveling.
117	78	3453137574	Neverwhere	Richard Mayhew is an ordinary young man with an ordinary life and a good heart. His world is changed forever when he stops to help a girl he finds bleeding on a London sidewalk. This small kindness propels him into a dark world he never dreamed existed. He must learn to survive in London Below, in a world of perpetual shadows and darkness, filled with monsters and saints, murderers and angels. He must survive if he is ever to return to the London that he knew.
199	165	0140621318	The Prisoner of Zenda	An adventure novel, originally published in 1894, set in the fictitious European Kingdom of Ruritania. An English tourist is persuaded to impersonate the new king after he is abducted before he can be crowned. This act draws upon him the wrath of the Prince who has had the king abducted and his partner in crime the villainous Rupert of Hentzau.
98	79	0333781724	Perdido Street Station	Beneath the towering bleached ribs of a dead, ancient beast lies New Crobuzon, a squalid city where humans, Re-mades, and arcane races live in perpetual fear of Parliament and its brutal militia. The air and rivers are thick with factory pollutants and the strange effluents of alchemy, and the ghettos contain a vast mix of workers, artists, spies, junkies, and whores. In New Crobuzon, the unsavory deal is stranger to none—not even to Isaac, a brilliant scientist with a penchant for Crisis Theory.\n\nIsaac has spent a lifetime quietly carrying out his unique research. But when a half-bird, half-human creature known as the Garuda comes to him from afar, Isaac is faced with challenges he has never before fathomed. Though the Garuda's request is scientifically daunting, Isaac is sparked by his own curiosity and an uncanny reverence for this curious stranger.\n\nWhile Isaac's experiments for the Garuda turn into an obsession, one of his lab specimens demands attention: a brilliantly colored caterpillar that feeds on nothing but a hallucinatory drug and grows larger—and more consuming—by the day. What finally emerges from the silken cocoon will permeate every fiber of New Crobuzon—and not even the Ambassador of Hell will challenge the malignant terror it invokes . . .\n\nA magnificent fantasy rife with scientific splendor, magical intrigue, and wonderfully realized characters, told in a storytelling style in which Charles Dickens meets Neal Stephenson, Perdido Street Station offers an eerie, voluptuously crafted world that will plumb the depths of every reader's imagination.
99	80	0747542988	Harry Potter and the Philosopher's Stone	When mysterious letters start arriving on his doorstep, Harry Potter has never heard of Hogwarts School of Witchcraft and Wizardry.\n\nThey are swiftly confiscated by his aunt and uncle.\n\nThen, on Harry’s eleventh birthday, a strange man bursts in with some important news: Harry Potter is a wizard and has been awarded a place to study at Hogwarts.\n\nAnd so the first of the Harry Potter adventures is set to begin.\n([source][1])\n\n\n  [1]: https://www.jkrowling.com/book/harry-potter-philosophers-stone/
100	81	0575077859	The Blade Itself	Logen Ninefingers, infamous barbarian, has finally run out of luck. Caught in one feud too many, he’s on the verge of becoming a dead barbarian – leaving nothing behind him but bad songs, dead friends, and a lot of happy enemies.\nNobleman Captain Jezal dan Luthar, dashing officer, and paragon of selfishness, has nothing more dangerous in mind than fleecing his friends at cards and dreaming of glory in the fencing circle. But war is brewing, and on the battlefields of the frozen North they fight by altogether bloodier rules.\n\nInquisitor Glokta, cripple turned torturer, would like nothing better than to see Jezal come home in a box. But then Glokta hates everyone: cutting treason out of the Union one confession at a time leaves little room for friendship. His latest trail of corpses may lead him right to the rotten heart of government, if he can stay alive long enough to follow it.\n\nEnter the wizard, Bayaz. A bald old man with a terrible temper and a pathetic assistant, he could be the First of the Magi, he could be a spectacular fraud, but whatever he is, he's about to make the lives of Logen, Jezal, and Glotka a whole lot more difficult.\n\nMurderous conspiracies rise to the surface, old scores are ready to be settled, and the line between hero and villain is sharp enough to draw blood.
101	82	226611185X	The Eye of the World (The Wheel of Time Book 1)	The Wheel of Time turns and Ages come and go, leaving memories that become legend. Legend fades to myth, and even myth is long forgotten when the Age that gave it birth returns again. In the Third Age, an Age of Prophecy, the World and Time themselves hang in the balance. What was, what will be, and what is, may yet fall under the Shadow.
102	78	0060853980	Good Omens	Armageddon only happens once, you know. They don't let you go around again until you get it right.\n\nAccording to the Nice and Accurate Prophecies of Agnes Nutter, Witch - the world's only totally reliable guide to the future, written in 1655, before she exploded - the world will end on a Saturday.\n\nNext Saturday, in fact. Just after tea...\n\nPeople have been predicting the end of the world almost from its very beginning, so it's only natural to be sceptical when a new date is set for Judgement Day.\n\nThis time though, the armies of Good and Evil really do appear to be massing. The four Bikers of the Apocalypse are hitting the road. But both the angels and demons - well, one fast-living demon and a somewhat fussy angel - would quite like the Rapture not to happen.\n\nOh, and someone seems to have misplaced the Antichrist...
104	84	342670272X	Kushiel's dart	The land of Terre d'Ange is a place of unsurpassing beauty and grace. It is said that angels found the land and saw it was good... and the ensuing race that rose from the seed of angels and men live by one simple rule: Love as thou wilt.\n\nPhèdre nó Delaunay is a young woman who was born with a scarlet mote in her left eye. Sold into indentured servitude as a child, her bond is purchased by Anafiel Delaunay, a nobleman with very a special mission... and the first one to recognize who and what she is: one pricked by Kushiel's Dart, chosen to forever experience pain and pleasure as one.\n\nPhèdre is trained equally in the courtly arts and the talents of the bedchamber, but, above all, the ability to observe, remember, and analyze. Almost as talented a spy as she is courtesan, Phèdre stumbles upon a plot that threatens the very foundations of her homeland. Treachery sets her on her path; love and honor goad her further. And in the doing, it will take her to the edge of despair... and beyond. Hateful friend, loving enemy, beloved assassin; they can all wear the same glittering mask in this world, and Phèdre will get but one chance to save all that she holds dear.\n\nSet in a world of cunning poets, deadly courtiers, heroic traitors, and a truly Machiavellian villainess, this is a novel of grandeur, luxuriance, sacrifice, betrayal, and deeply laid conspiracies. Not since Dune has there been an epic on the scale of Kushiel's Dart-a massive tale about the violent death of an old age, and the birth of a new.
106	1	9783129079706	The Silmarillion	A number-one New York Times bestseller when it was originally published, The Silmarillion is the core of J.R.R. Tolkien's imaginative writing, a work whose origins stretch back to a time long before The Hobbit.
107	86	1857231511	The Sword of Shannara	A young man and his brother set out on a journey to find the magical "Sword of Shannara".  Only the mystical sword can defeat the evil overlord and his minions.
108	87	0316556335	Circe	In the house of Helios, god of the sun and mightiest of the Titans, a daughter is born. But Circe is a strange child--not powerful, like her father, nor viciously alluring like her mother. Turning to the world of mortals for companionship, she discovers that she does possess power--the power of witchcraft, which can transform rivals into monsters and menace the gods themselves.\n\nThreatened, Zeus banishes her to a deserted island, where she hones her occult craft, tames wild beasts and crosses paths with many of the most famous figures in all of mythology, including the Minotaur, Daedalus and his doomed son Icarus, the murderous Medea, and, of course, wily Odysseus.\n\nBut there is danger, too, for a woman who stands alone, and Circe unwittingly draws the wrath of both men and gods, ultimately finding herself pitted against one of the most terrifying and vengeful of the Olympians. To protect what she loves most, Circe must summon all her strength and choose, once and for all, whether she belongs with the gods she is born from, or the mortals she has come to love.\n\nWith unforgettably vivid characters, mesmerizing language and page-turning suspense, Circe is a triumph of storytelling, an intoxicating epic of family rivalry, palace intrigue, love and loss, as well as a celebration of indomitable female strength in a man's world.\n([source][1])\n\n\n  [1]: http://madelinemiller.com/circe/
125	100	0201485370	Design Patterns	Four software designers present a catalog of simple and succinct solutions to commonly occurring design problems, using Smalltalk and C++ in example code. These 23 patterns allow designers to create more flexible, elegant, and ultimately reusable designs without having to rediscover the design solutions themselves. The authors begin by describing what patterns are and how they can help you design object-oriented software. They go on to systematically name, explain, evaluate, and catalog recurring designs in object-oriented systems.
13	12	8493416738	Don Quixote	Widely regarded as one of the funniest and most tragic books ever written, Don Quixote chronicles the adventures of the self-created knight-errant Don Quixote of La Mancha and his faithful squire, Sancho Panza, as they travel through sixteenth-century Spain.
105	85	0812521390	The Black Company (The Chronicles of the Black Company #1)	Some feel the Lady, newly risen from centuries in thrall, stands between humankind and evil. Some feel she is evil itself. The hard-bitten men of the Black Company take their pay and do what they must, burying their doubts with their dead. Until the prophesy: The White Rose has been reborn, somewhere, to embody good once more. There must be a way for the Black Company to find her... So begins one of the greatest fantasy epics of our age—Glen Cook's Chronicles of the Black Company.
110	78	6057762800	The Ocean at the End of the Lane	A middle-aged man returns to his childhood home to attend a funeral. Although the house he lived in is long gone, he is drawn to the farm at the end of the road, where, when he was seven, he encountered a most remarkable girl, Lettie Hempstock, and her mother and grandmother. He hasn't thought of Lettie in decades, and yet as he sits by the pond (a pond that she'd claimed was an ocean) behind the ramshackle old farmhouse, the unremembered past comes flooding back. And it is a past too strange, too frightening, too dangerous to have happened to anyone, let alone a small boy.\n\nForty years earlier, a man committed suicide in a stolen car at this farm at the end of the road. Like a fuse on a firework, his death lit a touchpaper and resonated in unimaginable ways. The darkness was unleashed, something scary and thoroughly incomprehensible to a little boy. And Lettie—magical, comforting, wise beyond her years—promised to protect him, no matter what.\n\nA groundbreaking work from a master, The Ocean at the End of the Lane is told with a rare understanding of all that makes us human, and shows the power of stories to reveal and shelter us from the darkness inside and out. It is a stirring, terrifying, and elegiac fable as delicate as a butterfly's wing and as menacing as a knife in the dark.
111	89	0062662562	The Poppy War	A brilliantly imaginative talent makes her exciting debut with this epic historical military fantasy, inspired by the bloody history of China’s twentieth century and filled with treachery and magic, in the tradition of Ken Liu’s Grace of Kings and N.K. Jemisin’s Inheritance Trilogy.\n\nWhen Rin aced the Keju—the Empire-wide test to find the most talented youth to learn at the Academies—it was a shock to everyone: to the test officials, who couldn’t believe a war orphan from Rooster Province could pass without cheating; to Rin’s guardians, who believed they’d finally be able to marry her off and further their criminal enterprise; and to Rin herself, who realized she was finally free of the servitude and despair that had made up her daily existence. That she got into Sinegard—the most elite military school in Nikan—was even more surprising.\n\nBut surprises aren’t always good.\n\nBecause being a dark-skinned peasant girl from the south is not an easy thing at Sinegard. Targeted from the outset by rival classmates for her color, poverty, and gender, Rin discovers she possesses a lethal, unearthly power—an aptitude for the nearly-mythical art of shamanism. Exploring the depths of her gift with the help of a seemingly insane teacher and psychoactive substances, Rin learns that gods long thought dead are very much alive—and that mastering control over those powers could mean more than just surviving school.\n\nFor while the Nikara Empire is at peace, the Federation of Mugen still lurks across a narrow sea. The militarily advanced Federation occupied Nikan for decades after the First Poppy War, and only barely lost the continent in the Second. And while most of the people are complacent to go about their lives, a few are aware that a Third Poppy War is just a spark away . . .\n\nRin’s shamanic powers may be the only way to save her people. But as she finds out more about the god that has chosen her, the vengeful Phoenix, she fears that winning the war may cost her humanity . . . and that it may already be too late.
112	90	0575024801	Dreamsnake	In a world devastated by nuclear holocaust, Snake is a healer. One of an elite band dedicated to caring for sick humanity, she goes wherever her skills are needed.\n\nWith her she takes the three deadly reptiles through which her cures are accomplished: a cobra, a rattlesnake, and the dreamsnake, a creature whose hallucinogenic venom brings not healing but an easeful death for the terminally ill.\n\nRare and valuable is this dreamsnake. When Grass is wantonly slain, Snake must journey across perilous landscapes to find another to take its place...
113	91	1408883465	The Priory of the Orange Tree	A world divided. A queendom without an heir. An ancient enemy awakens.\n\nThe House of Berethnet has ruled Inys for a thousand years. Still unwed, Queen Sabran the Ninth must conceive a daughter to protect her realm from destruction – but assassins are getting closer to her door.\n\nEad Duryan is an outsider at court. Though she has risen to the position of lady-in-waiting, she is loyal to a hidden society of mages. Ead keeps a watchful eye on Sabran, secretly protecting her with forbidden magic.\n\nAcross the dark sea, Tané has trained to be a dragonrider since she was a child, but is forced to make a choice that could see her life unravel.\n\nMeanwhile, the divided East and West refuse to parley, and forces of chaos are rising from their sleep.
114	92	9781250313072	Ninth House	Galaxy “Alex” Stern is the most unlikely member of Yale’s freshman class. Raised in the Los Angeles hinterlands by a hippie mom, Alex dropped out of school early and into a world of shady drug dealer boyfriends, dead-end jobs, and much, much worse. By age twenty, in fact, she is the sole survivor of a horrific, unsolved multiple homicide. Some might say she’s thrown her life away. But at her hospital bed, Alex is offered a second chance: to attend one of the world’s most elite universities on a full ride. What’s the catch, and why her?\n\nStill searching for answers to this herself, Alex arrives in New Haven tasked by her mysterious benefactors with monitoring the activities of Yale’s secret societies. These eight windowless “tombs” are well-known to be haunts of the future rich and powerful, from high-ranking politicos to Wall Street and Hollywood’s biggest players. But their occult activities are revealed to be more sinister and more extraordinary than any paranoid imagination might conceive.
116	94	0152008691	The Forgotten Beasts of Eld	Young Sybel, the heiress of powerful wizards, needs the company of no-one outside her gates. In her exquisite stone mansion, she is attended by exotic, magical beasts: Riddle-master Cyrin the boar; the treasure-starved dragon Gyld; Gules the Lyon, tawny master of the Southern Deserts; Ter, the fiercely vengeful falcon; Moriah, feline Lady of the Night. Sybel only lacks the exquisite and mysterious Liralen, which continues to elude her most powerful enchantments.\n\nBut when a soldier bearing an infant arrives, Sybel discovers that the world of man and magic is full of both love and deceit―and the possibility of more power than she can possibly imagine.
118	95	0394498216	Interview With the Vampire	This is the story of Louis, as told in his own words, of his journey through mortal and immortal life. Louis recounts how he became a vampire at the hands of the radiant and sinister Lestat and how he became indoctrinated, unwillingly, into the vampire way of life. His story ebbs and flows through the streets of New Orleans, defining crucial moments such as his discovery of the exquisite lost young child Claudia, wanting not to hurt but to comfort her with the last breaths of humanity he has inside. Yet, he makes Claudia a vampire, trapping her womanly passion, will, and intelligence inside the body of a small child. Louis and Claudia form a seemingly unbreakable alliance and even "settle down" for a while in the opulent French Quarter. Louis remembers Claudia's struggle to understand herself and the hatred they both have for Lestat that sends them halfway across the world to seek others of their kind. Louis and Claudia are desperate to find somewhere they belong, to find others who understand, and someone who knows what and why they are.\n\nLouis and Claudia travel Europe, eventually coming to Paris and the ragingly successful Theatre des Vampires--a theatre of vampires pretending to be mortals pretending to be vampires. Here they meet the magnetic and ethereal Armand, who brings them into a whole society of vampires. But Louis and Claudia find that finding others like themselves provides no easy answers and in fact presents dangers they scarcely imagined.\n\nOriginally begun as a short story, the book took off as Anne wrote it, spinning the tragic and triumphant life experiences of a soul. As well as the struggles of its characters, Interview captures the political and social changes of two continents. The novel also introduces Lestat, Anne's most enduring character, a heady mixture of attraction and revulsion. The book, full of lush description, centers on the themes of immortality, change, loss, sexuality, and power.\n([source][1])\n\n\n  [1]: http://annerice.com/Bookshelf-Interview.html
119	96	0689840357	Over Sea, Under Stone (The Dark Is Rising #1)	On holiday in Cornwall, the three Drew children discover an ancient map in the attic of the house that they are staying in. They know immediately that it is special. It is even more than that -- the key to finding a grail, a source of power to fight the forces of evil known as the Dark. And in searching for it themselves, the Drews put their very lives in peril. \nThis is the first volume of Susan Cooper's brilliant and absorbing fantasy sequence known as The Dark Is Rising.
120	96	0689851952	The Dark Is Rising (Dark is Rising #2)	On his eleventh birthday Will Stanton discovers that he is the last of the Old Ones, destined to seek the six magical Signs that will enabee the Old Ones to triumph over the evil forces of the Dark.
121	97	0143110918	Behave	Why do we do the things we do?\n\nOver a decade in the making, this game-changing book is Robert Sapolsky's genre-shattering attempt to answer that question as fully as perhaps only he could, looking at it from every angle. Sapolsky's storytelling concept is delightful but it also has a powerful intrinsic logic: he starts by looking at the factors that bear on a person's reaction in the precise moment a behavior occurs, and then hops back in time from there, in stages, ultimately ending up at the deep history of our species and its genetic inheritance.\n\nAnd so the first category of explanation is the neurobiological one. What goes on in a person's brain a second before the behavior happens? Then he pulls out to a slightly larger field of vision, a little earlier in time: What sight, sound, or smell triggers the nervous system to produce that behavior? And then, what hormones act hours to days earlier to change how responsive that individual is to the stimuli which trigger the nervous system? By now, he has increased our field of vision so that we are thinking about neurobiology and the sensory world of our environment and endocrinology in trying to explain what happened.\n\nSapolsky keeps going--next to what features of the environment affected that person's brain, and then back to the childhood of the individual, and then to their genetic makeup. Finally, he expands the view to encompass factors larger than that one individual. How culture has shaped that individual's group, what ecological factors helped shape that culture, and on and on, back to evolutionary factors thousands and even millions of years old.\n\nThe result is one of the most dazzling tours de horizon of the science of human behavior ever attempted, a majestic synthesis that harvests cutting-edge research across a range of disciplines to provide a subtle and nuanced perspective on why we ultimately do the things we do...for good and for ill. Sapolsky builds on this understanding to wrestle with some of our deepest and thorniest questions relating to tribalism and xenophobia, hierarchy and competition, morality and free will, and war and peace. Wise, humane, often very funny, Behave is a towering achievement, powerfully humanizing, and downright heroic in its own right.\n\nSource: Publisher
122	97	9780525560975	Determined	Biologically-based arguments for determinism and against free will, and what the other side of that rainbow looks like.
123	98	1501134612	Midnight in Chernobyl	"Journalist Adam Higginbotham's definitive, years-in-the-making account of the Chernobyl nuclear power plant disaster--and a powerful investigation into how propaganda, secrecy, and myth have obscured the true story of one of the twentieth century's greatest disasters. Early in the morning of April 26, 1986, Reactor Number Four of the Chernobyl Atomic Energy Station exploded, triggering history's worst nuclear disaster. In the thirty years since then, Chernobyl has become lodged in the collective nightmares of the world: shorthand for the spectral horrors of radiation poisoning, for a dangerous technology slipping its leash, for ecological fragility, and for what can happen when a dishonest and careless state endangers its citizens and the entire world. But the real story of the accident, clouded from the beginning by secrecy, propaganda, and misinformation, has long remained in dispute. Drawing on hundreds of hours of interviews conducted over the course of more than ten years, as well as letters, unpublished memoirs, and documents from recently-declassified archives, Adam Higginbotham has written a harrowing and compelling narrative which brings the disaster to life through the eyes of the men and women who witnessed it firsthand. The result is a masterful nonfiction thriller, and the definitive account of an event that changed history: a story that is more complex, more human, and more terrifying than the Soviet myth. Midnight in Chernobyl is an indelible portrait of one of the great disasters of the twentieth century, of human resilience and ingenuity, and the lessons learned when mankind seeks to bend the natural world to his will--lessons which, in the face of climate change and other threats, remain not just vital but necessary"--Publisher's website.
126	101	0374157359	The Dawn of Everything	The renowned activist and public intellectual David Graeber teams up with the professor of comparative archaeology David Wengrow to deliver a trailblazing account of human history, challenging our most fundamental assumptions about social evolution—from the development of agriculture and cities to the emergence of "the state," political violence, and social inequality—and revealing new possibilities for human emancipation\n\nFor generations, our remote ancestors have been cast as primitive and childlike—either free and equal innocents, or thuggish and warlike. Civilization, we are told, could be achieved only by sacrificing those original freedoms or, alternatively, by taming our baser instincts. David Graeber and David Wengrow show how such theories first emerged in the eighteenth century as a conservative reaction to powerful critiques of European society posed by Indigenous observers and intellectuals. Revisiting this encounter has startling implications for how we make sense of human history today, including the origins of farming, property, cities, democracy, slavery, and civilization itself.\n\nDrawing on pathbreaking research in archaeology and anthropology, the authors show how history becomes a far more interesting place once we learn to throw off our conceptual shackles and perceive what’s really there. If humans did not spend 95 percent of their evolutionary past in tiny bands of hunter-gatherers, what were they doing all that time? If agriculture, and cities, did not mean a plunge into hierarchy and domination, then what kinds of social and economic organization did they lead to? What was really happening during the periods that we usually describe as the emergence of "the state"? The answers are often unexpected, and suggest that the course of human history may be less set in stone, and more full of playful, hopeful possibilities, than we tend to assume.\n\nThe Dawn of Everything fundamentally transforms our understanding of the human past and offers a path toward imagining new forms of freedom, new ways of organizing society. This is a monumental book of formidable intellectual range, animated by curiosity, moral vision, and a faith in the power of direct action.
128	103	9781804220375	Thinking, Fast and Slow	In his mega bestseller, Thinking, Fast and Slow, Daniel Kahneman, world-famous psychologist and winner of the Nobel Prize in Economics, takes us on a groundbreaking tour of the mind and explains the two systems that drive the way we think.\n\nSystem 1 is fast, intuitive, and emotional; System 2 is slower, more deliberative, and more logical. The impact of overconfidence on corporate strategies, the difficulties of predicting what will make us happy in the future, the profound effect of cognitive biases on everything from playing the stock market to planning our next vacation―each of these can be understood only by knowing how the two systems shape our judgments and decisions.\n\nEngaging the reader in a lively conversation about how we think, Kahneman reveals where we can and cannot trust our intuitions and how we can tap into the benefits of slow thinking. He offers practical and enlightening insights into how choices are made in both our business and our personal lives―and how we can use different techniques to guard against the mental glitches that often get us into trouble. Topping bestseller lists for almost ten years, Thinking, Fast and Slow is a contemporary classic, an essential book that has changed the lives of millions of readers.
129	104	0593138511	Stolen Focus	Is your ability to focus and pay attention in free fall?\n\nYou are not alone. The average office worker now focuses on any one task for just three minutes. But it's not your fault. Your attention didn't collapse. It has been stolen.\n\nInternationally bestselling author Johann Hari shows twelve deep factors harming our focus. Once we understand them, together, we can take back our minds.
130	105	2226127097	Band of Brothers	Follows the 101st Airbone as it drops into Normandy on D-Day and fights its way through Europe to the end of World War II.
131	106	1250192811	Ghosts of the Tsunami	On March 11, 2011, a 120-foot-high tsunami smashed into the northeast coast of Japan, leaving more than eighteen thousand people dead. It was Japan's single greatest loss of life since the atomic bombing of Nagasaki in 1945. Richard Lloyd Parry, an award winning foreign correspondent, lived through the earthquake in Tokyo and spent six years reporting from the disaster zone. Ghosts of the Tsunami is the intimate account of an epic tragedy, told through the perspectives of those who lived through it. -- Adapted from book jacket.
132	107	1665146796	The Radium Girls	As World War I raged across the globe, hundreds of young women toiled away at the radium-dial factories, where they painted clock faces with a mysterious new substance called radium. Assured by their bosses that the luminous material was safe, the women themselves shone brightly in the dark, covered from head to toe with the glowing dust. With such a coveted job, these "shining girls" were considered the luckiest alive--until they began to fall mysteriously ill. As the fatal poison of the radium took hold, they found themselves embroiled in one of America's biggest scandals and a groundbreaking battle for workers' rights. The Radium Girls explores the strength of extraordinary women in the face of almost impossible circumstances and the astonishing legacy they left behind.
133	108	9780316053396	Crow Planet	There are more crows now than ever. Their abundance is both an indicator of ecological imbalance and a generous opportunity to connect with the animal world. CROW PLANET reminds us that we do not need to head to faraway places to encounter "nature." Rather, even in the suburbs and cities where we live we are surrounded by wild life such as crows, and through observing them we can enhance our appreciation of the world's natural order. CROW PLANET richly weaves Haupt's own "crow stories" as well as scientific and scholarly research and the history and mythology of crows, culminating in a book that is sure to make readers see the world around them in a very different way.
134	109	9781627790369	Algorithms to Live By	Algorithms to Live By looks at the simple, precise algorithms that computers use to solve the complex 'human' problems that we face, and discovers what they can tell us about the nature and origin of the mind.\r\n\r\n [1]: https://archive.org/details/AlgorithmstoLiveBy
135	110	0321934113	Peopleware	Few books in computing have had as profound an influence on software management as Peopleware. The unique insight of this longtime best seller is that the major issues of software development are human, not technical. They're not easy issues; but solve them, and youll maximize your chances of success. For this third edition, the authors have added six new chapters and updated the text throughout, bringing it in line with today's development environments and challenges. For example, the book now discusses pathologies of leadership that hadn't previously been judged to be pathological: an evolving culture of meetings: hybrid teams made up of people from seemingly incompatible generations; and a growing awareness that some of our most common tools are more like anchors than propellers. Anyone who needs to manage a software project or software organization will find invaluable advice throughout the book.
136	111	0061339202	Flow	Psychologist Mihaly Csikszentmihalyi's famous investigations of "optimal experience" have revealed that what makes an experience genuinely satisfying is a state called *flow*. During flow, people typically experience deep enjoyment, creativity, and a total involvement with life. In this new edition of his groundbreaking classic work, Csikszentmihalyi demonstrates the ways this positive state can be controlled, not just left to chance. *Flow: The Psychology of Optimal Experience* teaches how, by ordering the information that enters our consciousness, we can discover true happiness and greatly improve the quality of our lives.
137	112	067002581X	The Boys in the Boat	Daniel James Brown’s robust book tells the story of the University of Washington’s 1936 eight-oar crew and their epic quest for an Olympic gold medal, a team that transformed the sport and grabbed the attention of millions of Americans. The sons of loggers, shipyard workers, and farmers, the boys defeated elite rivals first from eastern and British universities and finally the German crew rowing for Adolf Hitler in the Olympic games in Berlin, 1936. The emotional heart of the story lies with one rower, Joe Rantz, a teenager without family or prospects, who rows not for glory, but to regain his shattered self-regard and to find a place he can call home. The crew is assembled by an enigmatic coach and mentored by a visionary, eccentric British boat builder, but it is their trust in each other that makes them a victorious team. They remind the country of what can be done when everyone quite literally pulls together—a perfect melding of commitment, determination, and optimism. Drawing on the boys’ own diaries and journals, their photos and memories of a once-in-a-lifetime shared dream, The Boys in the Boat is an irresistible story about beating the odds and finding hope in the most desperate of times—the improbable, intimate story of nine working-class boys from the American west who, in the depths of the Great Depression, showed the world what true grit really meant. It will appeal to readers of Erik Larson, Timothy Egan, James Bradley, and David Halberstam's The Amateurs.
138	113	0375508589	Shadow Divers	Shadow Divers is a riveting true adventure in which two weekend scuba divers risk everything to solve a great historical mystery–and make history themselves.\n\nFor John Chatterton and Richie Kohler, deep wreck diving was more than a sport. Testing themselves against treacherous currents, braving depths that induced hallucination, navigating through a minefield of perilous wreckage, they pushed themselves to their limits and beyond, brushing against death often in the rusting hulks of sunken ships.\n\nBut in 1991, not even these bold divers were prepared for what they found 230 feet below the surface, in the frigid Atlantic waters sixty miles off the New Jersey coast: a World War II German U-boat, its ruined interior a macabre wasteland of twisted metal, tangled wires, and human bones–all buried under decades of sediment.\n\nOver the next six years, an elite team of divers embarked on a quest to solve the mystery. Some would not live to see its end. Chatterton and Kohler, at first bitter rivals, would be drawn into a friendship that deepened to an almost mystical sense of brotherhood with each other and the drowned U-boat sailors–former enemies of their country. As the men’s marriages frayed under the pressure of a shared obsession, their dives grew more daring, and each realized that he was hunting more than the identities of a lost U-boat and its nameless crew.\n\nShadow Divers spent 24 weeks on the New York Times Bestseller list, peaking at #2. The book was awarded the American Booksellers Association’s 2005 “Book of the Year Award,” and has been translated into 22 languages.\n([source][1])\n\n  [1]: https://www.robertkurson.com/shadow-divers/
139	114	9780141036250	Outliers	In this stunning new book, Malcolm Gladwell takes us on an intellectual journey through the world of "outliers"--the best and the brightest, the most famous and the most successful. He asks the question: what makes high-achievers different? His answer is that we pay too much attention to what successful people are like, and too little attention to where they are from: that is, their culture, their family, their generation, and the idiosyncratic experiences of their upbringing. Along the way he explains the secrets of software billionaires, what it takes to be a great soccer player, why Asians are good at math, and what made the Beatles the greatest rock band.  Brilliant and entertaining, OUTLIERS is a landmark work that will simultaneously delight and illuminate.
140	114	9708120286	Blink	Intuition is not some magical property that arises unbidden from the depths of our mind. It is a product of long hours and intelligent design, of meaningful work environments and particular rules and principles. This book shows us how we can hone our instinctive ability to know in an instant, helping us to bring out the best in our thinking and become better decision-makers in our homes, offices and in everyday life. Just as he did with his revolutionary theory of the tipping point, Gladwell reveals how the power of 'blink' could fundamentally transform our relationships, the way we consume, create and communicate, how we run our businesses and even our societies.You'll never think about thinking in the same way again.
141	56	0684853523	On Writing	On Writing is both a textbook for writers and a memoir of Stephen's life and will, thus, appeal even to those who are not aspiring writers. If you've always wondered what led Steve to become a writer and how he came to be the success he is today, this will answer those questions.\n\n([source][1])\n\n\n  [1]: https://stephenking.com/library/nonfiction/on_writing_a_memoir_of_the_craft.html
142	115	0393609391	Astrophysics for People in a Hurry	A short book for almost all ages, it’s simply astrophysics for people in a hurry, taught by acclaimed astrophysicist Neil deGrasse Tyson. This is a must-read for anyone who wants to know how the universe works!
144	117	1844081818	The Glass Castle	A story about the early life of Jeannette Walls. The memoir is an exposing work about her early life and growing up on the run and often homeless. It presents a different perspective of life from all over the United States and the struggle a girl had to find normalcy as she grew into an adult.
145	118	1439107955	The Emperor of All Maladies	The Emperor of All Maladies: A Biography of Cancer is a book written by Siddhartha Mukherjee, an Indian-born American physician and oncologist. Published on 16 November 2010 by Scribner, it won the 2011 Pulitzer Prize for General Non-Fiction.
146	119	1101971444	The Monk of Mokha	The true story of a young Yemeni-American man, raised in San Francisco, who dreams of resurrecting the ancient art of Yemeni coffee but finds himself trapped in Sana a by civil war.
147	120	8535919716	Steve Jobs	Based on more than forty interviews with Jobs conducted over two years -- as well as interviews with more than a hundred family members, friends, adversaries, competitors, and colleagues -- Walter Isaacson has written a riveting story of the roller-coaster life and searingly intense personality of a creative entrepreneur whose passion for perfection and ferocious drive revolutionized six industries: personal computers, animated movies, music, phones, tablet computing, and digital publishing. At a time when America is seeking ways to sustain its innovative edge, and when societies around the world are trying to build digital-age economies, Jobs stands as the ultimate icon of inventiveness and applied imagination. He knew that the best way to create value in the twenty-first century was to connect creativity with technology. He built a company where leaps of the imagination were combined with remarkable feats of engineering. Although Jobs cooperated with this book, he asked for no control over what was written nor even the right to read it before it was published. He put nothing off-limits. He encouraged the people he knew to speak honestly. And Jobs speaks candidly, sometimes brutally so, about the people he worked with and competed against. His friends, foes, and colleagues provide an unvarnished view of the passions, perfectionism, obsessions, artistry, devilry, and compulsion for control that shaped his approach to business and the innovative products that resulted. Driven by demons, Jobs could drive those around him to fury and despair. But his personality and products were interrelated, just as Apple's hardware and software tended to be, as if part of an integrated system. His tale is instructive and cautionary, filled with lessons about innovation, character, leadership, and values. - Publisher.
148	120	1797117041	The Code Breaker	A scientific biography of Jennifer Doudna, a founder and co-developer of the CRISPR gene-editing mechanism, and an examination of what happened after CRISPR hit the marketplace.
149	121	1455540005	The Lost City of the Monkey God: A True Story	Recounts how the author and a team of scientists discovered a legendary sacred city, the Lost City of the Monkey God, hidden deep in the Honduran jungle.
150	122	1861978235	Born to Run	Born to Run: A Hidden Tribe, Superathletes, and the Greatest Race the World Has Never Seen, is a 2009 best-selling non-fiction written by the American author and journalist Christopher McDougall.
151	123	1785414747	When Breath Becomes Air	At the age of thirty-six, on the verge of completing a decade's training as a neurosurgeon, Paul Kalanithi was diagnosed with inoperable lung cancer. One day he was a doctor treating the dying, the next he was a patient struggling to live.\nWhen Breath Becomes Air chronicles Kalanithi's transformation from a medical student in search of what makes a virtuous  and meaningful life into a neurosurgeon working in the core of human identity- the brain- and finally into a patient and a new father.\nWhat makes life worth living in the face of death? What do you do when life is catastrophically interrupted? What does it mean to have a child as your own life fades away?\nPaul Kalanithi died while working on this profoundly moving book, yet his words live on as a guide to us all. When Breath Becomes Air ia life-affirming reflection on facing our mortality and on the relationship between doctor and patient, from a gifted writer who became both.\n(Extracted from the book cover)
185	152	0563226617	Cold Comfort Farm	When sensible, sophisticated Flora Poste is orphaned at nineteen, she decides her only choice is to descend upon relatives in deepest Sussex. At the aptly named Cold Comfort Farm, she meets the doomed Starkadders: cousin Judith, heaving with remorse for unspoken wickedness; Amos, preaching fire and damnation; their sons, lustful Seth and despairing Reuben; child of nature Elfine; and crazed old Aunt Ada Doom, who has kept to her bedroom for the last twenty years. But Flora loves nothing better than to organize other people. Armed with common sense and a strong will, she resolves to take each of the family in hand. A hilarious and merciless parody of rural melodramas, Cold Comfort Farm (1932) is one of the best-loved comic novels of all time.
152	124	0593238117	What My Bones Know	By age thirty, Stephanie Foo was successful on paper: She had her dream job as an award-winning radio producer at This American Life and a loving boyfriend. But behind her office door, she was having panic attacks and sobbing at her desk every morning. After years of questioning what was wrong with herself, she was diagnosed with complex PTSD—a condition that occurs when trauma happens continuously, over the course of years.\n\nBoth of Foo’s parents abandoned her when she was a teenager, after years of physical and verbal abuse and neglect. She thought she’d moved on, but her new diagnosis illuminated the way her past continued to threaten her health, relationships, and career. She found limited resources to help her, so Foo set out to heal herself, and to map her experiences onto the scarce literature about C-PTSD.\n\nIn this deeply personal and thoroughly researched account, Foo interviews scientists and psychologists and tries a variety of innovative therapies. She returns to her hometown of San Jose, California, to investigate the effects of immigrant trauma on the community, and she uncovers family secrets in the country of her birth, Malaysia, to learn how trauma can be inherited through generations. Ultimately, she discovers that you don’t move on from trauma—but you can learn to move with it.\n\nPowerful, enlightening, and hopeful, What My Bones Know is a brave narrative that reckons with the hold of the past over the present, the mind over the body—and examines one woman’s ability to reclaim agency from her trauma.
153	125	0812994523	Just Mercy	Just Mercy: A Story of Justice and Redemption is a memoir by Bryan Stevenson that documents his career as a lawyer for disadvantaged clients. The book, focusing on injustices in the United States judicial system, alternates chapters between documenting Stevenson's efforts to overturn the wrongful conviction of Walter McMillian and his work on other cases, including children who receive life sentences and other poor or marginalized clients.\n\nInitially published by Spiegel & Grau, then an imprint of Penguin Random House, on 21 October 2014 in hardcover and digital formats and by Random House Audio in audiobook format read by Stevenson, a paperback edition was released on 16 August 2015 by Penguin Random House and a young adult adaptation was published by Delacorte Press on 18 September 2018. The memoir was later adapted into a 2019 movie of the same name by Destin Daniel Cretton and, commemorating the film, "Movie Tie-In" editions were released for both versions of the memoir on 3 December 2019 by imprints of Penguin Random House.\n\nThe memoir has received many honors and won multiple non-fiction book awards. It was a New York Times best seller and spent more than 230 weeks on the paperback nonfiction best sellers list. It won the 2015 Andrew Carnegie Medal for Excellence in Nonfiction, given annually by the American Library Association. Stevenson's acceptance speech for the award, given at the Library Association's annual meeting, was said to be the best that many of the librarians had ever heard, and was published with acclaim by Publishers Weekly. The book was also awarded the 2015 Dayton Literary Peace Prize for Nonfiction and the 2015 NAACP Image Award for Outstanding Literary Work in Nonfiction. It was named one of "10 of the decade's most influential books" in December 2019 by CNN.
154	126	9781509877027	The Immortal Life of Henrietta Lacks	Her name was Henrietta Lacks, but scientists know her as HeLa. She was a poor black tobacco farmer whose cells—taken without her knowledge in 1951—became one of the most important tools in medicine, vital for developing the polio vaccine, cloning, gene mapping, in vitro fertilization, and more. Henrietta’s cells have been bought and sold by the billions, yet she remains virtually unknown, and her family can’t afford health insurance.\n\nThis New York Times bestseller takes readers on an extraordinary journey, from the “colored” ward of Johns Hopkins Hospital in the 1950s to stark white laboratories with freezers filled with HeLa cells, from Henrietta’s small, dying hometown of Clover, Virginia, to East Baltimore today, where her children and grandchildren live and struggle with the legacy of her cells. The Immortal Life of Henrietta Lacks tells a riveting story of the collision between ethics, race, and medicine; of scientific discovery and faith healing; and of a daughter consumed with questions about the mother she never knew. It’s a story inextricably connected to the dark history of experimentation on African Americans, the birth of bioethics, and the legal battles over whether we control the stuff we’re made of.\n([source][1])\n\n\n  [1]: http://rebeccaskloot.com/the-immortal-life/
155	127	1841157910	Fermat's Last Theorem	x^n + y^n = z^n, where n represents 3, 4, 5, ...no solution "I have discovered a truly marvelous demonstration of this proposition which this margin is too narrow to contain." With these words, the seventeenth-century French mathematician Pierre de Fermat threw down the gauntlet to future generations.  What came to be known as Fermat's Last Theorem looked simple; proving it, however, became the Holy Grail of mathematics, baffling its finest minds for more than 350 years.  \r\n\r\nIn Fermat's Enigma--based on the author's award-winning documentary film, which aired on PBS's "Nova"--Simon Singh tells the astonishingly entertaining story of the pursuit of that grail, and the lives that were devoted to, sacrificed for, and saved by it.  Here is a mesmerizing tale of heartbreak and mastery that will forever change your feelings about mathematics.
156	128	9781250073952	Let There Be Water	As every day brings urgent reports of growing water shortages around the world, there is no time to lose in the search for solutions.\n\nThe U.S. government predicts that forty of our fifty states-and 60 percent of the earth's land surface-will soon face alarming gaps between available water and the growing demand for it. Without action, food prices will rise, economic growth will slow, and political instability is likely to follow.\n\nLet There Be Water illustrates how Israel can serve as a model for the United States and countries everywhere by showing how to blunt the worst of the coming water calamities. Even with 60 percent of its country made of desert, Israel has not only solved its water problem; it also had an abundance of water. Israel even supplies water to its neighbors-the Palestinians and the Kingdom of Jordan-every day.\n\nBased on meticulous research and hundreds of interviews, Let There Be Water reveals the methods and techniques of the often offbeat inventors who enabled Israel to lead the world in cutting-edge water technology.\n\nLet There Be Water also tells unknown stories of how cooperation on water systems can forge diplomatic ties and promote unity. Remarkably, not long ago, now-hostile Iran relied on Israel to manage its water systems, and access to Israel's water know-how helped to warm China's frosty relations with Israel.\n\nBeautifully written, Let There Be Water is and inspiring account of the vision and sacrifice by a nation and people that have long made water security a top priority. Despite scant natural water resources, a rapidly growing population and economy, and often hostile neighbors, Israel has consistently jumped ahead of the water innovation-curve to assure a dynamic, vital future for itself. Every town, every country, and every reader can benefit from learning what Israel did to overcome daunting challenges and transform itself from a parched land into a water superpower.
157	129	0006751156	The Outsiders	According to Ponyboy, there are two kinds of people in the world: greasers and socs. A soc (short for "social") has money, can get away with just about anything, and has an attitude longer than a limousine. A greaser, on the other hand, always lives on the outside and needs to watch his back. Ponyboy is a greaser, and he's always been proud of it, even willing to rumble against a gang of socs for the sake of his fellow greasers--until one terrible night when his friend Johnny kills a soc. The murder gets under Ponyboy's skin, causing his world to crumble and teaching him that pain feels the same whether a soc or a greaser.\n([source][1])\n\n\n  [1]: http://www.sehinton.com/books/
158	130	0307276562	The Man Who Ate His Boots	The enthralling and often harrowing history of the adventurers who searched for the Northwest Passage, the holy grail of nineteenth-century British exploration.After the triumphant end of the Napoleonic Wars in 1815, the British took it upon themselves to complete something they had been trying to do since the sixteenth century: find the fabled Northwest Passage, a shortcut to the Orient via a sea route over northern Canada. For the next thirty-five years the British Admiralty sent out expedition after expedition to probe the ice-bound waters of the Canadian Arctic in search of a route, and then, after 1845, to find Sir John Franklin, the Royal Navy hero who led the last of these Admiralty expeditions and vanished into the maze of channels, sounds, and icy seas with two ships and 128 officers and men. In The Man Who Ate His Boots, Anthony Brandt tells the whole story of the search for the Northwest Passage, from its beginnings early in the age of exploration through its development into a British national obsession to the final sordid, terrible descent into scurvy, starvation, and cannibalism. Sir John Franklin is the focus of the book but it covers all the major expeditions and a number of fascinating characters, including Franklin's extraordinary wife, Lady Jane, in vivid detail. The Man Who Ate His Boots is a rich and engaging work of narrative history that captures the glory and the folly of this ultimately tragic enterprise.From the Hardcover edition.
159	131	0385509456	The Curious Incident of the Dog in the Night-Time	This is Christopher's murder mystery story. There are no lies in this story because Christopher can't tell lies. Christopher does not like strangers or the colours yellow or brown or being touched. On the other hand, he knows all the countries in the world and their capital cities and every prime number up to 7507. When Christohper decides to find out who killed the neighbour's dog, his mystery story becomes more complicated than he could ever have predicted.
161	133	0062821954	Truly Devious	Ellingham Academy is a famous private school in Vermont for the brightest thinkers, inventors, and artists. It was founded by Albert Ellingham, an early twentieth century tycoon, who wanted to make a wonderful place full of riddles, twisting pathways, and gardens. Shortly after the school opened, his wife and daughter were kidnapped. The only real clue was a mocking riddle listing methods of murder, signed with the frightening pseudonym 'Truly, Devious.'
163	135	0374237131	Presumed Innocent	The novel that launched Turow's career as one of America's pre-eminent thriller writers tells the story of Rusty Sabicch, chief deputy prosecutor in a large Midwestern city. With three weeks to go in his boss' re-election campaign, a member of Rusty's staff is found murdered; he is charged with finding the killer, until his boss loses and, incredibly, Rusty finds himself accused of the murder.
164	136	039912442X	Red Dragon	Red Dragon is a novel by American author Thomas Harris, first published in 1981. The plot follows former FBI profiler Will Graham, who comes out of retirement to find and apprehend an enigmatic serial-killer nicknamed "The Tooth Fairy". The novel introduced the character Dr. Hannibal Lecter, a brilliant psychiatrist and cannibalistic serial-killer, whom Graham reluctantly turns to for advice and with whom he has a dark past. The title refers to the figure from William Blake's painting The Great Red Dragon and the Woman Clothed in Sun.
162	134	1441734287	We Have Always Lived in the Castle	Taking readers deep into a labyrinth of dark neurosis, We Have Always Lived in the Castle is a deliciously unsettling novel about a perverse, isolated, and possibly murderous family and the struggle that ensues when a cousin arrives at their estate.
166	138	030758836X	Gone Girl	Gone Girl is a 2012 crime thriller novel by American writer Gillian Flynn. It was published by Crown Publishing Group in June 2012. The novel became popular and made the New York Times Best Seller list. The sense of suspense in the novel comes from whether or not Nick Dunne is involved in the disappearance of his wife Amy.
167	139	0670069019	The Girl with the Dragon Tattoo	Journalist Mikael Blomkvist and hacker Lisbeth Salander investigate the disappearance of Harriet Vanger which took place forty years ago.
168	140	0385416342	The Firm	The Firm is a 1991 legal thriller by American writer John Grisham. It was his second book and the first which gained wide popularity.
170	71	0582430291	The Woman in White	The Woman in White famously opens with Walter Hartright's eerie encounter on a moonlit London road. Engaged as a drawing master to the beautiful Laura Fairlie, Walter is drawn into the sinister intrigues of Sir Percival Glyde and his 'charming' friend Count Fosco, who has a taste for white mice, vanilla bonbons and poison. Pursuing questions of identity and insanity along the paths and corridors of English country houses and the madhouse, The Woman in White is the first and most influential of the Victorian genre that combined Gothic horror with psychological realism.
171	142	0786293101	The Black Dahlia	The Black Dahlia is a roman noir on an epic scale: a classic period piece that provides a startling conclusion to America's most infamous unsolved murder mystery--the murder of the beautiful young woman known as The Black Dahlia.
172	49	0563496819	A Study in Scarlet	A Study in Scarlet is an 1887 detective novel by British writer Arthur Conan Doyle. The story marks the first appearance of Sherlock Holmes and Dr. Watson, who would become the most famous detective duo in literature.
169	141	9781521958711	The Big Sleep	Philip Marlowe, a private eye who operates in Los Angeles's seamy underside during the 1930s, takes on his first case, which involves a paralyzed California millionaire, two psychotic daughters, blackmail, and murder.
174	144	8820074052	The Love Hypothesis	When a fake relationship between scientists meets the irresistible force of attraction, it throws one woman's carefully calculated theories on love into chaos.\n\nAs a third-year PhD candidate, Olive Smith doesn't believe in lasting romantic relationships—but her best friend does, and that's what got her into this situation. Convincing Anh that Olive is dating and well on her way to a happily ever after was always going to take more than hand-wavy Jedi mind tricks: Scientists require proof. So, like any self-respecting biologist, Olive panics and kisses the first man she sees.\n\nThat man is none other than Adam Carlsen, a young hotshot professor—and well-known ass. Which is why Olive is positively floored when Stanford's reigning lab tyrant agrees to keep her charade a secret and be her fake boyfriend. But when a big science conference goes haywire, putting Olive's career on the Bunsen burner, Adam surprises her again with his unyielding support and even more unyielding...six-pack abs.\n\nSuddenly their little experiment feels dangerously close to combustion. And Olive discovers that the only thing more complicated than a hypothesis on love is putting her own heart under the microscope.
175	87	9780753189610	The Song of Achilles	This is the story of the seige of Troy from the perspective of Achilles best-friend Patroclus.  Although Patroclus is outcast from his home for disappointing his father he manages to be the only mortal who can keep up with the half-God Archilles.  Even though many will know the facts behind the story the telling is fresh and engaging.
176	145	6051739939	It Ends With Us	Lily hasn’t always had it easy, but that’s never stopped her from working hard for the life she wants. She’s come a long way from the small town where she grew up—she graduated from college, moved to Boston, and started her own business. And when she feels a spark with a gorgeous neurosurgeon named Ryle Kincaid, everything in Lily’s life seems too good to be true.\n\nRyle is assertive, stubborn, maybe even a little arrogant. He’s also sensitive, brilliant, and has a total soft spot for Lily. And the way he looks in scrubs certainly doesn’t hurt. Lily can’t get him out of her head. But Ryle’s complete aversion to relationships is disturbing. Even as Lily finds herself becoming the exception to his “no dating” rule, she can’t help but wonder what made him that way in the first place.\n\nAs questions about her new relationship overwhelm her, so do thoughts of Atlas Corrigan—her first love and a link to the past she left behind. He was her kindred spirit, her protector. When Atlas suddenly reappears, everything Lily has built with Ryle is threatened.\n\nWith this bold and deeply personal novel, It Ends With Us is a heart-wrenching story and an unforgettable tale of love that comes at the ultimate price.
186	153	9780141943893	Skippy Dies	Ruprecht Van Doren is an overweight genius whose hobbies include very difficult maths and the Search for Extra-Terrestrial Intelligence. Daniel 'Skippy' Juster is his roommate. In the grand old Dublin institution that is Seabrook College for Boys, nobody pays either of them much attention. But when Skippy falls for Lori, the Frisbee-playing Siren from the girls' school next door, suddenly all kinds of people take an interest - including Carl, part-time drug-dealer and official school psychopath.While his teachers battle over modernisation, and Ruprecht attempts to open a portal into a parallel universe, Skippy, in the name of love, is heading for a showdown - in the form of a fatal doughnut-eating race that only one person will survive. This unlikely tragedy will explode Seabrook's century-old complacency and bring all kinds of secrets into the light, until teachers and pupils alike discover that the fragile lines dividing past from present, love from betrayal - and even life from death - have become almost impossible to read . . .
178	147	0525574689	One Day in December	Two people. Ten chances. One unforgettable love story. Laurie is pretty sure love at first sight doesn't exist anywhere but the movies. But then, through a misted-up bus window one snowy December day, she sees a man who she knows instantly is the one. Their eyes meet, there's a moment of pure magic...and then her bus drives away. Certain they're fated to find each other again, Laurie spends a year scanning every bus stop and cafe in London for him. But she doesn't find him, not when it matters anyway. Instead they "reunite" at a Christmas party, when her best friend Sarah giddily introduces her new boyfriend to Laurie. It's Jack, the man from the bus. It would be. What follows for Laurie, Sarah and Jack is ten years of friendship, heartbreak, missed opportunities, roads not taken, and destinies reconsidered. One Day in December is a joyous, heartwarming and immensely moving love story to escape into and a reminder that fate takes inexplicable turns along the route to happiness.
179	148	9780374260507	The Sellout	A biting satire about a young man's isolated upbringing and the race trial that sends him to the Supreme Court, Paul Beatty's *The Sellout* showcases a comic genius at the top of his game. It challenges the sacred tenets of the United States Constitution, urban life, the civil rights movement, the father-son relationship, and the holy grail of racial equality―the black Chinese restaurant.\n\nBorn in the "agrarian ghetto" of Dickens―on the southern outskirts of Los Angeles―the narrator of *The Sellout* resigns himself to the fate of lower-middle-class Californians: "I'd die in the same bedroom I'd grown up in, looking up at the cracks in the stucco ceiling that've been there since '68 quake." Raised by a single father, a controversial sociologist, he spent his childhood as the subject in racially charged psychological studies. He is led to believe that his father's pioneering work will result in a memoir that will solve his family's financial woes. But when his father is killed in a police shoot-out, he realizes there never was a memoir. All that's left is the bill for a drive-thru funeral.\n\nFuelled by this deceit and the general disrepair of his hometown, the narrator sets out to right another wrong: Dickens has literally been removed from the map to save California from further embarrassment. Enlisting the help of the town's most famous resident―the last surviving Little Rascal, Hominy Jenkins―he initiates the most outrageous action conceivable: reinstating slavery and segregating the local high school, which lands him in the Supreme Court.
180	149	9780812995343	Lincoln in the Bardo	February 1862. The Civil War is less than one year old. The fighting has begun in earnest, and the nation has begun to realize it is in for a long, bloody struggle. Meanwhile, President Lincoln's beloved eleven-year-old son, Willie, lies upstairs in the White House, gravely ill. In a matter of days, despite predictions of a recovery, Willie dies and is laid to rest in a Georgetown cemetery. "My poor boy, he was too good for this earth," the president says at the time. "God has called him home." Newspapers report that a grief-stricken Lincoln returns, alone, to the crypt several times to hold his boy's body. From that seed of historical truth, George Saunders spins a story of familial love and loss that breaks free of its historical framework into a supernatural realm both hilarious and terrifying. Willie Lincoln finds himself in a strange purgatory where ghosts mingle, gripe, commiserate, quarrel, and enact bizarre acts of penance. Within this transitional state -- called, in the Tibetan tradition, the bardo -- a monumental struggle erupts over young Willie's soul.
181	149	1410460398	Tenth of December	One of the most important and blazingly original writers of his generation, George Saunders is an undisputed master of the short story, and Tenth of December is his most honest, accessible, and moving collection yet.\n\nIn the taut opener, “Victory Lap,” a boy witnesses the attempted abduction of the girl next door and is faced with a harrowing choice: Does he ignore what he sees, or override years of smothering advice from his parents and act? In “Home,” a combat-damaged soldier moves back in with his mother and struggles to reconcile the world he left with the one to which he has returned. And in the title story, a stunning meditation on imagination, memory, and loss, a middle-aged cancer patient walks into the woods to commit suicide, only to encounter a troubled young boy who, over the course of a fateful morning, gives the dying man a final chance to recall who he really is. \n\nA hapless, deluded owner of an antiques store; two mothers struggling to do the right thing; a teenage girl whose idealism is challenged by a brutal brush with reality; a man tormented by a series of pharmaceutical experiments that force him to lust, to love, to kill—the unforgettable characters that populate the pages of Tenth of December are vividly and lovingly infused with Saunders’s signature blend of exuberant prose, deep humanity, and stylistic innovation.\n\n \n\nWriting brilliantly and profoundly about class, sex, love, loss, work, despair, and war, Saunders cuts to the core of the contemporary experience. These stories take on the big questions and explore the fault lines of our own morality, delving into the questions of what makes us good and what makes us human.\n\nUnsettling, insightful, and hilarious, the stories in Tenth of December—through their manic energy, their focus on what is redeemable in human beings, and their generosity of spirit—not only entertain and delight; they fulfill Chekhov’s dictum that art should “prepare us for tenderness.”\n([source][1])\n\n\n  [1]: http://www.georgesaundersbooks.com/tenth-of-december/
183	151	1860466869	Independent People	Bjartus is a sheep farmer hewing a living from a blighted patch of land in Iceland. After 18 years of servitude to a master he despises, all he wants is to raise his flocks unbeholden to anyone. Nothing, not inclement weather, not his wives, not his family will come between him and his goal of financial independence. Only Asta Solillja, the child he brings up as his daughter, can pierce his stubborn heart. But she too wants to live independently - and when Bjartus throws her from the house on discovering she is pregnant, her more temperate determination is set against his stony will.
184	62	9798613739455	Oliver Twist	Oliver Twist; or, The Parish Boy's Progress, is the second novel by English author Charles Dickens. It was originally published as a serial from 1837 to 1839, and as a three-volume book in 1838. The story follows the titular orphan, who, after being raised in a workhouse, escapes to London, where he meets a gang of juvenile pickpockets led by the elderly criminal Fagin, discovers the secrets of his parentage, and reconnects with his remaining family.\n\nOliver Twist unromantically portrays the sordid lives of criminals, and exposes the cruel treatment of the many orphans in London in the mid-19th century.[2] The alternative title, The Parish Boy's Progress, alludes to Bunyan's The Pilgrim's Progress, as well as the 18th-century caricature series by painter William Hogarth, A Rake's Progress and A Harlot's Progress.\n\nIn an early example of the social novel, Dickens satirises child labour, domestic violence, the recruitment of children as criminals, and the presence of street children. The novel may have been inspired by the story of Robert Blincoe, an orphan whose account of working as a child labourer in a cotton mill was widely read in the 1830s. It is likely that Dickens's own experiences as a youth contributed as well, considering he spent two years of his life in the workhouse at the age of 12 and subsequently, missed out on some of his education.
191	157	1841932515	Paradise Lost	John Milton's Paradise Lost is one of the greatest epic poems in the English language. It tells the story of the Fall of Man, a tale of immense drama and excitement, of rebellion and treachery, of innocence pitted against corruption, in which God and Satan fight a bitter battle for control of mankind's destiny. The struggle rages across three worlds - heaven, hell, and earth - as Satan and his band of rebel angels plot their revenge against God. At the center of the conflict are Adam and Eve, who are motivated by all too human temptations but whose ultimate downfall is unyielding love.\n\nMarked by Milton's characteristic erudition, Paradise Lost is a work epic both in scale and, notoriously, in ambition. For nearly 350 years, it has held generation upon generation of audiences in rapt attention, and its profound influence can be seen in almost every corner of Western culture.
193	159	3518010107	Old Possum's Book of Practical Cats	T. S. Eliot’s playful cat poems have delighted readers and cat lovers around the world ever since they were first published in 1939. They were originally composed for his godchildren, with Eliot posing as Old Possum himself, and later inspired the legendary musical Cats. Now with vibrant illustrations by the award-winning Axel Scheffler, this captivating edition makes a wonderful new home for Mr. Mistoffelees, Growltiger, the Rum Tum Tugger, Macavity the mystery cat, and many other memorable strays. It’s the perfect complement to the beloved previous edition, which remains available. - Publisher.
192	158	0060572345	Where the Sidewalk Ends	If you are a dreamer, come in, If you are a dreamer, A wisher, a liar, A hope-er, a pray-er, A magic bean buyer... Come in ... for where the sidewalk ends, Shel Silverstein's world begins. You'll meet a boy who turns into a TV set, and a girl who eats a whale. The Unicorn and the Bloath live there, and so does Sarah Cynthia Sylvia Stout who will not take the garbage out. It is a place where you wash your shadow and plant diamond gardens, a place where shoes fly, sisters are auctioned off, and crocodiles go to the dentist. Shel Silverstein's masterful collection of poems and drawings is at once outrageously funny and profound. This special edition has 12 extra poems the did not appear in the original collection. - Jacket flap.
194	160	9780811217477	A Coney Island of the Mind, Poems	The title of this book is taken from Henry Miller's into the Night Life and expresses the way Lawrence Ferlinghetti felt about these poems when he wrote them during a short period in the 1950's-as if they were taken together, a kind of Coney Island of the mind, a kind of circus of the soul. \r\nThe twenty-nice poems of the title section form an integrated sequence in which the poet's eye sees beneath the "surface of the round world," while the section entitled "Oral Messages" was particularly written to be read aloud and communicated in the voice of our times. A measure of the poet's success in this is evident in that the paperback edition of a Coney Island of the Mind is now in its nineteenth printing with a total of 300,000 copies in print.
189	156	0553148923	Still Life with Woodpecker	Still Life with Woodpecker is a sort of a love story that takes place inside a pack of Camel cigarettes. It reveals the purpose of the moon, explains the difference between criminals and outlaws, examines the conflict between social activism and romantic individualism, and paints a portrait of contemporary society that includes powerful Arabs, exiled royalty, and pregnant cheerleaders. It also deals with the problem of redheads. From the Trade Paperback edition.
200	166	9780375435010	Unbroken	On a May afternoon in 1943, an Army Air Forces bomber crashed into the Pacific Ocean and disappeared, leaving only a spray of debris and a slick of oil, gasoline, and blood.  Then, on the ocean surface, a face appeared.  It was that of a young lieutenant, the plane’s bombardier, who was struggling to a life raft and pulling himself aboard.  So began one of the most extraordinary odysseys of the Second World War.\n\nThe lieutenant’s name was Louis Zamperini.  In boyhood, he’d been a cunning and incorrigible delinquent, breaking into houses, brawling, and fleeing his home to ride the rails.  As a teenager, he had channeled his defiance into running, discovering a prodigious talent that had carried him to the Berlin Olympics and within sight of the four-minute mile.  But when war had come, the athlete had become an airman, embarking on a journey that led to his doomed flight, a tiny raft, and a drift into the unknown.\n\nAhead of Zamperini lay thousands of miles of open ocean, leaping sharks, a foundering raft, thirst and starvation, enemy aircraft, and, beyond, a trial even greater.  Driven to the limits of endurance, Zamperini would answer desperation with ingenuity; suffering with hope, resolve, and humor; brutality with rebellion.  His fate, whether triumph or tragedy, would be suspended on the fraying wire of his will.
201	167	0399588175	Born a Crime	Born a Crime is the story of a mischievous young boy who grows into a restless young man as he struggles to find himself in a world where he was never supposed to exist. It is also the story of that young man’s relationship with his fearless, rebellious, and fervently religious mother—his teammate, a woman determined to save her son from the cycle of poverty, violence, and abuse that would ultimately threaten her own life.\n\nThe stories collected here are by turns hilarious, dramatic, and deeply affecting. Whether subsisting on caterpillars for dinner during hard times, being thrown from a moving car during an attempted kidnapping, or just trying to survive the life-and-death pitfalls of dating in high school, Trevor illuminates his curious world with an incisive wit and unflinching honesty. His stories weave together to form a moving and searingly funny portrait of a boy making his way through a damaged world in a dangerous time, armed only with a keen sense of humor and a mother’s unconventional, unconditional love.
202	168	0684813637	John Adams	In this powerful, epic biography, David McCullough unfolds the adventurous life-journey of John Adams, the brilliant, fiercely independent, often irascible, always honest Yankee patriot who spared nothing in his zeal for the American Revolution; who rose to become the second President of the United States and saved the country from blundering into an unnecessary war; who was learned beyond all but a few and regarded by some as "out of his senses"; and whose marriage to the wise and valiant Abigail Adams is one of the moving love stories in American history. This is history on a grand scale -- a book about politics and war and social issues, but also about human nature, love, religious faith, virtue, ambition, friendship, and betrayal, and the far-reaching consequences of noble ideas. Above all, John Adams is an enthralling, often surprising story of one of the most important and fascinating Americans who ever lived.
203	169	0375756787	The Rise of Theodore Roosevelt	Biography of Theodore Roosevelt, 26th President of the United States, detailing his life from birth (1858) to his ascendancy to the Presidency (1901). This is the first book in Edmund Morris's trilogy on Roosevelt (followed by *Theodore Rex* and *Colonel Roosevelt*). It won the 1980 Pulitzer Prize for Bibliography or Autobiography and the 1980 National Book Award in Biography.
204	170	5170812140	Surely You're Joking, Mr. Feynman!	The biography of the physicist and Nobel prize winner Richard P. Feynman - a collection of short stories, chapters told to and written down by Ralph Leighton.\r\nFeynman tells of his childhood and youth and goes into his adult life, both personally and professionally.
205	171	076791936X	The Life and Times of the Thunderbolt Kid	Bill Bryson on his most personal journey yet: into his own childhood in America's Mid-West. Some say that the first hint that Bill Bryson was not of Planet Earth came when his mother sent him to school in lime-green Capri pants. Others think it all started with his discovery, at the age of six, of a woollen jersey of rare fineness. Across the moth-holed chest was a golden thunderbolt. It may have looked like an old college football sweater, but young Bryson knew better. It was obviously the Sacred Jersey of Zap, and proved that he had been placed with this innocuous family in the middle of America to fly, become invisible, shoot guns out of people's hands from a distance, and wear his underpants over his jeans in the manner of Superman.Bill Bryson's first travel book opened with the immortal line, 'I come from Des Moines. Somebody had to.' In his deeply funny new memoir, he travels back in time to explore the ordinary kid he once was, and the curious world of 1950s America. It was a happy time, when almost everything was good for you, including DDT, cigarettes and nuclear fallout. This is a book about growing up in a specific time and place. But in Bryson's hands, it becomes everyone's story, one that will speak volumes – especially to anyone who has ever been young.
206	172	1432837753	The Sound of Gravel	The true story of one girl's coming-of-age in a polygamist family. Ruth Wariner was the thirty-ninth of her father's forty-two children. Growing up on a farm in rural Mexico, where authorities turn a blind eye to the practices of her community, Ruth lives in a ramshackle house without indoor plumbing or electricity. At church, preachers teach that God will punish the wicked by destroying the world and that women can only ascend to Heaven by entering into polygamous marriages and giving birth to as many children as possible. After Ruth's father--the founding prophet of the colony--is brutally murdered by his brother in a bid for church power, her mother remarries, becoming the second wife of another faithful congregant. In need of government assistance and supplemental income, Ruth and her siblings are carted back and forth between Mexico and the United States, where Ruth's mother collects welfare and her stepfather works a variety of odd jobs. Ruth comes to love the time she spends in the States, realizing that perhaps the community into which she was born is not the right one for her. As she begins to doubt her family's beliefs and question her mother's choices, she struggles to balance her fierce love for her siblings with her determination to forge a better life for herself. Recounted from the innocent and hopeful perspective of a child, this is the memoir of one girl's fight for peace and love.
207	173	0151012709	Merle's door	While on a camping trip, Ted Kerasote met a dog--a Labrador mix--who was living on his own in the wild. They became attached to each other, and Kerasote decided to name the dog Merle and bring him home. There, he realized that Merle's native intelligence would be diminished by living exclusively in the human world. He put a dog door in his house so Merle could live both outside and in. This portrait of a remarkable dog and his relationship with the author explores the issues that animals and their human companions face as their lives intertwine, bringing to bear the latest research into animal consciousness and behavior as well as insights into the origins and evolution of the human-dog partnership. Merle showed Kerasote how dogs might live if they were allowed to make more of their own decisions, and Kerasote suggests how these lessons can be applied universally.--From publisher description.
209	175	0684874350	Angela's Ashes	"When I look back on my childhood I wonder how I managed to survive at all. It was, of course, a miserable childhood: the happy childhood is hardly worth your while. Worse than the ordinary miserable childhood is the miserable Irish childhood, and worse yet is the miserable Irish Catholic childhood." So begins the luminous memoir of Frank McCourt, born in Depression-era Brooklyn to recent Irish immigrants and raised in the slums of Limerick, Ireland.  in the 1930s and 40s. Frank's mother, Angela, has no money to feed the children since Frank's father, Malachy, rarely works, and when he does he drinks his wages. Yet Malachy -- exasperating, irresponsible and beguiling -- does nurture in Frank an appetite for the one thing he can provide: a story. Frank lives for his father's tales of Cuchulain, who saved Ireland, and of the Angel on the Seventh Step, who brings his mother babies. Perhaps it is story that accounts for Frank's survival. Wearing rags for diapers, begging a pig's head for Christmas dinner and gathering coal from the roadside to light a fire, Frank endures poverty, near-starvation and the casual cruelty of relatives and neighbors -- yet lives to tell his tale with eloquence, exuberance and remarkable forgiveness. - Jacket flap.
210	176	0679772898	Thinking in Pictures	The idea that some people think differently, though no less humanly, is explored in this inspiring book. Temple Grandin is a gifted and successful animal scientist, and she is autistic. Here she tells us what it was like to grow up perceiving the world in an entirely concrete and visual way – somewhat akin to how animals think, she believes – and how it feels now. Through her finely observed understanding of the workings of her mind she gives us an invaluable insight into autism and its challenges.
208	174	9780241003404	A House in the Sky	The spectacularly dramatic memoir of a woman whose curiosity about the world led her from rural Canada to imperiled and dangerous countries on every continent, and then into fifteen months of harrowing captivity in Somalia--a story of courage, resilience, and extraordinary grace. At the age of eighteen, Amanda Lindhout moved from her hardscrabble Alberta hometown to the big city--Calgary--and worked as a cocktail waitress, saving her tips so she could travel the globe. As a child, she escaped a violent household by paging through National Geographic and imagining herself in its exotic locales. Now she would see those places for real. She backpacked through Latin America, Laos, Bangladesh, and India, and emboldened by each experience, went on to travel solo across Sudan, Syria, and Pakistan. In war-ridden Afghanistan and Iraq she carved out a fledgling career as a TV reporter. And then, in August 2008, she traveled to Mogadishu, Somalia--"the most dangerous place on earth"--To report on the fighting there. On her fourth day in the country, she and her photojournalist companion were abducted. An astoundingly intimate and harrowing account of Lindhout's fifteen months as a captive, A House in the Sky illuminates the psychology, motivations, and desperate extremism of her young guards and the men in charge of them. She is kept in chains, nearly starved, and subjected to unthinkable abuse. She survives by imagining herself in a "house in the sky," looking down at the woman shackled below, and finding strength and hope in the power of her own mind. Lindhout's decision, upon her release, to counter the violence she endured by founding an organization to help the Somali people rebuild their country through education is a wrenching testament to the capacity of the human spirit and an astonishing portrait of the power of compassion and forgiveness.
215	182	9780520267190	The Autobiography of Mark Twain	"I've struck it!" Mark Twain wrote in a 1904 letter to a friend. "And I will give it away—to you. You will never know how much enjoyment you have lost until you get to dictating your autobiography." Thus, after dozens of false starts and hundreds of pages, Twain embarked on his "Final (and Right) Plan" for telling the story of his life. His innovative notion—to "talk only about the thing which interests you for the moment"—meant that his thoughts could range freely. The strict instruction that many of these texts remain unpublished for 100 years meant that when they came out, he would be "dead, and unaware, and indifferent," and that he was therefore free to speak his "whole frank mind." \r\n\r\nThe year 2010 marks the 100th anniversary of Twain's death. In celebration of this important milestone and in honor of the cherished tradition of publishing Mark Twain's works, UC Press is proud to offer for the first time Mark Twain's uncensored autobiography in its entirety and exactly as he left it. This major literary event brings to readers, admirers, and scholars the first of three volumes and presents Mark Twain's authentic and unsuppressed voice, brimming with humor, ideas, and opinions, and speaking clearly from the grave as he intended. - [Publisher][1]\r\n\r\nExcerpts available: \r\n\r\n - http://www.ucpress.edu/content/chapters/11412.excerpt1.pdf\r\n - http://www.ucpress.edu/content/chapters/11412.excerpt2.pdf\r\n\r\n  [1]: http://www.ucpress.edu/book.php?isbn=9780520267190
217	184	0375405534	Speak, Memory	Speak, Memory is an autobiographical memoir by writer Vladimir Nabokov. The book includes individual essays published between 1936 and 1951 to create the first edition in 1951. Nabokov's revised and extended edition appeared in 1966.\r\n\r\n([Wikipedia](https://en.wikipedia.org/wiki/Speak,_Memory))
213	180	0891419195	With the Old Breed	In The Wall Street Journal, Victor Davis Hanson named With the Old Breed one of the top five books on epic twentieth-century battles. Studs Terkel interviewed the author for his definitive oral history, The Good War. Now E. B. Sledge's acclaimed first-person account of fighting at Peleliu and Okinawa returns to thrill, edify, and inspire a new generation.An Alabama boy steeped in American history and enamored of such heroes as George Washington and Daniel Boone, Eugene B. Sledge became part of the war's famous 1st Marine Division--3d Battalion, 5th Marines. Even after intense training, he was shocked to be thrown into the battle of Peleliu, where "the world was a nightmare of flashes, explosions, and snapping bullets." By the time Sledge hit the hell of Okinawa, he was a combat vet, still filled with fear but no longer with panic. Based on notes Sledge secretly kept in a copy of the New Testament, With the Old Breed captures with utter simplicity and searing honesty the experience of a soldier in the fierce Pacific Theater. Here is what saved, threatened, and changed his life. Here, too, is the story of how he learned to hate and kill--and came to love--his fellow man. From the Trade Paperback edition.
216	183	0099416271	The Agony and the Ecstasy	Stone gives his signature style and thought to this story of Michelangelo. He points out often in this book that Michelangelo, before beginning a work, asks what it is he is trying to capture in the moment of his painting, sculpture, or poem. So it is with Stone. He wants to portray, as close as he can find, the moments of the life of this artist. What shaped him, what he loved, what (and whom) he hated.
17	14	9780099468677	Catch-22	Catch-22 is like no other novel. It has its own rationale, its own extraordinary character. It moves back and forth from hilarity to horror. It is outrageously funny and strangely affecting. It is totally original. Set in the closing months of World War II in an American bomber squadron off Italy, Catch-22 is the story of a bombardier named Yossarian, who is frantic and furious because thousands of people he hasn't even met keep trying to kill him. Catch-22 is a microcosm of the twentieth-century world as it might look to someone dangerously sane. It is a novel that lives and moves and grows with astonishing power and vitality -- a masterpiece of our time. - Back cover.
220	187	0316403555	It's a Long Story	The iconic Country Music Hall of Fame artist and 10-time Grammy winner shares the story of his personal life and career, from his early ambitions and indelible relationships through his bankruptcy and founding of Farm Aid.
221	188	0156806797	The Seven Storey Mountain	The Seven Storey Mountain tells of the growing restlessness of a brilliant and passionate young man, who at the age of twenty-six, takes vows in one of the most demanding Catholic orders—the Trappist monks. At the Abbey of Gethsemani, "the four walls of my new freedom," Thomas Merton struggles to withdraw from the world, but only after he has fully immersed himself in it. At the abbey, he wrote this extraordinary testament, a unique spiritual autobiography that has been recognized as one of the most influential religious works of our time. Translated into more than twenty languages, it has touched millions of lives.
223	190	9781529066364	The Happiest Man on Earth	A New York Times Bestseller\n\nIn this uplifting memoir in the vein of The Last Lecture and Man’s Search for Meaning, a Holocaust survivor pays tribute to those who were lost by telling his story, sharing his wisdom, and living his best possible life.\n\nBorn in Leipzig, Germany, into a Jewish family, Eddie Jaku was a teenager when his world was turned upside-down. On November 9, 1938, during the terrifying violence of Kristallnacht, the Night of Broken Glass, Eddie was beaten by SS thugs, arrested, and sent to a concentration camp with thousands of other Jews across Germany. Every day of the next seven years of his life, Eddie faced unimaginable horrors in Buchenwald, Auschwitz, and finally on a forced death march during the Third Reich’s final days. The Nazis took everything from Eddie—his family, his friends, and his country. But they did not break his spirit.\n\nAgainst unbelievable odds, Eddie found the will to survive. Overwhelming grateful, he made a promise: he would smile every day in thanks for the precious gift he was given and to honor the six million Jews murdered by Hitler. Today, at 100 years of age, despite all he suffered, Eddie calls himself the “happiest man on earth.” In his remarkable memoir, this born storyteller shares his wisdom and reflects on how he has led his best possible life, talking warmly and openly about the power of gratitude, tolerance, and kindness. Life can be beautiful if you make it beautiful. With The Happiest Man on Earth, Eddie shows us how. \n\nFilled with his insights on friendship, family, health, ethics, love, and hatred, and the simple beliefs that have shaped him, The Happiest Man on Earth offers timeless lessons for readers of all ages, especially for young people today.
224	191	0804139024	The Martian	The Martian is a 2011 science fiction novel written by Andy Weir. It was his debut novel under his own name. It was originally self-published in 2011; Crown Publishing purchased the rights and re-released it in 2014. The story follows an American astronaut, Mark Watney, as he becomes stranded alone on Mars in 2035 and must improvise in order to survive.
225	192	0613361628	Snow Crash	Within the Metaverse, Hiro is offered a datafile named Snow Crash by a man named Raven who hints that it is a form of narcotic. Hiro's friend and fellow hacker Da5id views a bitmap image contained in the file which causes his computer to crash and Da5id to suffer brain damage in the real world.\n\nThis is the future we now live where all can be brought to life in the metaverse and now all can be taken away. Follow on an adventure with Hiro and YT as they work with the mob to uncover a plot of biblical proportions.
109	88	9780142403884	Charlie and the Chocolate Factory	Charlie and the Chocolate Factory is a 1964 children's novel by British author Roald Dahl. The story features the adventures of young Charlie Bucket inside the chocolate factory of eccentric chocolatier Willy Wonka.\r\n\r\nCharlie and the Chocolate Factory was first published in the United States by Alfred A. Knopf, Inc. in 1964 and in the United Kingdom by George Allen & Unwin 11 months later. \r\n\r\nIn the 2012 survey published by SLJ, a monthly with primarily US audience, Charlie was the second of four books by Dahl among their Top 100 Chapter Books, one more than any other writer. Time magazine in the US included the novel in its list of the 100 Best Young-Adult Books of All Time.
219	186	0006164226	Frost in May	Nanda Gray, the daughter of a Catholic convert, is nine when she is sent to the Convent of Five Wounds. Quick-witted, resilient, and eager to please, she adapts to this cloistered world, learning rigid conformity and subjection to authority. Passionate friendships are the only deviation from her total obedience. Convent life is perfectly captured by Antonia White.
218	185	1400043468	My Life in France	Julia Child singlehandedly created a new approach to American cuisine with her cookbook Mastering the Art of French Cooking and her television show The French Chef, but as she reveals in this bestselling memoir, she was not always a master chef. Indeed, when she first arrived in France in 1948 with her husband, Paul, who was to work for the USIS, she spoke no French and knew nothing about the country itself. But as she dove into French culture, buying food at local markets and taking classes at the Cordon Bleu, her life changed forever with her newfound passion for cooking and teaching. Julia's unforgettable story -- struggles with the head of the Cordon Bleu, rejections from publishers to whom she sent her now-famous cookbook, a wonderful, nearly fifty-year long marriage that took them across the globe -- unfolds with the spirit so key to her success as a chef and a writer, brilliantly capturing one of the most endearing American personalities of the last fifty years. From the Trade Paperback edition.
227	194	0804172447	Station Eleven	One snowy night Arthur Leander, a famous actor, has a heart attack onstage during a production of "King Lear." Jeevan Chaudhary, a paparazzo-turned-EMT, is in the audience and leaps to his aid. A child actress named Kirsten Raymonde watches in horror as Jeevan performs CPR, pumping Arthur's chest as the curtain drops, but Arthur is dead. That same night, as Jeevan walks home from the theater, a terrible flu begins to spread. Hospitals are flooded and Jeevan and his brother barricade themselves inside an apartment, watching out the window as cars clog the highways, gunshots ring out, and life disintegrates around them. Fifteen years later, Kirsten is an actress with the Traveling Symphony. Together, this small troupe moves between the settlements of an altered world, performing Shakespeare and music for scattered communities of survivors. Written on their caravan, and tattooed on Kirsten's arm is a line from Star Trek: "Because survival is insufficient." But when they arrive in St. Deborah by the Water, they encounter a violent prophet who digs graves for anyone who dares to leave.\n\nIn a future in which a pandemic has left few survivors, actress Kirsten Raymonde travels with a troupe performing Shakespeare and finds herself in a community run by a deranged prophet. The plot contains mild profanity and violence.
229	196	2221141571	Stranger in a Strange Land	Stranger in a Strange Land is a 1961 science fiction novel by American author Robert A. Heinlein. It tells the story of Valentine Michael Smith, a human who comes to Earth in early adulthood after being born on the planet Mars and raised by Martians. The novel explores his interaction with—and eventual transformation of—terrestrial culture. The title is an allusion to the phrase in Exodus 2:22. According to Heinlein, the novel's working title was The Heretic. Several later editions of the book have promoted it as "The most famous Science Fiction Novel ever written".
230	197	1857988140	The Stars My Destination	In this pulse-quickening novel, Alfred Bester imagines a future in which people "jaunte" a thousand miles with a single thought, where the rich barricade themselves in labyrinths and protect themselves with radioactive hitmen—and where an inarticulate outcast is the most valuable and dangerous man alive.\n\nThe Stars My Destination is a classic of technological prophecy and timeless narrative enchantment by an acknowledged master of science fiction.
231	198	0747236046	The Fall of Hyperion	On the world called Hyperion, beyond the law of the Hegemony of Man, there waits the creature called the Shrike.  There are those who worship it.  There are those who fear it.  And there are those who have vowed to destroy it.  In the Valley of the Time Tombs, where huge, brooding structures move backward through time, the Shrike waits for them all.  On the eve of Armageddon, with the entire galaxy at war, seven pilgrims set forth on a final voyage to Hyperion seeking the answers to the unsolved riddles of their lives.  Each carries a desperate hope--and a terrible secret.  And one may hold the fate of humanity in his hands.
232	199	0671434004	Contact	In December, 1999, a multinational team journeys out to the stars, to the most awesome encounter in human history. Who -- or what -- is out there? \nIn Cosmos, Carl Sagan explained the universe. In Contact, he predicts its future -- and our own.
233	200	1611136768	Consider Phlebas	Consider Phlebas is perhaps one of the lesser-known, but nevertheless the first, of the revelationary late Iain M. Banks' science fiction books. Consider Phlebas introduces us to the complex world of the mind-controlling, ubiquitous utopia of the Culture, which contrasts to their mortal sentient enemies. Iain Banks creates an imaginative and encapsulating premise to keep the reader hooked for more, with hints of science fiction and alien humour to liven a deadly race against an omnipotent foe.
234	196	9781101500422	Starship Troopers	Starship Troopers takes place in the midst of an interstellar war between the Terran Federation of Earth and the Arachnids (referred to as "The Bugs") of Klendathu. It is narrated as a series of flashbacks by Juan Rico, and is one of only a few Heinlein novels set out in this fashion.  The novel opens with Rico aboard the corvette  Rodger Young, about to embark on a raid against the planet of the "Skinnies," who are allies of the Arachnids. We learn that he is a cap(sule) trooper in the Terran Federation's Mobile Infantry. The raid itself, one of the few instances of actual combat in the novel, is relatively brief: the Mobile Infantry land on the planet, destroy their targets, and retreat, suffering a single casualty in the process.\n\nThe story then flashes back to Rico's graduation from high school, and his decision to sign up for Federal Service over the objections of his father. This is the only chapter that describes Rico's civilian life, and most of it is spent on the monologues of two people: retired Lt. Col. Jean V. Dubois, Rico's school instructor in "History and Moral Philosophy," and Fleet Sergeant Ho, a recruiter for the armed forces of the Terran Federation.\n\nDubois serves as a stand-in for Heinlein throughout the novel, and delivers what is probably the book's most famous soliloquy on violence, and how it "has settled more issues in history than has any other factor." Fleet Sergeant Ho's monologues examine the nature of military service, and his anti-military tirades appear in the book primarily as a contrast with Dubois. (It is later revealed that his rants are calculated to scare off the weaker applicants).\n\nInterspersed throughout the book are other flashbacks to Rico's high school History and Moral Philosophy course, which describe how in the Terran Federation of Rico's day, the rights of a full Citizen (to vote, and hold public office) must be earned through some form of volunteer Federal service. Those residents who have not exercised their right to perform this Federal Service retain the other rights generally associated with a modern democracy (free speech, assembly, etc.), but they cannot vote or hold public office. This structure arose ad hoc after the collapse of the 20th century Western democracies, brought on by both social failures at home and military defeat by the Chinese Hegemony overseas (assumed looking forward into the late 20th century from the time the novel was written in the late 1950s).\n\nIn the next section of the novel Rico goes to boot camp at Camp Arthur Currie, on the northern prairies. Five chapters are spent exploring Rico's experience entering the service under the training of his instructor, Career Ship's Sergeant Charles Zim. Camp Currie is so rigorous that less than ten percent of the recruits finish basic training; the rest either resign, are expelled, or die in training. One of the chapters deals with Ted Hendrick, a fellow recruit and constant complainer who is flogged and expelled for striking a superior officer. Another recruit, a deserter who committed a heinous crime while AWOL, is hanged by his battalion. Rico himself is flogged for poor handling of (simulated) nuclear weapons during a drill; despite these experiences he eventually graduates and is assigned to a unit.\n\nAt some point during Rico's training, the 'Bug War' has begun to brew, and Rico finds himself taking part in combat operations. The war "officially" starts with an Arachnid attack that annihilates the city of Buenos Aires, although Rico makes it clear that prior to the attack there were plenty of "'incidents,' 'patrols,' or 'police actions.'" Rico briefly describes the Terran Federation's loss at the Battle of Klendathu where his unit is decimated and his ship destroyed. Following Klendathu, the Terran Federation is reduced to making hit-and-run raids similar to the one described at the beginning of the novel (which, chronologically would be placed between Chapters 10 and 11). Rico meanwhile finds himself posted to Rasczak's Roughnecks, named after Lieutenant Rasczak (his first name is never given). This part of the book focuses on the daily routine of military life, as well as the relationship between officers and non-commissioned officers, personified in this case by Rasczak and Sergeant Jelal.\n\nEventually, Rico decides to become a career soldier and attends Officer Candidate School, which turns out to be just like boot camp, only "squared and cubed with books added."[15] Rico is commissioned a temporary Third Lieutenant as a field-test final exam and commands his own unit during Operation Royalty; eventually he graduates as a Second Lieutenant and full-fledged officer.\n\nThe final chapter serves as more of a coda, depicting Rico aboard the Rodger Young as the lieutenant in command of Rico's Roughnecks, preparing to drop to Klendathu as part of a major strike, with his father (having joined the Service earlier in the novel) as his senior sergeant and a Third Lieutenant-in-training of his own under his wing.
214	181	9780763680541	Symphony for the City of the Dead	National Book Award winner M. T. Anderson delivers a brilliant and riveting account of the Siege of Leningrad and the role played by Russian composer Shostakovich and his Leningrad Symphony. In September 1941, Adolf Hitler's Wehrmacht surrounded Leningrad in what was to become one of the longest and most destructive sieges in Western history almost three years of bombardment and starvation that culminated in the harsh winter of 1943-1944. More than a million citizens perished. Survivors recall corpses littering the frozen streets, their relatives having neither the means nor the strength to bury them. Residents burned books, furniture, and floorboards to keep warm; they ate family pets and eventually one another to stay alive. Trapped between the Nazi invading force and the Soviet government itself was composer Dmitri Shostakovich, who would write a symphony that roused, rallied, eulogized, and commemorated his fellow citizens the Leningrad Symphony, which came to occupy a surprising place of prominence in the eventual Allied victory.
91	74	2082111822	A Brief History of Time	Stephen Hawking's A Brief History of Time has become an international publishing phenomenon. Translated into thirty languages, it has sold over ten million copies worldwide and lives on as a science book that continues to captivate and inspire new readers each year. When it was first published in 1988 the ideas discussed in it were at the cutting edge of what was then known about the universe. In the intervening twenty years there have been extraordinary advances in the technology of observing both the micro- and macro-cosmic world. Indeed, during that time cosmology and the theoretical sciences have entered a new golden age. Professor Hawking is one of the major scientists and thinkers to have contributed to this renaissance.
33	29	0151191530	The Color Purple	The Color Purple is a 1982 epistolary novel by American author Alice Walker which won the 1983 Pulitzer Prize for Fiction and the National Book Award for Fiction.\r\n\r\nThe novel has been the frequent target of censors and appears on the American Library Association list of the 100 Most Frequently Challenged Books of 2000–2009 at number seventeenth because of the sometimes explicit content, particularly in terms of violence. In 2003, the book was listed on the BBC's The Big Read poll of the UK's "best-loved novels."
50	41	0749318473	A Clockwork Orange	A Clockwork Orange is a dystopian satirical black comedy novel by English writer Anthony Burgess, published in 1962. It is set in a near-future society that has a youth subculture of extreme violence. The teenage protagonist, Alex, narrates his violent exploits and his experiences with state authorities intent on reforming him. The book is partially written in a Russian-influenced argot called "Nadsat", which takes its name from the Russian suffix that is equivalent to '-teen' in English. According to Burgess, it was a jeu d'esprit written in just three weeks.\r\n\r\nIn 2005, A Clockwork Orange was included on Time magazine's list of the 100 best English-language novels written since 1923, and it was named by Modern Library and its readers as one of the 100 best English-language novels of the 20th century. The original manuscript of the book has been kept at McMaster University's William Ready Division of Archives and Research Collections in Hamilton, Ontario, Canada since the institution purchased the documents in 1971. It is considered one of the most influential dystopian books.
235	201	150110456X	All the Light We Cannot See	From the highly acclaimed, multiple award-winning Anthony Doerr, a stunningly ambitious and beautiful novel about a blind French girl and a German boy whose paths collide in occupied France as both try to survive the devastation of World War II. Marie Laure lives with her father in Paris within walking distance of the Museum of Natural History where he works as the master of the locks (there are thousands of locks in the museum). When she is six, she goes blind, and her father builds her a model of their neighborhood, every house, every manhole, so she can memorize it with her fingers and navigate the real streets with her feet and cane. When the Germans occupy Paris, father and daughter flee to Saint-Malo on the Brittany coast, where Marie-Laure's agoraphobic great uncle lives in a tall, narrow house by the sea wall. In another world in Germany, an orphan boy, Werner, grows up with his younger sister, Jutta, both enchanted by a crude radio Werner finds. He becomes a master at building and fixing radios, a talent that wins him a place at an elite and brutal military academy and, ultimately, makes him a highly specialized tracker of the Resistance. Werner travels through the heart of Hitler Youth to the far-flung outskirts of Russia, and finally into Saint-Malo, where his path converges with Marie-Laure. Doerr's gorgeous combination of soaring imagination with observation is electric. Deftly interweaving the lives of Marie-Laure and Werner, Doerr illuminates the ways, against all odds, people try to be good to one another. Ten years in the writing, All the Light We Cannot See is his most ambitious and dazzling work.
165	137	0671466062	And Then There Were None	And Then There Were None is a mystery novel by the English writer Agatha Christie, described by her as the most difficult of her books to write. It was first published in the United Kingdom by the Collins Crime Club on 6 November 1939, as Ten Little Niggers, after the children's counting rhyme and minstrel song, which serves as a major element of the plot. A US edition was released in January 1940 with the title And Then There Were None, which is taken from the last five words of the song. All successive American reprints and adaptations use that title, except for the Pocket Books paperbacks published between 1964 and 1986, which appeared under the title Ten Little Indians. UK editions continued to use the original title until the current definitive title appeared with a reprint of the 1963 Fontana Paperback in 1985.\r\n\r\nIn 1990 Crime Writers' Association ranked And Then There Were None 19th in their The Top 100 Crime Novels of All Time list. In 1995 in a similar list Mystery Writers of America ranked the novel 10th. In September 2015, to mark her 125th birthday, And Then There Were None was named the "World's Favourite Christie" in a vote sponsored by the author's estate. In the "Binge!" article of Entertainment Weekly Issue #1343-44 (26 December 2014–3 January 2015), the writers picked And Then There Were None as an "EW favorite" on the list of the "Nine Great Christie Novels".
43	8	1858782651	Animal Farm	Animal Farm is a brilliant political satire and a powerful and affecting story of revolutions and idealism, power and corruption. 'All animals are equal. But some animals are more equal than others.' Mr Jones of Manor Farm is so lazy and drunken that one day he forgets to feed his livestock. The ensuing rebellion under the leadership of the pigs Napoleon and Snowball leads to the animals taking over the farm. Vowing to eliminate the terrible inequities of the farmyard, the renamed Animal Farm is organised to benefit all who walk on four legs. But as time passes, the ideals of the rebellion are corrupted, then forgotten. And something new and unexpected emerges...
160	132	1250055504	Broadchurch	In the sleepy British seaside town of Broadchurch, Detective Ellie Miller has just returned from vacation, only to learn that she's been passed over for a promotion at work in favor of outsider Alec Hardy. He, escaping the spectacular failure of his last case, is having trouble finding his way into this tight-knit community wary of new faces. But professional rivalry aside, both detectives are about to receive some terrible news: 11-year-old Danny Latimer has been found murdered on the beach. For Ellie it's a personal blow; Danny was her older son's best friend. She can't believe anyone in Broadchurch would ever have harmed him. But Alec considers everyone, even Danny's parents, suspect in his death. It's a living nightmare for everyone involved...even before the press arrive and start stirring up the secrets every town member keeps hidden behind closed doors. An intimate portrait of a town and the ordinary grievances that have slowly simmered for years before boiling over in an unthinkable crime, this remarkable adaptation of the hit television show Broadchurch tells the story of a shattered family, a reeling town, and the two imperfect detectives trying to bring them answers.
55	46	9789875661196	Fahrenheit 451	Fahrenheit 451 is a 1953 dystopian novel by American writer Ray Bradbury. Often regarded as one of his best works, the novel presents a future American society where books are outlawed and "firemen" burn any that are found. The book's tagline explains the title as "'the temperature at which book paper catches fire, and burns": the autoignition temperature of paper. The lead character, Guy Montag, is a fireman who becomes disillusioned with his role of censoring literature and destroying knowledge, eventually quitting his job and committing himself to the preservation of literary and cultural writings.\r\n\r\nThe novel has been the subject of interpretations focusing on the historical role of book burning in suppressing dissenting ideas for change. In a 1956 radio interview, Bradbury said that he wrote Fahrenheit 451 because of his concerns at the time (during the McCarthy era) about the threat of book burning in the United States. In later years, he described the book as a commentary on how mass media reduces interest in reading literature.\r\n\r\nIn 1954, Fahrenheit 451 won the American Academy of Arts and Letters Award in Literature and the Commonwealth Club of California Gold Medal. It later won the Prometheus "Hall of Fame" Award in 1984 and a "Retro" Hugo Award, one of a limited number of Best Novel Retro Hugos ever given, in 2004. Bradbury was honored with a Spoken Word Grammy nomination for his 1976 audiobook version.
41	35	0771008139	The Handmaid's Tale	The Handmaid's Tale is a dystopian novel by Canadian author Margaret Atwood, published in 1985. It is set in a near-future New England, in a strongly patriarchal, totalitarian theonomic state, known as the Republic of Gilead, which has overthrown the United States government. The central character and narrator is a woman named Offred, one of the group known as "handmaids", who are forcibly assigned to produce children for the "commanders" — the ruling class of men in Gilead.\r\n\r\nThe novel explores themes of subjugated women in a patriarchal society, loss of female agency and individuality, and the various means by which they resist and attempt to gain individuality and independence.\r\n\r\nThe Handmaid's Tale won the 1985 Governor General's Award and the first Arthur C. Clarke Award in 1987; it was also nominated for the 1986 Nebula Award, the 1986 Booker Prize, and the 1987 Prometheus Award.
190	43	0497256614	The Importance of Being Earnest	Set in England during the late Victorian era, the play's humour derives in part from characters maintaining fictitious identities to escape unwelcome social obligations. It is replete with witty dialogue and satirises some of the foibles and hypocrisy of late Victorian society. It has proved Wilde's most enduringly popular play. [1]\r\n\r\n\r\n  [1]: http://en.wikipedia.org/wiki/The_Importance_of_Being_Earnest
143	116	0385492081	Into Thin Air	When Jon Krakauer reached the summit of Mt. Everest in the early afternoon of May 10,1996, he hadn't slept in fifty-seven hours and was reeling from the brain-altering effects of oxygen depletion. As he turned to begin the perilous descent from 29,028 feet (roughly the cruising altitude of an Airbus jetliner), twenty other climbers were still pushing doggedly to the top, unaware that the sky had begun to roil with clouds...Into Thin Air is the definitive account of the deadliest season in the history of Everest by the acclaimed Outside journalist and author of the bestselling Into the Wild. Taking the reader step by step from Katmandu to the mountain's deadly pinnacle, Krakauer has his readers shaking on the edge of their seat. Beyond the terrors of this account, however, he also peers deeply into the myth of the world's tallest mountain. What is is about Everest that has compelled so many poeple--including himself--to throw caution to the wind, ignore the concerns of loved ones, and willingly subject themselves to such risk, hardship, and expense? Written with emotional clarity and supported by his unimpeachable reporting, Krakauer's eyewitness account of what happened on the roof of the world is a singular achievement. (From the Paperback edition.)
182	150	0062328247	The Mandibles	It is 2029. The Mandibles have been counting on a sizable fortune filtering down when their 97-year-old patriarch dies. Yet America's soaring national debt has grown so enormous that it can never be repaid. Under siege from an upstart international currency, the dollar is in meltdown. A bloodless world war will wipe out the savings of millions of American families. Their inheritance turned to ash, each family member must contend with disappointment, but also -- as the effects of the downturn start to hit -- the challenge of sheer survival. Recently affluent Avery is petulant that she can't buy olive oil, while her sister Florence is forced to absorb strays into her increasingly cramped household. As their father Carter fumes at having to care for his demented stepmother now that a nursing home is too expensive, his sister Nollie, an expat author, returns from abroad at 73 to a country that's unrecognizable. Perhaps only Florence's oddball teenage son Willing, an economics autodidact, can save this formerly august American family from the streets. This is not science fiction. This is a frightening, fascinating, scabrously funny glimpse into the decline that may await the United States all too soon, from the pen of perhaps the most consistently perceptive and topical author of our times.
226	193	9780099303541	Jurassic Park	Jurassic Park is a 1990 science fiction novel written by Michael Crichton. A cautionary tale about genetic engineering, it presents the collapse of an amusement park showcasing genetically re-created dinosaurs to illustrate the mathematical concept of chaos theory and its real-world implications. A sequel titled The Lost World, also written by Crichton, was published in 1995. In 1997, both novels were re-published as a single book titled Michael Crichton's Jurassic World. In 1996 it was awarded the Secondary BILBY Award.
115	93	1407033328	The Book Thief	The extraordinary, beloved novel about the ability of books to feed the soul even in the darkest of times.\r\n\r\nWhen Death has a story to tell, you listen.\r\n\r\nIt is 1939. Nazi Germany. The country is holding its breath. Death has never been busier, and will become busier still.\r\n\r\nLiesel Meminger is a foster girl living outside of Munich, who scratches out a meager existence for herself by stealing when she encounters something she can’t resist–books. With the help of her accordion-playing foster father, she learns to read and shares her stolen books with her neighbors during bombing raids as well as with the Jewish man hidden in her basement. \r\n\r\nIn superbly crafted writing that burns with intensity, award-winning author Markus Zusak, author of I Am the Messenger, has given us one of the most enduring stories of our time.\r\n \r\n“The kind of book that can be life-changing.” —The New York Times
195	161	077102231X	Stranger Music	Some of the best work of one of the most enduring poet/songwriters of our time collected. When his fist album was released in 1967, Leonard Cohen was already well known in his native Canada as a poet and novelist, and in the United States as the writer behind Judy Collins' hugely popular recording of 'Suzanne. ' With the success of the first and through the release of ten more albums, Cohen Gained a reputation as a dazzlingly literate and consistently daring songwriter. Over the years his status as a cult artist has grown, and in 1988 the release of his album I'm Your Man' put Cohen back into the mainstream spotlight. His latest recording, 'The Future' has brought him renewed, widespread acclaim and this collection will include lyrics from that album, together with many of his famous classics, such as Suzanne, Joan of Arcand The Chelsea Hotel. STRANGER MUSIC brings together Cohen's song lyrics and a generous selection of his poetry (originally published between 1956-1992). It is a long overdue celebration of Leonard Cohen's extraordinary gift for language that speaks with rare clarity, passion and timelessness.
16	1	9780828818124	The Lord of the Rings	Originally published from 1954 through 1956, J.R.R. Tolkien's richly complex series ushered in a new age of epic adventure storytelling. A philologist and illustrator who took inspiration from his work, Tolkien invented the modern heroic quest novel from the ground up, creating not just a world, but a domain, not just a lexicon, but a language, that would spawn countless imitators and lead to the inception of the epic fantasy genre. Today, THE LORD OF THE RINGS is considered "the most influential fantasy novel ever written." (THE ENCYCLOPEDIA OF FANTASY)\r\n\r\nDuring his travels across Middle-earth, the hobbit Bilbo Baggins had found the Ring. But the simple band of gold was far from ordinary; it was in fact the One Ring - the greatest of the ancient Rings of Power. Sauron, the Dark Lord, had infused it with his own evil magic, and when it was lost, he was forced to flee into hiding.\r\n\r\nBut now Sauron's exile has ended and his power is spreading anew, fueled by the knowledge that his treasure has been found. He has gathered all the Great Rings to him, and will stop at nothing to reclaim the One that will complete his dominion. The only way to stop him is to cast the Ruling Ring deep into the Fire-Mountain at the heart of the land of Mordor--Sauron's dark realm.\r\n\r\nFate has placed the burden in the hands of Frodo Baggins, Bilbo's heir...and he is resolved to bear it to its end. Or his own.
68	56	0385121679	The Shining	The Shining is a 1977 horror novel by American author Stephen King. It is King's third published novel and first hardback bestseller; its success firmly established King as a preeminent author in the horror genre. The setting and characters are influenced by King's personal experiences, including both his visit to The Stanley Hotel in 1974 and his struggle with alcoholism. The book was followed by a sequel, Doctor Sleep, published in 2013.\n\nThe Shining centers on the life of Jack Torrance, a struggling writer and recovering alcoholic who accepts a position as the off-season caretaker of the historic Overlook Hotel in the Colorado Rockies. His family accompanies him on this job, including his young son Danny Torrance, who possesses "the shining", an array of psychic abilities that allow Danny to see the hotel's horrific past. Soon, after a winter storm leaves them snowbound, the supernatural forces inhabiting the hotel influence Jack's sanity, leaving his wife and son in incredible danger.\n\n\n
58	49	9798484660766	The Return of Sherlock Holmes	The Return of Sherlock Holmes is a 1905 collection of 13 Sherlock Holmes stories, originally published in 1903–1904, by Arthur Conan Doyle. The stories were published in the Strand Magazine in Britain and Collier's in the United States.
228	195	9754706255	Solaris	Telling of humanity's encounter with an alien intelligence on the planet Solaris, the 1961 novel is a cult classic, exploring the ultimate futility of attempting to communicate with extra-terrestrial life.\r\n\r\nWhen Kris Kelvin arrives at the planet Solaris to study the ocean that covers its surface, he finds a painful, hitherto unconscious memory embodied in the living physical likeness of a long-dead lover. Others examining the planet, Kelvin learns, are plagued with their own repressed and newly corporeal memories. The Solaris ocean may be a massive brain that creates these incarnate memories, though its purpose in doing so is unknown, forcing the scientists to shift the focus of their quest and wonder if they can truly understand the universe without first understanding what lies within their hearts.
103	83	0380002930	Watership Down	A phenomenal worldwide bestseller for more than forty years, Richard Adams's Watership Down is a timeless classic and one of the most beloved novels of all time. Set in England's Downs, a once idyllic rural landscape, this stirring tale of adventure, courage and survival follows a band of very special creatures on their flight from the intrusion of man and the certain destruction of their home. Led by a stouthearted pair of brothers, they journey forth from their native Sandleford Warren through the harrowing trials posed by predators and adversaries, to a mysterious promised land and a more perfect society.
124	99	9000378737	What If?	Millions of people visit xkcd.com each week to read Randall Munroe's iconic webcomic. His stick-figure drawings about science, technology, language, and love have a large and passionate following. Fans of xkcd ask Munroe a lot of strange questions. What if you tried to hit a baseball pitched at 90 percent the speed of light? How fast can you hit a speed bump while driving and live? If there was a robot apocalypse, how long would humanity last? In pursuit of answers, Munroe runs computer simulations, pores over stacks of declassified military research memos, solves differential equations, and consults with nuclear reactor operators. His responses are masterpieces of clarity and hilarity, complemented by signature xkcd comics. They often predict the complete annihilation of humankind, or at least a really big explosion. The book features new and never-before-answered questions, along with updated and expanded versions of the most popular answers from the xkcd website.
\.


--
-- Data for Name: genres; Type: TABLE DATA; Schema: lib; Owner: -
--

COPY lib.genres (genre_id, name) FROM stdin;
2	Fiction
3	Literature
4	Satire
5	Fantasy
6	Romance
9	Horror
10	Mystery
11	Thriller
12	Adventure
13	Dystopian
14	Autobiography
15	Biography
18	Nonfiction
20	Essay
21	Poetry
22	Humor
24	Philosophy
25	Classics
26	Drama
23	Fairy Tale
16	Graphic Novel
8	Historical Fiction
7	Science Fiction
19	Short Fiction
17	Young Adult
\.


--
-- Data for Name: spotlight_works; Type: TABLE DATA; Schema: lib; Owner: -
--

COPY lib.spotlight_works (serial, book_id, cover_id) FROM stdin;
212	234	14630746
213	235	14559680
210	232	4143957
211	233	11208887
\.


--
-- Name: authors_author_id_seq; Type: SEQUENCE SET; Schema: lib; Owner: -
--

SELECT pg_catalog.setval('lib.authors_author_id_seq', 201, true);


--
-- Name: book_instance_instance_id_seq; Type: SEQUENCE SET; Schema: lib; Owner: -
--

SELECT pg_catalog.setval('lib.book_instance_instance_id_seq', 344, true);


--
-- Name: books_book_id_seq; Type: SEQUENCE SET; Schema: lib; Owner: -
--

SELECT pg_catalog.setval('lib.books_book_id_seq', 235, true);


--
-- Name: genres_genre_id_seq; Type: SEQUENCE SET; Schema: lib; Owner: -
--

SELECT pg_catalog.setval('lib.genres_genre_id_seq', 26, true);


--
-- Name: spotlight_works_serial_seq; Type: SEQUENCE SET; Schema: lib; Owner: -
--

SELECT pg_catalog.setval('lib.spotlight_works_serial_seq', 213, true);


--
-- Name: authors authors_pkey; Type: CONSTRAINT; Schema: lib; Owner: -
--

ALTER TABLE ONLY lib.authors
    ADD CONSTRAINT authors_pkey PRIMARY KEY (author_id);


--
-- Name: book_genres book_genres_pkey; Type: CONSTRAINT; Schema: lib; Owner: -
--

ALTER TABLE ONLY lib.book_genres
    ADD CONSTRAINT book_genres_pkey PRIMARY KEY (genre_id, book_id);


--
-- Name: book_instance book_instance_pkey; Type: CONSTRAINT; Schema: lib; Owner: -
--

ALTER TABLE ONLY lib.book_instance
    ADD CONSTRAINT book_instance_pkey PRIMARY KEY (instance_id);


--
-- Name: books books_pkey; Type: CONSTRAINT; Schema: lib; Owner: -
--

ALTER TABLE ONLY lib.books
    ADD CONSTRAINT books_pkey PRIMARY KEY (book_id);


--
-- Name: genres genres_pkey; Type: CONSTRAINT; Schema: lib; Owner: -
--

ALTER TABLE ONLY lib.genres
    ADD CONSTRAINT genres_pkey PRIMARY KEY (genre_id);


--
-- Name: spotlight_works spotlight_works_book_id_key; Type: CONSTRAINT; Schema: lib; Owner: -
--

ALTER TABLE ONLY lib.spotlight_works
    ADD CONSTRAINT spotlight_works_book_id_key UNIQUE (book_id);


--
-- Name: spotlight_works spotlight_works_cover_id_key; Type: CONSTRAINT; Schema: lib; Owner: -
--

ALTER TABLE ONLY lib.spotlight_works
    ADD CONSTRAINT spotlight_works_cover_id_key UNIQUE (cover_id);


--
-- Name: spotlight_works spotlight_works_pkey; Type: CONSTRAINT; Schema: lib; Owner: -
--

ALTER TABLE ONLY lib.spotlight_works
    ADD CONSTRAINT spotlight_works_pkey PRIMARY KEY (serial);


--
-- Name: spotlight_works limit_spotlight; Type: TRIGGER; Schema: lib; Owner: -
--

CREATE TRIGGER limit_spotlight AFTER INSERT ON lib.spotlight_works FOR EACH ROW EXECUTE FUNCTION lib.delete_oldest_spotlight();


--
-- Name: book_instance status_due_trigger; Type: TRIGGER; Schema: lib; Owner: -
--

CREATE TRIGGER status_due_trigger BEFORE INSERT OR UPDATE ON lib.book_instance FOR EACH ROW EXECUTE FUNCTION lib.enforce_null_due();


--
-- Name: book_genres book_genres_book_id_fkey; Type: FK CONSTRAINT; Schema: lib; Owner: -
--

ALTER TABLE ONLY lib.book_genres
    ADD CONSTRAINT book_genres_book_id_fkey FOREIGN KEY (book_id) REFERENCES lib.books(book_id) ON DELETE CASCADE;


--
-- Name: book_genres book_genres_genre_id_fkey; Type: FK CONSTRAINT; Schema: lib; Owner: -
--

ALTER TABLE ONLY lib.book_genres
    ADD CONSTRAINT book_genres_genre_id_fkey FOREIGN KEY (genre_id) REFERENCES lib.genres(genre_id) ON DELETE CASCADE;


--
-- Name: book_instance book_instance_book_id_fkey; Type: FK CONSTRAINT; Schema: lib; Owner: -
--

ALTER TABLE ONLY lib.book_instance
    ADD CONSTRAINT book_instance_book_id_fkey FOREIGN KEY (book_id) REFERENCES lib.books(book_id) ON DELETE CASCADE;


--
-- Name: books fk_author; Type: FK CONSTRAINT; Schema: lib; Owner: -
--

ALTER TABLE ONLY lib.books
    ADD CONSTRAINT fk_author FOREIGN KEY (author_id) REFERENCES lib.authors(author_id) ON DELETE CASCADE;


--
-- Name: spotlight_works fk_spotlight_works_book_id; Type: FK CONSTRAINT; Schema: lib; Owner: -
--

ALTER TABLE ONLY lib.spotlight_works
    ADD CONSTRAINT fk_spotlight_works_book_id FOREIGN KEY (book_id) REFERENCES lib.books(book_id) ON DELETE CASCADE;


--
-- Name: SCHEMA lib; Type: ACL; Schema: -; Owner: -
--

GRANT USAGE ON SCHEMA lib TO libraryserver;


--
-- Name: TABLE authors; Type: ACL; Schema: lib; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE lib.authors TO libraryserver;


--
-- Name: TABLE book_genres; Type: ACL; Schema: lib; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE lib.book_genres TO libraryserver;


--
-- Name: TABLE book_instance; Type: ACL; Schema: lib; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE lib.book_instance TO libraryserver;


--
-- Name: TABLE books; Type: ACL; Schema: lib; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE lib.books TO libraryserver;


--
-- Name: TABLE genres; Type: ACL; Schema: lib; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE lib.genres TO libraryserver;


--
-- Name: TABLE spotlight_works; Type: ACL; Schema: lib; Owner: -
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE lib.spotlight_works TO libraryserver;


--
-- PostgreSQL database dump complete
--


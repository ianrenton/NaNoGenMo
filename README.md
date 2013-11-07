NaNoGenMo
=========

National Novel Generation Month.

A script to automatically generate a 50,000-word "novel" during November, as an alternative to writing it. Based on an idea by Github user [dariusk](https://github.com/dariusk) co-ordinated [here](https://github.com/dariusk/NaNoGenMo).

My script automatically scrapes user-submitted stories from FanFiction.net, mashes them together and remixes them into something almost entirely devoid of meaning.

Usage
-----

* Only one file is important: `nanogenmo.rb`. Download it, or clone the repo, whatever you feel like.
* You will need the `nokogiri` gem installed. This can be a pain in the arse on some platforms. Google it.
* Edit `nanogenmo.rb` in your choice of editor, and look at the configuration options at the top. You'll want to set `INDEX_URL` to a list of stories on Fanfiction.net that you want to generate your story from. Some examples are given.
* Other configuration options are provided with comments. You may want to generate a story of a different length (`WORD_GOAL`), create a larger data set (`MAX_PAGES`), etc.
* Run the script using `ruby nanogenmo.rb`. Depending on your options, connection speed and the whim of the Fanfiction.net servers, this may take a long time.
* Your story will be saved to `story.md` (Markdown format) and `story.html` (HTML format).
* Read and enjoy!

* If you have run the script previously, you will have a `cache.yaml` file saved which contains all the data scrapted from Fanfiction.net. If you want to tweak the story generation parameters but use the same data set (saving a shitload of time) you can set `FETCH_LIVE_DATA = true`) in the script.

FAQ
---

* **What kind of stories does this generate?**<br/>It's like viagra spammers decided to write about Harry Potter's secret romances.
* **So it's completely unintelligible?**<br/>The source material is Fanfiction.net. Garbage in, garbage out. (I jest. Half these people are better writers than me anyway.)
* **Will I see adult content?**<br/>Depends which Fanfiction.net index page you give it to work with. I think ff.net bans NC-17 material, so it's probably not going to be too graphic.
* **Do the generated stories infringe copyright?**<br/>Not a clue. I think there are more important reasons why you wouldn't publish the output.
* **The generated text is full of weird half-sentences, what gives?**<br/>The regular expression parser assumes the Fanfiction.net authors have a proper grasp of punctuation and grammar. Regrettably this is not always the case.
* **Why is some of it in a foreign language?**<br/>NaNoGenMo doesn't discriminate, man! It just uses the stories you point it at. You can generate a story entirely in another language by using ff.net's search.
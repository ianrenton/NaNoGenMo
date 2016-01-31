NaNoGenMo
=========

National Novel Generation Month.

A script to automatically generate a 50,000-word "novel" during November, as an alternative to writing it. Based on an idea by Github user [dariusk](https://github.com/dariusk) co-ordinated [here](https://github.com/dariusk/NaNoGenMo).

My script automatically scrapes user-submitted stories from FanFiction.net, mashes them together and remixes them into something almost entirely devoid of meaning.

You can see an example of what it generates at [http://ianrenton.github.io/NaNoGenMo/example.html](http://ianrenton.github.io/NaNoGenMo/example.html).

Usage
-----

* Only two files are important: `nanogenmo.rb` and `story.erb`. Download them, or clone the repo, whatever you feel like.
* You will need the `nokogiri` and `redcarpet` gems installed. These require native extensions, which can be a pain in the arse on some platforms. Google it if you have problems.
* Edit `nanogenmo.rb` in your choice of editor, and look at the configuration options at the top. You'll want to set `INDEX_URLS` to an array of  Fanfiction.net index page URLs that you want to generate your story from. Some examples are given, and you can use as many as you like.
* Other configuration options are provided with comments. You may want to generate a story of a different length (`WORD_GOAL`), create a larger data set (`MAX_PAGES`), etc.
* Run the script using `ruby nanogenmo.rb`. Depending on your options, connection speed and the whim of the Fanfiction.net servers, this may take a long time.
* Your story will be saved to `story.md` (Markdown format) and `story.html` (HTML format).
* Read and enjoy!

* If you have run the script previously, you will have a `cache.yaml` file saved which contains all the data scraped from Fanfiction.net. If you want to tweak the story generation parameters but use the same data set (saving a shitload of time) you can set `FETCH_LIVE_DATA = false` in the script.

FAQ
---

* **What kind of stories does this generate?**<br/>It's from a dystopian future where [Bayesian poisoning](http://en.wikipedia.org/wiki/Bayesian_poisoning) spammers hawk My Little Pony / Sonic the Hedgehog fanfiction written by confused 12-year-olds.
* **So it's completely unintelligible?**<br/>The source material is Fanfiction.net. Garbage in, garbage out. (Only joking :)
* **Will I see adult content?**<br/>Depends which Fanfiction.net index page you give it to work with. I think ff.net bans NC-17 material, so it's probably not going to be too graphic.
* **Do the generated stories infringe copyright?**<br/>Maybe?  If you're considering publishing the output of this script, you have more important problems than copyright. I recommend the services of a mental health professional.
* **Does running this violate Fanfiction.net's Terms of Service?**<br/>Yep. If you're an actual Fanfiction.net user you probably want to log out before running this. I take no responsibility if you get banned.
* **The generated text is full of weird half-sentences, what gives?**<br/>The regular expression parser assumes the Fanfiction.net authors have a proper grasp of punctuation and grammar. Regrettably this is not always the case.
* **Why is some of it in a foreign language?**<br/>NaNoGenMo doesn't discriminate, man! It just uses the stories you point it at. If you only want English, make sure the stories on the page you run the script on are all in English. If your language tastes lie elsewhere, you can use ff.net's advanced search to fetch stories in any language you like, and use that as the input.
* **What's the best combination of sentences you've seen it add to a story?**<br/>"Rose, stop. We can't do another fight like this."<br/>"No. I think I have a lifetime spanner ban," she said ruefully.
* **The darkest?**<br/>"Bella it's either your dad or abortion" he said.<br/>"Why not? I mean, other than for my pleasures."
* **And the best auto-generated title?**<br/>Chapter 5. Should we go make sure Kari and my mum haven't killed each other?

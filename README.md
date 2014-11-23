NaNoGenMo
=========

National Novel Generation Month.

A script to automatically generate a 50,000-word "novel" during November, as an alternative to writing it. Based on an idea by Github user [dariusk](https://github.com/dariusk) co-ordinated [here](https://github.com/dariusk/NaNoGenMo).

The original script harvested fiction from Fanfiction.net to generate its stories. This is a quick hack to load data from local files inside the `files/` directory instead.

You can see an example of what it generates at http://ianrenton.github.io/NaNoGenMo/example.html

Usage
-----

* Only two files are important: `nanogenmo.rb` and `story.erb`. Download them, or clone the repo, whatever you feel like.
* You will need the `nokogiri` and `redcarpet` gems installed. These require native extensions, which can be a pain in the arse on some platforms. Google it if you have problems.
* Edit `nanogenmo.rb` in your choice of editor, and look at the configuration options at the top. You can set `FILES_DIR` to something other than `./files/` if you like.
* Other configuration options are provided with comments. You may want to generate a story of a different length (`WORD_GOAL`), create a larger data set (`MAX_PAGES`), etc.
* Run the script using `ruby nanogenmo.rb`. Depending on your options, this may take a long time.
* Your story will be saved to `story.md` (Markdown format) and `story.html` (HTML format).
* Read and enjoy!

* If you have run the script previously, you will have a `cache.yaml` file saved which contains all the data scraped from the files. If you want to tweak the story generation parameters but use the same data set (saving a shitload of time) you can set `FETCH_LIVE_DATA = false` in the script.


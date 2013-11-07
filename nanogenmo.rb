#!/usr/bin/env ruby
# encoding: UTF-8

# Generates random fiction by harvesting stories from Fanfiction.net and randomly
# combining the sentences it finds.

require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'yaml'

######### CONFIGURATION ##########

# Pick a Fanfiction.net page that has links to stories
INDEX_URL = 'http://www.fanfiction.net/tv/Doctor-Who/'

# Fetch live data from the web. "true" is the normal use case. If you have previously run
# the script and want to run it again to get a new story with the same data set (i.e.
# without spending ages scraping data from the web again) you can set this to "false".
FETCH_LIVE_DATA = true

## Less common config options
# Fanfiction.net base URL for following relative links
BASE_URL = 'http://www.fanfiction.net'
# Fake a user agent to avoid getting 403 errors
USER_AGENT = 'Mozilla/5.0 (X11; Ubuntu; Linux armv7l; rv:24.0) Gecko/20100101 Firefox/24.0'
# File names to use
DATA_CACHE_FILE_NAME = 'cache.yaml'
STORY_FILE_NAME = 'story.txt'
# Tags, IDs, classes and regexes to find and extract stories, pages, and sentences.
STORY_LINK_CLASS = 'stitle'
CHAPTER_SELECT_ID = 'chap_select'
PARAGRAPH_TAG = 'p'
SENTENCE_REGEX = '' # TODO
# Tweaks
MIN_WORDS_PER_SENTENCE = 4
WORD_GOAL = 50000

######### CODE STARTS HERE ##########

# If we're fetching live data, as opposed to reading an existing file...
if FETCH_LIVE_DATA
	# First fetch the HTML for the chosen index page, and find all the links to stories.
	print 'Finding stories...'
	indexHTML = Nokogiri::HTML(open(INDEX_URL, 'User-Agent' => USER_AGENT))
	storyLinkTags = indexHTML.css("a.#{STORY_LINK_CLASS}")
	storyURLs = []
	storyLinkTags.each do |tag|
		storyURLs << BASE_URL + tag['href']
	end
	print " #{storyURLs.size} found.\n"

	# Now you have a link to the "Chapter 1" page of each story. For each "Chapter 1" page,
	# look for a SELECT box that will provide links to any other chapters. Add them all to
	# a new array of pages.
	print 'Finding pages...'
	pageURLs = []
	storyURLs.each do |chapterOneURL|
		# The URL we already have is a valid page, so add that first
		pageURLs << chapterOneURL
		
		# Now go looking for others
		chapterOneHTML = Nokogiri::HTML(open(chapterOneURL, 'User-Agent' => USER_AGENT))
		optionElements = chapterOneHTML.css("select\##{CHAPTER_SELECT_ID} option")
		optionElements.each do |option|
		  # Figure out what the URL for that page would be
		  chapterURL = chapterOneURL.sub(/\/1\//, "\/#{option['value']}\/")
		  # Add to the page URLs list if it's not already in there
		  if !pageURLs.include?(chapterURL)
		    print '.'
		  	pageURLs << chapterURL
		  end
		end
	end
	print " #{pageURLs.size} found.\n"

	# Create a data structure that will hold each sentence in an array, sorted by which
	# type of sentence it is.
	sentences = {
		:startChapters => [],
		:endChapters => [],
		:startParagraphs => [],
		:midParagraphs => [],
		:endParagraphs => [],
		:dialogue => []
	}
	
	# For each page URL, load the page and extract sentences.
	# TODO
	
	# Serialise the data to disk for later use
	print "Saving data to #{DATA_CACHE_FILE_NAME}..."
	serialisedSentences = YAML::dump(sentences)
	File.open(DATA_CACHE_FILE_NAME, 'w') { |file| file.write(serialisedSentences) }
	print " Done.\n"

else
	# We're not fetching live data, so load it from a file saved previously
	
	if File.file?(DATA_CACHE_FILE_NAME)
		print "Loading data from #{DATA_CACHE_FILE_NAME}..."
		serialisedSentences = File.read(DATA_CACHE_FILE_NAME)
		sentences = YAML::load(serialisedSentences)
		print " Done.\n"
	else
	  # No file, so error out
		print "FETCH_LIVE_DATA was set to 'false' but a data file named #{DATA_CACHE_FILE_NAME} could not be found. This means there is no source of data for the script to use. Check your configuration.\n"
		exit
	end

end

# Start generating. If we get here, we know that sentences has contents that we can use.
# TODO
#!/usr/bin/env ruby
# encoding: UTF-8

# Generates random fiction by harvesting stories from Fanfiction.net and randomly
# combining the sentences it finds.

require 'rubygems'
require 'nokogiri'
require 'open-uri'

######### CONFIGURATION ##########

# Pick a Fanfiction.net page that has links to stories
INDEX_URL = 'http://www.fanfiction.net/tv/Doctor-Who/'
# Fanfiction.net base URL for following relative links
BASE_URL = 'http://www.fanfiction.net'
# Fake a user agent to avoid getting 403 errors
USER_AGENT = 'Mozilla/5.0 (X11; Ubuntu; Linux armv7l; rv:24.0) Gecko/20100101 Firefox/24.0'
# Tags, IDs, classes and regexes to find and extract stories, pages, and sentences.
STORY_LINK_CLASS = 'stitle'
CHAPTER_SELECT_ID = 'chap_select'
PARAGRAPH_TAG = 'p'
SENTENCE_REGEX = '' # TODO
# Tweaks
MIN_WORDS_PER_SENTENCE = 4
WORD_GOAL = 50000

######### CODE STARTS HERE ##########

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

# TODO: Nokogiri all the pages, extract sentences from P blocks. Combine randomly. Add paragraph breaks by remembering whether harvested sentences began, ended or both a paragraph. Some analysis of sentences to clump similar subjects together.
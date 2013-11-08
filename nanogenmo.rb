#!/usr/bin/env ruby
# encoding: UTF-8

# Generates random fiction by harvesting stories from Fanfiction.net and semi-randomly
# combining the sentences it finds.

require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'yaml'
require 'redcarpet'
require 'erb'

#########################################
#            SOURCE MATERIAL            #
#########################################

# Pick a Fanfiction.net page that has links to stories. This can be a category, user or
# search page, e.g.
# http://www.fanfiction.net/tv/Doctor-Who/
# http://www.fanfiction.net/Sonic-the-Hedgehog-and-My-Little-Pony-Crossovers/253/621/
# http://www.fanfiction.net/search.php?keywords=cupcakes&ready=1&type=story
# http://www.fanfiction.net/u/1234567/UserName
INDEX_URL = 'http://www.fanfiction.net/tv/Doctor-Who/'

# A list of words which, if present in a sentence, will disqualify it from use in
# the generator. Used to catch sentences which aren't part of the actual text.
BANNED_WORDS = ['Chapter', 'chapter', 'Ch.', 'review', 'A/N', 'Note', '*', '1.', '2.', '3.', '4.', '5.', '6.', '7.', '8.', '9.', '0.', ':', '^_^', 'R&R', 'POV']

#########################################
#         WEB SCRAPING CONFIG           #
#########################################

# Fetch live data from the web. "true" is the normal use case. If you have previously run
# the script and want to run it again to get a new story with the same data set (i.e.
# without spending ages scraping data from the web again) you can set this to "false".
FETCH_LIVE_DATA = true

# Stop after finding this many pages to avoid huge data sets
MAX_PAGES = 100

# Delay between requesting pages from fanfiction.net, to be nice. Seconds.
# The default 5 seconds makes data collection take a LONG TIME. Smaller values are
# fine right up until fanfiction.net IP-bans you :(
PAGE_DELAY = 5

#########################################
#       STORY GENERATION CONFIG         #
#########################################

# Number of words to aim for.
WORD_GOAL = 50000

# Number of chapters to write. Each will be roughly WORD_GOAL/NUM_CHAPTERS words long.
NUM_CHAPTERS = 20

# For every 1 proper paragraph, there will be this many solitary (one-sentence)
# paragraphs.
SOLITARY_RATE = 0.1

# For every 1 proper paragraph, there will be this many dialogue sequences.
DIALOGUE_RATE = 0.2

# Maximum number of sentences per paragraph
MAX_SENT_PER_PARA = 6

# Maximum number of sentences / lines in a dialogue sequence.
MAX_SENT_PER_DIALOGUE = 6

#########################################
#            GLOBAL DEFINES             #
#   You shouldn't need to edit these    #
#########################################

# Fake a user agent to avoid getting 403 errors
USER_AGENT = 'Mozilla/5.0 (X11; Ubuntu; Linux armv7l; rv:24.0) Gecko/20100101 Firefox/24.0'
# Intermediate and output file names to use
DATA_CACHE_FILE_NAME = 'cache.yaml'
STORY_MARKDOWN_FILE_NAME = 'story.md'
STORY_HTML_FILE_NAME = 'story.html'
# Element IDs, classes and regexes to find and extract stories, pages, and sentences.
STORY_LINK_CLASS = 'stitle'
CHAPTER_SELECT_ID = 'chap_select'
STORY_TEXT_ID = 'storytext'
SENTENCE_REGEX = /[^.!?\s][^.!?]*(?:[.!?](?!['"]?\s|$)[^.!?]*)*[.!?]?['"]?(?=\s|$)/
QUOTED_TEXT_REGEX = /"([^"]*)"/
STRIP_FROM_TITLE_REGEX = /[\,\.\"]/

#########################################
#          METHODS START HERE           #
#########################################

# Makes a title for the story or a chapter
def makeTitle()
  title = ''
  while title == ''
    tmpTitle = @sentences[:dialogue][rand(@sentences[:dialogue].size - 1)]
    quotedSections = tmpTitle.scan(QUOTED_TEXT_REGEX)
    if !quotedSections.nil? && !quotedSections[0].nil?
      title = quotedSections[0][0].gsub(STRIP_FROM_TITLE_REGEX, '')
    end
  end
  return title
end

#########################################
#       MAIN SCRIPT STARTS HERE         #
#########################################

# Store start time
startTime = Time.now
print "NaNoGenMo started at: #{startTime}\n"

# If we're fetching live data, as opposed to reading an existing file...
if FETCH_LIVE_DATA
  # First fetch the HTML for the chosen index page, and find all the links to stories.
  print 'Finding stories...'
  indexHTML = Nokogiri::HTML(open(INDEX_URL, 'User-Agent' => USER_AGENT))
  sleep(PAGE_DELAY)
  storyLinkTags = indexHTML.css("a.#{STORY_LINK_CLASS}")
  storyURLs = []
  # Work out the base URL (fanfiction.net) to append to relative links
  uri = URI.parse(INDEX_URL)
  baseURL = "#{uri.scheme}://#{uri.host}"
  # Compile a list of all the links to stories
  storyLinkTags.each do |tag|
    storyURLs << baseURL + tag['href']
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
    begin
      chapterOneHTML = Nokogiri::HTML(open(chapterOneURL, 'User-Agent' => USER_AGENT))
      sleep(PAGE_DELAY)
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
    rescue
      print "\nFailed to load and parse a page. Carrying on..."
    end
    
  end
  print " #{pageURLs.size} found.\n"
  
  # Limit the number of pages found if necessary
  if pageURLs.size > MAX_PAGES
    print "Restricting page list to #{MAX_PAGES} to avoid a huge data set.\n"
    pageURLs = pageURLs[0..(MAX_PAGES-1)]
  end

  # Create a data structure that will hold each sentence in an array, sorted by which
  # type of sentence it is.
  @sentences = {
    :startChapters => [],
    :endChapters => [],
    :startParagraphs => [],
    :midParagraphs => [],
    :endParagraphs => [],
    :solitary => [],
    :dialogue => []
  }
  
  # For each page URL, load the page and extract sentences.
  print 'Extracting sentences'
  pageURLs.each do |pageURL|
    print '.'
    begin
      pageHTML = Nokogiri::HTML(open(pageURL, 'User-Agent' => USER_AGENT))
      sleep(PAGE_DELAY)
      paragraphs = pageHTML.css("div\##{STORY_TEXT_ID} p")
      paragraphs.each_with_index do |para, pi|
        # Take the contents of each <p> element, remove linebreaks and scan for sentences
        tmpSentences = para.text.tr("\n"," ").tr("\r"," ").scan(SENTENCE_REGEX)
        tmpSentences.each_with_index do |tmpSentence, i|
          # Check for 'banned' words, only proceed if they are not present
          if !(BANNED_WORDS.any? { |word| tmpSentence.include?(word) })
            # Based on the sentence's position and content, decide what type it is and
            # thus into which bucket it goes.
            if (pi == 0) && (i == 0)
              @sentences[:startChapters] << tmpSentence
            elsif (pi == paragraphs.size - 1) && (i == tmpSentences.size - 1)
              @sentences[:endChapters] << tmpSentence
            elsif tmpSentence.include? '"'
              @sentences[:dialogue] << tmpSentence
            elsif tmpSentences.size == 1
              @sentences[:solitary] << tmpSentence
            elsif i == 0
              @sentences[:startParagraphs] << tmpSentence
            elsif i == tmpSentences.size - 1
              @sentences[:endParagraphs] << tmpSentence
            else
              @sentences[:midParagraphs] << tmpSentence
            end
          end
        end
      end
    rescue
      print "\nFailed to load and parse a page. Carrying on..."
    end
  end
  print " #{@sentences[:startChapters].size + @sentences[:endChapters].size + @sentences[:startParagraphs].size + @sentences[:midParagraphs].size + @sentences[:endParagraphs].size + @sentences[:solitary].size + @sentences[:dialogue].size} found.\n"
  
  # Serialise the data to disk for later use
  print "Saving data to #{DATA_CACHE_FILE_NAME}..."
  serialisedSentences = YAML::dump(@sentences)
  File.open(DATA_CACHE_FILE_NAME, 'w') { |file| file.write(serialisedSentences) }
  print " Done.\n"

else
  # We're not fetching live data, so load it from a file saved previously
  
  if File.file?(DATA_CACHE_FILE_NAME)
    print "Loading data from #{DATA_CACHE_FILE_NAME}..."
    serialisedSentences = File.read(DATA_CACHE_FILE_NAME)
    @sentences = YAML::load(serialisedSentences)
    print " #{@sentences[:startChapters].size + @sentences[:endChapters].size + @sentences[:startParagraphs].size + @sentences[:midParagraphs].size + @sentences[:endParagraphs].size + @sentences[:solitary].size + @sentences[:dialogue].size} sentences loaded.\n"
  else
    # No file, so error out
    print "FETCH_LIVE_DATA was set to 'false' but a data file named #{DATA_CACHE_FILE_NAME} could not be found. This means there is no source of data for the script to use. Check your configuration.\n"
    exit
  end

end


# Start generating. If we get here, we know that sentences has contents that we can use.
story = ''

# Write a title. Steal a line of dialog so we have something 'punchy' (or just weird)
# Underline it in Markdown style.
print 'Writing a story called... '
title = makeTitle()
story << "# #{title}\n\n"
print "\"#{title}\".\n"

print 'Generating text.'

# Word out how long each chapter should be
chapterLength = WORD_GOAL / NUM_CHAPTERS

# Generate a number of chapters
for chapterNumber in 1..NUM_CHAPTERS

  # Insert a chapter heading
  chapterTitle = makeTitle()
  story <<  "## Chapter #{chapterNumber}. #{chapterTitle}\n\n"

  # Start the chapter with an opening sentence
  story << @sentences[:startChapters][rand(@sentences[:startChapters].size - 1)] << "\n\n"

  # Keep going until word count goal for this chapter is reached
  while story.split.size < chapterLength * chapterNumber
    print '.'
    # Decide what type of section we are going into - a proper paragraph (at least 2 
    # sentences), a solitary sentence, or a dialogue section.
    roll = rand * (1 + SOLITARY_RATE + DIALOGUE_RATE)
    if roll < SOLITARY_RATE
      # Solitary. Pick a solitary paragraph and concatenate it to the story.
      story << @sentences[:solitary][rand(@sentences[:solitary].size - 1)] << "\n\n"
    elsif roll < (SOLITARY_RATE + DIALOGUE_RATE)
      # Dialogue. First work out how long the dialogue should be.
      dialogueLength = rand(MAX_SENT_PER_DIALOGUE)
      # Now add that many dialogue paragraphs.
      for i in 0..dialogueLength
        story << @sentences[:dialogue][rand(@sentences[:dialogue].size - 1)] << "\n\n"
      end
    else
      # Normal Paragraph. First work out how long the paragraph should be. Must be at
      # least 2
      paragraphLength = rand(MAX_SENT_PER_PARA - 1) + 1
      # Now add a beginning sentence, the right number of middle sentences, and an end
      # sentence.
      story << @sentences[:startParagraphs][rand(@sentences[:startParagraphs].size - 1)] << ' '
      for i in 0..paragraphLength-2
        story << @sentences[:midParagraphs][rand(@sentences[:midParagraphs].size - 1)] << ' '
      end
      story << @sentences[:endParagraphs][rand(@sentences[:endParagraphs].size - 1)] << "\n\n"
    end
  end

  # Finish the chapter with a closing sentence
  story << @sentences[:endChapters][rand(@sentences[:endChapters].size - 1)] << "\n\n"

end

print " wrote #{story.split.size} words in #{NUM_CHAPTERS} chapters!\n"

# Save the file as markdown
print 'Saving file...'
File.open(STORY_MARKDOWN_FILE_NAME, 'w') {|f| f.write(story) }
print " done.\n"

# Generate some nicer-looking HTML
print 'Generating HTML...'
markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
# Variables needed by ERB:
storyHTML = markdown.render(story)
wordCount = story.split.size
generationTime = Time.now - startTime
# Generate page with ERB
erbTemplate = File.open("story.erb", 'r').read
File.open(STORY_HTML_FILE_NAME, 'w') {|f| f.write(ERB.new(erbTemplate).result) }
print " done.\n"

print "NaNoGenMo processing complete in #{generationTime} seconds.\n"

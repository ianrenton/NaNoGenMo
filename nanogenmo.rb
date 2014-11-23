#!/usr/bin/env ruby
# encoding: UTF-8

# Generates random fiction by harvesting stories from local files and semi-randomly
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

# Path to local directory containing the files to parse
FILES_DIR = './files/'

# A list of words which, if present in a sentence, will disqualify it from use in
# the generator. Used to catch sentences which aren't part of the actual text.
BANNED_WORDS = ['Chapter', 'chapter', 'Ch.', 'review', 'A/N', 'Note', '*', '1.', '2.', '3.', '4.', '5.', '6.', '7.', '8.', '9.', '0.', ':', '^_^', '^-^', 'R&R', 'POV']

# Fetch live data from the files. "true" is the normal use case. If you have previously run
# the script and want to run it again to get a new story with the same data set (i.e.
# without spending time scraping data from the files) you can set this to "false".
FETCH_LIVE_DATA = true

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

# Intermediate and output file names to use
DATA_CACHE_FILE_NAME = 'cache.yaml'
STORY_MARKDOWN_FILE_NAME = 'story.md'
STORY_HTML_FILE_NAME = 'story.html'
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
    Dir.foreach(FILES_DIR) do |file|
      next if file == '.' or file == '..'
      print '.'
      lineNum = 0
      linesInFile = File.foreach("#{FILES_DIR}#{file}").inject(0) {|c, line| c+1}
        File.open("#{FILES_DIR}#{file}").each_line do |line|
          # Take the contents of each <p> element, remove linebreaks and scan for 
          # sentences
          tmpSentences = line.tr("\n"," ").tr("\r"," ").scan(SENTENCE_REGEX)
          tmpSentences.each_with_index do |tmpSentence, i|
            # Check for 'banned' words, only proceed if they are not present
            if !(BANNED_WORDS.any? { |word| tmpSentence.include?(word) })
              # Based on the sentence's position and content, decide what type it is and
              # thus into which bucket it goes.
              if (lineNum == 0) && (i == 0)
                @sentences[:startChapters] << tmpSentence
              elsif (lineNum == linesInFile - 1) && (i == tmpSentences.size - 1)
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
          lineNum += 1
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
story << "# The End\n\n"

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

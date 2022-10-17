require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

before do
  @contents = File.readlines("data/toc.txt")
end

helpers do
  def in_paragraphs(chapter)
    chapter.split("\n\n").each_with_index.map do |paragraph, index|
      "<p id=para#{index}>#{paragraph}</p>"
    end.join
  end

  def highlight(text, term)
    text.gsub(term, %(<strong>#{term}</strong>))
  end
end

not_found do
  redirect "/"
end

get "/" do
  @title = "The Adventures of Sherlock Holmes"
  
  erb :home
end

get "/chapters/:number" do  
  number = params[:number].to_i
  chapter_name = @contents[number - 1]
  
  redirect "/" unless (1..@contents.size).cover? number

  @title = "Chapter #{number}: #{chapter_name}"
  @chapter = File.read("data/chp#{number}.txt")

  erb :chapter
end

def remove_encoding(words)
  words.gsub("%20", " ").gsub("+", " ")
end

def each_chapter
  @contents.each_with_index do |title, index|
    number = index + 1
    contents = File.read("data/chp#{number}.txt")
    yield number, title, contents
  end
end

def matched_chapters(query)
  results = []

  return results if !query || query.empty?

  words = remove_encoding(params[:query])
  each_chapter do |number, title, contents|
    paragraphs = {}
    contents.split("\n\n").each_with_index do |paragraph, index|
      paragraphs[paragraph] = "#para#{index}" if paragraph.downcase.include?(words.downcase)
    end
    results << {number: number, title: title, paragraphs: paragraphs} unless paragraphs.empty?
  end

  results
end

get "/search" do
  @results = matched_chapters(params[:query])
  
  erb :search
end

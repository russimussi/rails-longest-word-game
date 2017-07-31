require 'open-uri'
require 'json'

class PagesController < ApplicationController
  def game
    @grid = []
    (1..15).each { @grid << ("A".."Z").to_a.sample }
  end

  def score
    @attempt = params[:query].upcase
    @start_time = Time.parse(params[:time])
    @end_time = Time.now
    @grid = params[:grid]
    @outcome = run_game(@attempt, @grid, @start_time, @end_time)
  end

  def run_game(attempt, grid, start_time, end_time)
    result = {}
    result[:time] = end_time - start_time
    result[:translation] = attempt_verification(@attempt)
    result[:game_score] = score_verification(@attempt, grid, result[:translation], result[:time])
    result[:message] = create_message(result[:game_score], @attempt, grid, result[:translation])
    result
  end

  def grid_verification(attempt, grid)
    letters_array = @attempt.upcase.chars
    letters_array.all? { |letter| letters_array.count(letter) <= grid.count(letter) }
  end

  def attempt_verification(attempt)
    url = "https://api-platform.systran.net/translation/text/translate?source=en&target=fr&key=23b48ffe-ba26-4605-ab81-48e6d2ee6edf&input=#{@attempt}"
    translation = JSON.parse(open(url).read)["outputs"][0]["output"]
    if translation == @attempt
      nil
    else
      translation
    end
  rescue
    url2 = "http://api.wordreference.com/0.8/80143/json/enfr/#{@attempt}"
    translation = JSON.parse(open(url2).read)["term0"]["PrincipalTranslations"]["0"]["FirstTranslation"]["term"]
    if translation == @attempt
      nil
    else
      translation
    end
  end

  def score_verification(attempt, grid, translated_word, time)
    return 0 unless grid_verification(@attempt, grid)
    return 0 if translated_word.nil?
    (@attempt.length / time) * 10
  end

  def create_message(game_score, attempt, grid, translated_word)
    if game_score > 0
      "well done"
    elsif grid_verification(@attempt, grid) == false
      "not in the grid"
    elsif translated_word.nil?
      "not an english word"
    end
  end
end

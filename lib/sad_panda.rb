require_relative "./sad_panda/version"
require_relative './sad_panda/emotions/emotion_bank.rb'
require_relative './sad_panda/emotions/term_polarities.rb'
require_relative './sad_panda/emotions/stopwords.rb'
require 'fast-stemmer'

module SadPanda

  # this method returns the best-fit emotion for the status message
  def self.emotion(message)
    # get the emotion for which the emotion score value is highest
    SadPanda.emotion_score(message, EmotionBank.get_term_emotions, term_frequencies(message))
  end

  # this method returns the polarity value for the status message
  # (normalized by the number of 'polar' words that the status
  # message contains)
  def self.polarity(message)
    # get the polarity for which the polarity score value is highest
    SadPanda.polarity_score(message, TermPolarities.get_term_polarities, SadPanda.term_frequencies(message))
  end


  private

  	# this method reads the text of the status message
  	# inputed by the user, removes common english words,
  	# strips punctuation and capitalized letters, isolates
  	# the stem of the word, and ultimately produces a hash
  	# where the keys are the stems of the remaining words,
  	# and the values are their respective frequencies within
  	# the status message
  	def self.term_frequencies(message, term_frequencies = {})
  		# clean the text of the status message
      happy_emoticon = happy_emoticon(message)
      sad_emoticon = sad_emoticon(message)
  		words = words_from_message_text(message)
  		#filter for english stopwords
  		stopwords = Stopwords.stopwords
  		words = words - stopwords
  		#get word stems
  		word_stems = SadPanda.word_stems words
  		#create term_frequencies
  		#return term frequency hash
    	create_term_frequencies(word_stems, term_frequencies)
    end

  	# this method takes an array of words an returns an array of word stems
  	def self.word_stems(words, output=[])
  		words.each do |word|
        output << word.stem
  		end
  		output
  	end

  	# this method takes an emotion-words hash and a hash containing word
  	# frequencies for the status message, calculates a numerical score
  	# for each possble emotion, and returns the emotion with the highest
  	# "score"
  	def self.emotion_score(message, emotions, term_frequencies, emotion_score = {})
  		term_frequencies.each do |key,value|
  			set_emotions(emotions, emotion_score, key, value)
  		end
  		# return an emotion_score_hash to be processed by emotion
      # get clue from any emoticons present
      check_emoticon_for_emotion(emotion_score, message)
  	end

  	# this method gives the status method a normalized polarity
  	# value based on the words it contains
  	def self.polarity_score (message, polarity_hash, term_frequencies, polarity_scores = [])
  		term_frequencies.each do |key, value|
        set_polarities(key, value, polarity_hash, polarity_scores)
  		end

  		# return an polarity_score_hash to be processed by polarity method
  		# return an emotion_score_hash to be processed by emotion
      # get clue from any emoticons present
      check_emoticon_for_polarity(polarity_scores, message)
  	end

    def self.happy_emoticon(message)
      (message.include?(":)") || message.include?(":-)") || message.include?(":]") || message.include?(":-]"))
    end

    def self.sad_emoticon(message)
      (message.include?(":(") || message.include?(":-(") || message.include?(":[") || message.include?(":-["))
    end

    def self.words_from_message_text(message)
      message.gsub!(/[^a-z ]/i, '')
      message.downcase!
      message.gsub!(/((([A-Za-z]{3,9}:(?:\/\/)?)(?:[-;:&=\+\$,\w]+@)?[A-Za-z0-9.-]+|(?:www.|[-;:&=\+\$,\w]+@)[A-Za-z0-9.-]+)((?:\/[\+~%\/.\w-_]*)?\??(?:[-\+=&;%@.\w_]*)#?(?:[\w]*))?)/, '')
      message.gsub!(/(?=\w*h)(?=\w*t)(?=\w*t)(?=\w*p)\w*/, '')
      message.gsub!(/\s\s+/,' ')
      message.split(" ")
    end

    def self.set_emotions(emotions, emotion_score, term, frequency)
      emotions.keys.each do |k|
        store_emotions(emotions, emotion_score, k, term, frequency)
      end
    end

    def self.set_polarities(term, frequency, polarity_hash, polarity_scores)
      polarity_hash.keys.each do |k|
        store_polarities(term, k, polarity_hash, polarity_scores)
      end
    end

    def self.store_emotions(emotions, emotion_score, emotion, term, frequency)
      if emotions[emotion].include?(term)
        emotion_score[emotion] ||= 0
        emotion_score[emotion] += frequency
      end
    end

    def self.store_polarities(term, word, polarity_hash, polarity_scores)
      if term == word
        polarity_scores << (polarity_hash[word].to_f)
      end
    end

    def self.check_emoticon_for_emotion(emotion_score, message)
      if (happy_emoticon(message) && sad_emoticon(message))
         "ambiguous"
      elsif happy_emoticon(message)
         "joy"
      elsif sad_emoticon(message)
         "sadness"
      else
        return_emotion_score(emotion_score)
      end
    end

    def self.return_emotion_score(emotion_score)
      ## 0 if unable to detect emotion
      if emotion_score.empty?
        "ambiguous"
      else
        emotion_score.max_by{|k, v| v}[0]
      end
    end

    def self.check_emoticon_for_polarity(polarity_scores, message)
      if (happy_emoticon(message) && sad_emoticon(message))
        score = 5
      elsif happy_emoticon(message)
        score = 8
      elsif sad_emoticon(message)
        score = 2
      else
        return_polarity_scores(polarity_scores)
      end
    end

    def self.return_polarity_scores(polarity_scores)
      if polarity_scores.empty?
        # polarity unreadable; return a neutral score of 5
        5
      else
        polarity_scores.inject(0.0){ |sum, el| sum + el}/polarity_scores.length
      end
    end

    def self.create_term_frequencies(word_stems, term_frequencies)
      word_stems.each do |stem|
        term_frequencies[stem] = word_stems.count(stem)
      end
      term_frequencies
    end


end

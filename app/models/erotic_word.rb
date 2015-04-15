class EroticWord < ActiveRecord::Base
  before_save :check_word_exist

  before_create do
    self.first_word = first_word.downcase if first_word =~ /^[A-Z]$/
  end

  def check_word_exist
    if self.class.all_word.include?(word)
      false
    else
      true
    end
  end

  def self.all_word
    self.all.map(&:word)
  end
end

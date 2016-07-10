require 'digest'

module Util
  def self.build_initial_plain_text
    "0" * 1_000
  end

  def self.cipher_text(plain_text)
    Digest::SHA256.hexdigest(plain_text)
  end

  def self.cipher_text_similarity_score(cipher_text1, cipher_text2)
    binary1 = hex_to_binary(cipher_text1)
    binary2 = hex_to_binary(cipher_text2)

    (0..255).to_a.inject(0) do |sum, index|
      binary1[index] == binary2[index] ? sum + 1 : sum
    end
  end

  def self.hex_to_binary(num)
    num.hex.to_s(2).rjust(num.size*4, '0')
  end
end

module Mutator
  def self.flip_char_at_position(plain_text, positions)
    plain_text_new = plain_text.clone

    positions.each do |position|
      char = plain_text_new[position]
      plain_text_new[position] = (char == '1' ? '0' : '1')
    end

    plain_text_new
  end
end

class Round
  attr_reader :plain_text, :final_score, :success

  def initialize(plain_text, original_cipher_text)
    @plain_text = plain_text
    @original_cipher_text = original_cipher_text
    @beginning_cipher_text = Util.cipher_text(@plain_text)
    @beginning_score = Util.cipher_text_similarity_score(@beginning_cipher_text, @original_cipher_text)
    @final_score = @beginning_score
    @success = false
    @cycles = 0
  end

  def run
    puts "*** Starting Round #{@beginning_score}"
    run_single_char
    puts "Final Score: #{@final_score}"
    puts "Cycles: #{@cycles}"
  end

  def score_it(plain_text_new)
    Util.cipher_text_similarity_score(
      Util.cipher_text(
        plain_text_new
      ),
      @original_cipher_text
    )
  end

  def run_single_char
    positions = (0..(@plain_text.size)).to_a.shuffle
    current_score = @beginning_score

    plain_text_new = nil
    while !@success && !positions.empty?
      @cycles += 1
      position = positions.pop
      plain_text_new = Mutator.flip_char_at_position(@plain_text, [position])
      current_score = score_it(plain_text_new)

      if current_score == @beginning_score
        @plain_text = plain_text_new
      end

      if current_score > @beginning_score
        @plain_text = plain_text_new
        @final_score = current_score
        @success = true
      end
    end

  end
end

class Game

end

original_cipher_text = ARGV[0]

plain_text = Util.build_initial_plain_text

round = Round.new(plain_text, original_cipher_text)
round.run

#while round.success
10.times do
  round = Round.new(round.plain_text, original_cipher_text)
  round.run
end
require 'digest'

# Digest::MD5.hexdigest("happy" * 10)
# "d626f7aa9894c7131735927815461006"

module Util
  def self.build_initial_plain_text
    "0" * 512
  end

  def self.cipher_text(plain_text)
    Digest::MD5.hexdigest(plain_text)
  end

  def self.cipher_text_similarity_score(cipher_text1, cipher_text2)
    binary1 = hex_to_binary(cipher_text1)
    binary2 = hex_to_binary(cipher_text2)

    (0..127).to_a.inject(0) do |sum, index|
      binary1[index] == binary2[index] ? sum + 1 : sum
    end
  end

  def self.hex_to_binary(num)
    num.hex.to_s(2).rjust(num.size*4, '0')
  end
end

module Mutator
  def self.mutate(plain_text, positions)
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

  def initialize(plain_text, original_cipher_text, positions_count)
    @plain_text = plain_text
    @original_cipher_text = original_cipher_text
    @beginning_cipher_text = Util.cipher_text(@plain_text)
    @beginning_score = Util.cipher_text_similarity_score(@beginning_cipher_text, @original_cipher_text)
    @final_score = @beginning_score
    @success = false
    @cycles = 0
    @winning_positions = nil
    @positions_count = positions_count || rand(20) + 1
  end

  def positions_generator
    (1..@positions_count).map {|n| rand(plain_text.size) }.sort.uniq
  end

  def run
    run_simple
  end

  def to_s
    [
      "Score Begin: #{@beginning_score}",
      "Score End: #{@final_score}",
      "Cycles: #{@cycles}",
      "Positions: #{@winning_positions.join(',')}"
    ].join("\t")
  end

  def score_it(plain_text_new)
    Util.cipher_text_similarity_score(
      Util.cipher_text(
        plain_text_new
      ),
      @original_cipher_text
    )
  end

  def run_simple
    current_score = @beginning_score

    plain_text_new = nil
    while !@success
      @cycles += 1
      positions = positions_generator
      plain_text_new = Mutator.mutate(@plain_text, positions)
      current_score = score_it(plain_text_new)

      if current_score == @beginning_score
        @plain_text = plain_text_new
      end

      if current_score > @beginning_score
        @plain_text = plain_text_new
        @final_score = current_score
        @success = true
        @winning_positions = positions
      end
    end

  end
end

module DataGatherer
  def self.run(plain_text, original_cipher_text, positions_count = nil)
    (1..1_000_000).each do |i|
      print "#{i} " if i % 10_000 == 0
      single_cycle(plain_text, original_cipher_text, positions_count)
    end

    puts ''
  end

  def self.single_cycle(plain_text, original_cipher_text, positions_count)
    round = Round.new(plain_text, original_cipher_text, positions_count)
    round.run
    write_to_file(round.to_s)
  end

  def self.write_to_file(string)
    File.open("data_gathering.tsv", 'a') {|fh| fh.write(string.strip + "\n") }
  end

  # positions: 16	=>	51720
  # positions: 15	=>	51674
  # positions: 18	=>	51577
  # positions: 17	=>	51480
  # positions: 13	=>	51328
  # positions: 14	=>	51261
  # positions: 12	=>	51170
  # positions: 11	=>	51165
  # positions: 9	=>	50957
  # positions: 10	=>	50840
  # positions: 5	=>	50721
  # positions: 7	=>	50677
  # positions: 8	=>	50627
  # positions: 6	=>	50621
  # positions: 4	=>	50377
  # positions: 2	=>	50257
  # positions: 1	=>	50227
  # positions: 3	=>	50203
  # positions: 19	=>	48730
  # positions: 20	=>	34388
  def self.interpret_raw_results
    position_count_frequency = Hash.new(0)
    counter = 0
    lines = IO.readlines("data_gathering.tsv")
    lines.each do |line|
      counter += 1
      positions = line.strip.split("\t")[3].split(' ')[1]
      position_count_frequency[positions.split(',').count] += 1
    end

    position_count_frequency.sort {|a,b| b[1] <=> a[1]}.each do |key, value|
      puts "positions: #{key}\t=>\t#{value}"
    end
  end

  def self.stats
    even_vs_odd = Hash.new(0)
    lines = IO.readlines("data_gathering.tsv")
    lines.each do |line|
      positions = line.strip.split("\t")[3].split(' ')[1].split(',')
      positions.each do |position|
        key = (position.to_i % 2 == 0 ? 'even' : 'odd')
        even_vs_odd[key] += 1
      end
    end

    even_vs_odd.sort {|a,b| b[1] <=> a[1]}.each do |key, value|
      puts "#{key}\t=>\t#{value}"
    end
  end
end


  #original_cipher_text = ARGV[0]
  # d626f7aa9894c7131735927815461006
original_cipher_text = Digest::MD5.hexdigest("happy" * 10)

plain_text = Util.build_initial_plain_text

#DataGatherer.run(plain_text, original_cipher_text, 16)

#DataGatherer.interpret_raw_results

DataGatherer.stats


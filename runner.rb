require 'digest'

# # happyhappyhappyhappyhappyhappyhappyhappyhappyhappy
# plain_text = "happy" * 10

# # 8667cf2942a759f257177010b094539dd6084a8f0147f01fa3284cc3310721c8
# cipher_text = Digest::SHA256.hexdigest(plain_text)

class Array
  def sum
    self.inject(0.0) { |sum, x| sum += x }
  end

  def mean
    return nil if self.empty?
    sum / self.size
  end

  def median
    return nil if self.empty?
    array = self.sort
    m_pos = array.size / 2
    return array.size % 2 == 1 ? array[m_pos] : array[m_pos-1..m_pos].mean
  end
end

module Util
  def self.cipher_text_it(plain_text)
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

  def self.generate_random_solution(original_cipher_text)
    Solution.new(generate_plain_text, original_cipher_text, 1, 'Random')
  end

  def self.generate_plain_text
    rand(10**100).to_s(2)
  end

  def self.mutate(plain_text)
    position = rand(plain_text.size)
    char = plain_text[position]
    plain_text[position] = (char == '1' ? '0' : '1')
    plain_text
  end
end

class Solution
  include Comparable

  attr_reader :cipher_text, :score, :age, :plain_text, :generation

  def initialize(plain_text, original_cipher_text, generation, classification)
    @plain_text     = plain_text
    @original_cipher_text  = original_cipher_text
    @cipher_text           = Util.cipher_text_it(plain_text.to_s)
    @generation     = generation
    @classification = classification
    @age            = 0
    compute_score
  end

  def <=>(anOther)
    @score <=> anOther.score
  end

  def increment_age!
    @age += 1
  end

#  def mutate!
#    @plain_text = Util.mutate(@plain_text.clone)
#    @generation += 1
#    @classification = 'Mutant'
#    compute_score
#  end

  def to_s
    [
      "Score: #{@score}",
      "Match %: #{100 * @score / 256}",
      "Gen: #{@generation}  ",
      "Age: #{@age}  ",
      "Class: #{@classification}",
      "Plain: #{@plain_text[0..12]}",
      "cipher_text: #{@cipher_text[0..12]}"
    ].join("\t")
  end

  private

  def compute_score
    @score = Util.cipher_text_similarity_score(@cipher_text, @original_cipher_text)
  end
end

module Raffle
  def self.pick_solution_cipher_text_to_kill_off(solutions)
#    max_score = solutions.map {|s| s.score}.max
#    hat = []
#    solutions.each do |s|
#      entries_into_the_hat = max_score - s.score
#      entries_into_the_hat.times { hat << s.cipher_text }
#    end
#
#    hat.shuffle.sort[0]
    solutions.sort[0].cipher_text
  end

  def self.pick_solution_to_mutate(solutions)
    solutions.shuffle[0]
  end

  def self.pick_2_solution_cipher_texts_to_mate(solutions)
    min_score = solutions.map {|s| s.score}.min
    hat = []
    solutions.each do |s|
      entries_into_the_hat = s.score - min_score
      entries_into_the_hat.times { hat << s.cipher_text }
    end

    hat.shuffle.uniq[0..1]
  end
end

class SolutionGroup
  def initialize(population_size, original_cipher_text)
    @population_size = population_size
    @original_cipher_text = original_cipher_text
    @solutions = {}
    populate!
  end

  def cycle
    kill_off_the_weak!
    kill_off_the_weak!
    make_off_spring!
    increment_everyones_age!
    populate!
  end

  def make_off_spring!
    parent_cipher_textes = Raffle.pick_2_solution_cipher_texts_to_mate(@solutions.values)
    parent_1 = @solutions[parent_cipher_textes[0]]
    parent_2 = @solutions[parent_cipher_textes[1]]

    size = [parent_1.plain_text.size, parent_2.plain_text.size].min
    plain_text = (0..(size - 1)).map do |index|
      rand > 0.5 ? parent_1.plain_text[index] : parent_2.plain_text[index]
    end.join('')

    plain_text = Util.mutate(plain_text)

    generation = [parent_1.generation, parent_2.generation].max + 1

    solution = Solution.new(plain_text, @original_cipher_text, generation, 'Child')
    @solutions[solution.cipher_text] = solution
  end

#  def mutate_someone!
#    solution = Raffle.pick_solution_to_mutate(@solutions.values)
#    old_cipher_text = solution.cipher_text
#    @solutions.delete(old_cipher_text)
#    solution.mutate!
#    @solutions[solution.cipher_text] = solution
#  end

  def increment_everyones_age!
    @solutions.values.each {|s| s.increment_age! }
  end

  def kill_off_the_weak!
    cipher_text = Raffle.pick_solution_cipher_text_to_kill_off(@solutions.values)
    @solutions.delete(cipher_text)
  end

  def populate!
    while @solutions.keys.size < @population_size
      solution = Util.generate_random_solution(@original_cipher_text)
      @solutions[solution.cipher_text] = solution
    end
  end

  def mean_score
    @solutions.values.map {|s| s.score }.mean
  end

  def median_score
    @solutions.values.map {|s| s.score }.median
  end

  def highest_score
    @solutions.values.map {|s| s.score }.max
  end

  def population_size
    @solutions.keys.size
  end

  def to_s
    @solutions.values.sort.reverse[0..29].map {|s| s.to_s }.join("\n")
  end
end

original_cipher_text = ARGV[0]

population_size = 10

sg = SolutionGroup.new(population_size, original_cipher_text)

def print(sg, iteration)
  puts "*** Iteration #{iteration}"
  puts sg
  puts "Highest Score: #{sg.highest_score}"
  puts "   Mean Score: #{sg.mean_score}"
  puts " Median Score: #{sg.median_score}"
  puts "    Pop. Size: #{sg.population_size}"
  puts ''
end

print(sg, 0)

times_to_run = 10_000_000
(1..times_to_run).each do |iteration|
  sg.cycle
  if iteration % (times_to_run / 100) == 0
    print(sg, iteration)
  end
end

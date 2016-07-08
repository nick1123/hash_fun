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

  def self.mutation_rate
#    (rand(4999) + 1) * 2 # evens upto 9998
#    2 * (rand(5) + 1)
    2
  end

  def self.mutate(plain_text, mutation_rate)
    mutation_rate.times do
      position = rand(plain_text.size)
      char = plain_text[position]
      plain_text[position] = (char == '1' ? '0' : '1')
    end
    plain_text
  end
end

class Solution
  include Comparable

  attr_reader :cipher_text, :score, :age, :plain_text, :generation

  MUTANT = 'Mutant'

  def initialize(plain_text, original_cipher_text, generation, classification, mutation_rate=nil)
    @plain_text     = plain_text
    @original_cipher_text  = original_cipher_text
    @cipher_text           = Util.cipher_text_it(plain_text.to_s)
    @generation     = generation
    @classification = classification
    @mutation_rate = mutation_rate
    @age            = 0
    compute_score
  end

  def <=>(anOther)
    @score <=> anOther.score
  end

  def increment_age!
    @age += 1
  end

  def mutant_clone
    mutation_rate = Util.mutation_rate

    Solution.new(
      Util.mutate(@plain_text.clone, mutation_rate),
      @original_cipher_text,
      @generation + 1,
      MUTANT,
      mutation_rate,
    )
  end

  def to_s
    [
      "Score: #{@score}",
      "Match %: #{(100.0 * @score / 256).round(1)}",
      "Gen: #{@generation}",
      "Age: #{@age}  ",
      "Class: #{@classification}",
      mutation_rate_to_s,
      "Plain: #{@plain_text[0..12]}",
      "cipher_text: #{@cipher_text[0..12]}"
    ].join("\t")
  end

  private

  def mutation_rate_to_s
    if @classification == MUTANT
      "Mut Rate: #{@mutation_rate}"
    else
      "\t"
    end
  end

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
#    solutions.shuffle[0]
    solutions.sort[-1]
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
    populate!(true)
  end

  def cycle
    kill_off_the_weak!
    populate!
    increment_everyones_age!
  end

  def create_offspring
    parent_cipher_textes = Raffle.pick_2_solution_cipher_texts_to_mate(@solutions.values)
    parent_1 = @solutions[parent_cipher_textes[0]]
    parent_2 = @solutions[parent_cipher_textes[1]]

    size = [parent_1.plain_text.size, parent_2.plain_text.size].min
    plain_text = (0..(size - 1)).map do |index|
      rand > 0.5 ? parent_1.plain_text[index] : parent_2.plain_text[index]
    end.join('')

#    plain_text = Util.mutate(plain_text)

    generation = [parent_1.generation, parent_2.generation].max + 1

    Solution.new(plain_text, @original_cipher_text, generation, 'Child')
  end

  def create_mutant_clone
    solution = Raffle.pick_solution_to_mutate(@solutions.values)
    solution.mutant_clone
  end

  def increment_everyones_age!
    @solutions.values.each {|s| s.increment_age! }
  end

  def kill_off_the_weak!
    cipher_text = Raffle.pick_solution_cipher_text_to_kill_off(@solutions.values)
    puts "kill"
    puts @solutions[cipher_text]
    puts ''
    @solutions.delete(cipher_text)
  end

  def populate!(only_random=false)
    while @solutions.keys.size < @population_size
      strategy = [
        :add_mutant,
     #   :add_offspring,
     #   :add_random
      ].shuffle[0]

      strategy = :add_random if only_random
      new_solution = nil
      if strategy == :add_random
        new_solution = Util.generate_random_solution(@original_cipher_text)
      elsif strategy == :add_mutant
        new_solution = create_mutant_clone
      elsif strategy == :add_offspring
        new_solution = create_offspring
      else
        raise "Unknown strategy!"
      end

      @solutions[new_solution.cipher_text] = new_solution
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

times_to_run = 1_000
(1..times_to_run).each do |iteration|
  sg.cycle
  if iteration % (times_to_run / 100) == 0
    print(sg, iteration)
  end
end

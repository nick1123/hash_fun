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
  def self.hash_it(plain_text)
  	Digest::SHA256.hexdigest(plain_text)
  end

  def self.hash_similarity_score(hash1, hash2)
    binary1 = hex_to_binary(hash1)
    binary2 = hex_to_binary(hash2)

    (0..255).to_a.inject(0) do |sum, index|
      binary1[index] == binary2[index] ? sum + 1 : sum
    end
  end

  def self.hex_to_binary(num)
    num.hex.to_s(2).rjust(num.size*4, '0')
  end

  def self.generate_random_solution(original_hash)
    Solution.new(generate_plain_text, original_hash, 1, 'Random')
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

  attr_reader :hash, :score, :age

  def initialize(plain_text, original_hash, generation, classification)
    @plain_text     = plain_text
    @original_hash  = original_hash
    @hash           = Util.hash_it(plain_text.to_s)
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

  def mutate!
    @plain_text = Util.mutate(@plain_text.clone)
    @generation += 1
    @classification = 'Mutant'
  end

  def to_s
    [
      "Score: #{@score}",
      "Match %: #{100 * @score / 256}",
      "Gen: #{@generation}  ",
      "Age: #{@age}  ",
      "Class: #{@classification}",
      "Plain: #{@plain_text[0..12]}",
      "Hash: #{@hash[0..12]}"
    ].join("\t")
  end

  private

  def compute_score
    @score = Util.hash_similarity_score(@hash, @original_hash)
  end
end

module Raffle
  def self.pick_solution_hash_to_kill_off(solutions)
    max_score = solutions.map {|s| s.score}.max
    hat = []
    solutions.each do |s|
      entries_into_the_hat = max_score - s.score
      entries_into_the_hat.times { hat << s.hash }
    end

    hat.shuffle.sort[0]
  end

  def self.pick_solution_to_mutate(solutions)
    solutions.shuffle[0]
  end
end

class SolutionGroup
  def initialize(population_size, original_hash)
    @population_size = population_size
    @original_hash = original_hash
    @solutions = {}
    populate!
  end

  def cycle
    mutate_someone!
    kill_off_the_weak!
    increment_everyones_age!
    populate!
  end

  def mutate_someone!
    Raffle.pick_solution_to_mutate(@solutions.values).mutate!
  end

  def increment_everyones_age!
    @solutions.values.each {|s| s.increment_age! }
  end

  def kill_off_the_weak!
    hash = Raffle.pick_solution_hash_to_kill_off(@solutions.values)
    @solutions.delete(hash)
  end

  def populate!
    while @solutions.keys.size < @population_size
      solution = Util.generate_random_solution(@original_hash)
      @solutions[solution.hash] = solution
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

  def to_s
    @solutions.values.sort.reverse[0..9].map {|s| s.to_s }.join("\n")
  end
end

original_hash = ARGV[0]

population_size = 100

sg = SolutionGroup.new(population_size, original_hash)

def print(sg, iteration)
  puts "*** Iteration #{iteration}"
  puts sg
  puts "Highest Score: #{sg.highest_score}"
  puts "  Mean Score:  #{sg.mean_score}"
  puts "Median Score:  #{sg.median_score}"
  puts ''
end

print(sg, 0)

times_to_run = 1_00_000
(1..times_to_run).each do |iteration|
  sg.cycle
  if iteration % (times_to_run / 100) == 0
    print(sg, iteration)
  end
end

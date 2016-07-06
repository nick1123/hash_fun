require 'digest'

# # happyhappyhappyhappyhappyhappyhappyhappyhappyhappy
# plain_text = "happy" * 10

# # 8667cf2942a759f257177010b094539dd6084a8f0147f01fa3284cc3310721c8
# cipher_text = Digest::SHA256.hexdigest(plain_text)


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
    Solution.new(rand.to_s, original_hash)
  end
end

class Solution
  include Comparable

  attr_reader :hash, :score, :age

  def initialize(plain_text, original_hash)
    @plain_text = plain_text
    @hash = Util.hash_it(plain_text.to_s)
    @score = Util.hash_similarity_score(@hash, original_hash)
    @age = 1
  end

  def <=>(anOther)
    @score <=> anOther.score
  end

  def increment_age
    @age += 1
  end

  def to_s
    [
      "Score: #{@score}",
      "Age: #{@age}",
      @hash
    ].join("\t")
  end
end

module Raffle
  def self.pick_solution_hash_to_kill_off(solutions)
    max_score = 256
    hat = []
    solutions.each do |s|
      entries_into_the_hat = 256 - s.score
      entries_into_the_hat.times { hat << s.hash }
    end

    hat.shuffle.sort[0]
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
    hash = Raffle.pick_solution_hash_to_kill_off(@solutions.values)
    @solutions.delete(hash)
    @solutions.values.each {|s| s.increment_age }
    populate!
  end

  def populate!
    while @solutions.keys.size < @population_size
      solution = Util.generate_random_solution(@original_hash)
      @solutions[solution.hash] = solution
    end
  end

  def to_s
    @solutions.values.sort.reverse.map {|s| s.to_s }.join("\n")
  end
end 

original_hash = ARGV[0]

population_size = 40

sg = SolutionGroup.new(population_size, original_hash)

puts sg

10.times do
  sg.cycle
  puts sg
  puts ''
end

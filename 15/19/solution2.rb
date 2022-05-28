
require 'sqlite3'

Rule = Struct.new(:from, :to)
State = Struct.new(:molecule, :rules)
Input = Struct.new(:text)

class Input
  def state
    State.new(molecule, rules)
  end

  def lines
    @lines ||= text.strip.lines
  end

  def rules
    lines.take(lines.length-1).map do |line|
      from, to = line.strip.split(' => ').map(&:strip)
      Rule.new(to, from) # reverse to and from so that they are semantically meaningful below
    # end
    end.sort_by(&:from)
  end

  def molecule
    lines.last.strip
  end
end

class Memo
  def initialize
    @d = SQLite3::Database.new '15/19/memo.db'
    @d.execute('create table if not exists memo (string text, depth int);')
  end

  def save(molecule, depth)
    @d.execute('insert into memo values (?, ?)', molecule, depth)
    depth
  end

  def query(molecule)
    value = @d.execute('select depth from memo where string = ?', molecule)
    value.first.first.to_i if value && value.first && value.first.first
  end
end

MEMO = Memo.new
LARGE = 500
# LARGE = 195 # found after running a few times
$MIN_COUNT = LARGE
$MAX_DEPTH = 0
$MIN_LENGTH = LARGE

class State
  def min_replacements
    mrep(molecule, rules, 0)
  end
  
  def mrep(molecule, rules, count)
    if MEMO.query(molecule)
      return MEMO.query(molecule)
    end

    if count > $MAX_DEPTH
      puts $MAX_DEPTH = count
    end

    if molecule.length < $MIN_LENGTH
      puts "#{count} #{molecule}"
      $MIN_LENGTH = molecule.length
    end

    if molecule == 'e'
      puts "Found one! count=#{count}"
      $MIN_COUNT = count if count < $MIN_COUNT
      return [count]
    elsif count > $MIN_COUNT
      puts "Skipping count=#{count}"
      return [LARGE]
    end

    result = rules.flat_map do |rule|
      all_indices(molecule, rule.from).flat_map do |index|
        mol = molecule[0...index] + rule.to + molecule[index+rule.from.length..-1]
        mrep(mol, rules, count+1)
      end
    end.filter{ |i| i }.min

    MEMO.save(molecule, result || LARGE)
  end

  def all_indices(molecule, substring)
    indices = []
    index = 0
    while index = molecule.index(substring, index)
      indices << index
      index += 1
    end
    indices
  end
end


# @input = %Q(
#   H => HO
#   H => OH
#   O => HH
#   e => O
#   e => H
#   HOHOHO
# )

@input = %Q(
  Al => ThF
  Al => ThRnFAr
  B => BCa
  B => TiB
  B => TiRnFAr
  Ca => CaCa
  Ca => PB
  Ca => PRnFAr
  Ca => SiRnFYFAr
  Ca => SiRnMgAr
  Ca => SiTh
  F => CaF
  F => PMg
  F => SiAl
  H => CRnAlAr
  H => CRnFYFYFAr
  H => CRnFYMgAr
  H => CRnMgYFAr
  H => HCa
  H => NRnFYFAr
  H => NRnMgAr
  H => NTh
  H => OB
  H => ORnFAr
  Mg => BF
  Mg => TiMg
  N => CRnFAr
  N => HSi
  O => CRnFYFAr
  O => CRnMgAr
  O => HP
  O => NRnFAr
  O => OTi
  P => CaP
  P => PTi
  P => SiRnFAr
  Si => CaSi
  Th => ThCa
  Ti => BP
  Ti => TiTi
  e => HF
  e => NAl
  e => OMg
  CRnCaSiRnBSiRnFArTiBPTiTiBFArPBCaSiThSiRnTiBPBPMgArCaSiRnTiMgArCaSiThCaSiRnFArRnSiRnFArTiTiBFArCaCaSiRnSiThCaCaSiRnMgArFYSiRnFYCaFArSiThCaSiThPBPTiMgArCaPRnSiAlArPBCaCaSiRnFYSiThCaRnFArArCaCaSiRnPBSiRnFArMgYCaCaCaCaSiThCaCaSiAlArCaCaSiRnPBSiAlArBCaCaCaCaSiThCaPBSiThPBPBCaSiRnFYFArSiThCaSiRnFArBCaCaSiRnFYFArSiThCaPBSiThCaSiRnPMgArRnFArPTiBCaPRnFArCaCaCaCaSiRnCaCaSiRnFYFArFArBCaSiThFArThSiThSiRnTiRnPMgArFArCaSiThCaPBCaSiRnBFArCaCaPRnCaCaPMgArSiRnFYFArCaSiThRnPBPMgAr
)

# To go back to part one put this as the last line of the input rather than 'e'
@target = "e"

# part 1
# Input.new(@input).state.next.count

# part 2
@state = Input.new(@input).state
@times = 0

# This is taking forever... I set it to run in tmux in the cloud because
# I've already spent a lot of time on it
puts @state.min_replacements

# Another update---taking unbelievable long
# I even switched to a DFS to see if that would help...
# Maybe adding memoing? if that doesn't work then I'm going to just binary search guess

# <204
# 153 <-- turned out not to be necessary

# This is terrible but it gets the right answer, sort of...
# It saves the answers in a memo, which I guess you could use a
# database in order to scale, but it also shuffles so sometimes
# it finds *a* right answer before getting an OOM exception.
#
# If you don't want to just get lucky, I guess using sqlite you
# could memo on disk and then run indefinitely
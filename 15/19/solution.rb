
Rule = Struct.new(:from, :to)
State = Struct.new(:molecules, :rules)
Input = Struct.new(:text)

class Input
  def state
    State.new(Set.new([molecules]), rules)
  end

  def lines
    @lines ||= text.strip.lines
  end

  def rules
    lines.take(lines.length-1).map do |line|
      from, to = line.strip.split(' => ').map(&:strip)
      Rule.new(from, to)
    end
  end

  def molecules
    lines.last.strip
  end
end

class State
  def next
    State.new(
      molecules.flat_map do |molecule|
        rules.flat_map do |rule|
          all_indices(molecule, rule.from).flat_map do |index|
            molecule[0...index] + rule.to + molecule[index+rule.from.length..-1]
          end
        end
      end.to_set,
      rules
    )
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

# part 1
# Input.new(@input).state.next.molecules.size

# part 2
# moved to another file to implement backwards
# @state = Input.new(@input).state
# @times = 0

# while !@state.molecules.include?(@target)
#   @state = @state.next
#   @times += 1
# end
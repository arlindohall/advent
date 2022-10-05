$debug = true

class Nanofactory
  Ingredient = Struct.new(:amount, :name)
  Combination = Struct.new(:inputs, :output)

  class Ingredient
    def inspect
      "#{amount} #{name}"
    end
  end

  def initialize(recipes)
    @recipes = recipes
  end

  def fuel
    build("FUEL", 1)
  end

  def possible_fuel
    small = goal/dup.fuel
    large = goal
    mid = (small + large) / 2
    binary_search(small, mid, large)
  end

  def binary_search(small, mid, large)
    puts "Searching [#{small}, #{mid}, #{large}]"
    return small if small == large

    small_ore = dup.build("FUEL", small)
    mid_ore = dup.build("FUEL", mid)
    large_ore = dup.build("FUEL", large)

    # If the window is outside of the goal
    raise "Out of bounds, low" if large_ore < goal
    raise "Out of bounds, high" if small_ore > goal

    # If we got lucky and used exactly 1 trillion ore
    return small if small_ore == goal
    return large if large_ore == goal
    return mid if mid_ore == goal

    # If we're within 1 of the goal, i.e. we can't divide any more
    # the large is still outside the window
    return small if mid == small || mid == large

    if mid_ore > goal
      binary_search(small, (small + mid) / 2, mid)
    elsif mid_ore < goal
      binary_search(mid, (mid + large) / 2, large)
    end
  end

  def goal
    1_000_000_000_000
  end

  def build(name, amount)
    return if name == "ORE"
    raise "Don't know how to make #{name}" unless @recipes[name]

    # how many times to run the production of `name`
    needed = needed(name, amount)
    factor = needed % unit_of(name) == 0 ?
      needed / unit_of(name) :
      needed / unit_of(name) + 1

    source(name, factor)
    produce(name, factor)
  end

  def needed(name, amount)
    leftovers[name] ||= 0
    return 0 if amount < leftovers[name]

    amount - leftovers[name]
  end

  def unit_of(name)
    @recipes[name].output.amount
  end

  def source(name, factor)
    return if factor == 0
    @recipes[name].inputs.each do |input|
      build(input.name, factor * input.amount)

      amount = factor * input.amount
      name = input.name
      consume(name, amount)
    end
  end


  def consume(name, amount)
    return use_ore(amount) if name == "ORE"

    leftovers[name] ||= 0

    raise "Don't have enough #{name} (#{leftovers[name]}/#{amount})" unless leftovers[name] >= amount
    leftovers[name] -= amount
  end

  def produce(name, factor)
    return if factor == 0

    amount = factor * unit_of(name)
    debug(name, amount)

    leftovers[name] ||= 0
    leftovers[name] += factor * unit_of(name)
    @ore_used
  end

  def have_enough(name, amount)
    leftovers[name] ||= 0
    leftovers[name] >= amount
  end

  def leftovers
    @leftovers ||= {}
  end

  def use_ore(amount)
    @ore_used ||= 0
    @ore_used += amount
  end

  def debug(name, amount)
    return unless $debug

    puts "Making #{amount} #{name}, have #{leftovers[name]}"
  end

  class << self
    def parse(text)
      new(
        text.strip
          .split("\n")
          .map { |line| line.split(" => ") }
          .map { |inputs, output| [inputs.split(", "), output] }
          .map { |inputs, output| parse_combination(inputs, output) }
          .to_h
      )
    end

    def parse_combination(inputs, output)
      output = Ingredient.new(*output.split(" "))
      output.amount = output.amount.to_i

      inputs = inputs.map { |input| Ingredient.new(*input.split(" ")) }
      inputs.each { |ingredient| ingredient.amount = ingredient.amount.to_i }

      [
        output.name,
        Combination.new(inputs, output),
      ]
    end
  end
end

def test
  [
    [@example1, 31],
    [@example2, 165],
    [@example3, 13312],
    [@example4, 180697],
    [@example5, 2210736],
  ]
  .map { |ex, exp| [Nanofactory.parse(ex).fuel, exp] }
  .each { |val, exp| raise "Part 1: Expected #{exp} got #{val}" unless val == exp }

  [
    [@example3, 82892753],
    [@example4, 5586022],
    [@example5, 460664],
  ]
  .map { |ex, exp| [Nanofactory.parse(ex).possible_fuel, exp] }
  .each { |val, exp| raise "Part 2: Expected #{exp} got #{val}" unless val == exp }

  :success
end

def solve
  [
    Nanofactory.parse(@input).fuel,
    Nanofactory.parse(@input).possible_fuel,
  ]
end

@example1 = <<-fuel
10 ORE => 10 A
1 ORE => 1 B
7 A, 1 B => 1 C
7 A, 1 C => 1 D
7 A, 1 D => 1 E
7 A, 1 E => 1 FUEL
fuel

@example2 = <<-fuel
9 ORE => 2 A
8 ORE => 3 B
7 ORE => 5 C
3 A, 4 B => 1 AB
5 B, 7 C => 1 BC
4 C, 1 A => 1 CA
2 AB, 3 BC, 4 CA => 1 FUEL
fuel

@example3 = <<-fuel
157 ORE => 5 NZVS
165 ORE => 6 DCFZ
44 XJWVT, 5 KHKGT, 1 QDVJ, 29 NZVS, 9 GPVTF, 48 HKGWZ => 1 FUEL
12 HKGWZ, 1 GPVTF, 8 PSHF => 9 QDVJ
179 ORE => 7 PSHF
177 ORE => 5 HKGWZ
7 DCFZ, 7 PSHF => 2 XJWVT
165 ORE => 2 GPVTF
3 DCFZ, 7 NZVS, 5 HKGWZ, 10 PSHF => 8 KHKGT
fuel

@example4 = <<-fuel
2 VPVL, 7 FWMGM, 2 CXFTF, 11 MNCFX => 1 STKFG
17 NVRVD, 3 JNWZP => 8 VPVL
53 STKFG, 6 MNCFX, 46 VJHF, 81 HVMC, 68 CXFTF, 25 GNMV => 1 FUEL
22 VJHF, 37 MNCFX => 5 FWMGM
139 ORE => 4 NVRVD
144 ORE => 7 JNWZP
5 MNCFX, 7 RFSQX, 2 FWMGM, 2 VPVL, 19 CXFTF => 3 HVMC
5 VJHF, 7 MNCFX, 9 VPVL, 37 CXFTF => 6 GNMV
145 ORE => 6 MNCFX
1 NVRVD => 8 CXFTF
1 VJHF, 6 MNCFX => 4 RFSQX
176 ORE => 6 VJHF
fuel

@example5 = <<-fuel
171 ORE => 8 CNZTR
7 ZLQW, 3 BMBT, 9 XCVML, 26 XMNCP, 1 WPTQ, 2 MZWV, 1 RJRHP => 4 PLWSL
114 ORE => 4 BHXH
14 VRPVC => 6 BMBT
6 BHXH, 18 KTJDG, 12 WPTQ, 7 PLWSL, 31 FHTLT, 37 ZDVW => 1 FUEL
6 WPTQ, 2 BMBT, 8 ZLQW, 18 KTJDG, 1 XMNCP, 6 MZWV, 1 RJRHP => 6 FHTLT
15 XDBXC, 2 LTCX, 1 VRPVC => 6 ZLQW
13 WPTQ, 10 LTCX, 3 RJRHP, 14 XMNCP, 2 MZWV, 1 ZLQW => 1 ZDVW
5 BMBT => 4 WPTQ
189 ORE => 9 KTJDG
1 MZWV, 17 XDBXC, 3 XCVML => 2 XMNCP
12 VRPVC, 27 CNZTR => 2 XDBXC
15 KTJDG, 12 BHXH => 5 XCVML
3 BHXH, 2 VRPVC => 7 MZWV
121 ORE => 7 VRPVC
7 XCVML => 6 RJRHP
5 BHXH, 4 VRPVC => 5 LTCX
fuel

@input = <<-fuel
2 RWPCH => 9 PVTL
1 FHFH => 4 BLPJK
146 ORE => 5 VJNBT
8 KDFNZ, 1 ZJGH, 1 GSCG => 5 LKPQG
11 NWDZ, 2 WBQR, 1 VRQR => 2 BMJR
3 GSCG => 4 KQDVM
5 QVNKN, 6 RPWKC => 3 BCNV
10 QMBM, 4 RBXB, 2 VRQR => 1 JHXBM
15 RPWKC => 6 MGCQ
1 QWKRZ => 4 FHFH
10 RWPCH => 6 MZKG
11 JFKGV, 5 QVNKN, 1 CTVK => 4 VQDT
1 SXKT => 5 RPWKC
1 VQDT, 25 ZVMCB => 2 RBXB
6 LGLNV, 4 XSNKB => 3 WBQR
199 ORE => 2 SXKT
1 XSNKB, 6 CWBNX, 1 HPKB, 5 PVTL, 1 JNKH, 9 SXKT, 3 KQDVM => 3 ZKTX
7 FDSX => 6 WJDF
7 JLRM => 4 CWBNX
167 ORE => 5 PQZXH
13 JHXBM, 2 NWDZ, 4 RFLX, 12 VRQR, 10 FJRFG, 14 PVTL, 2 JLRM => 6 DGFG
12 HPKB, 3 WHVXC => 9 ZJGH
1 JLRM, 2 ZJGH, 2 QVNKN => 9 FJRFG
129 ORE => 7 KZFPJ
2 QMBM => 1 RWPCH
7 VJMWM => 4 JHDW
7 PQZXH, 7 SXKT => 9 BJVQM
1 VJMWM, 4 JHDW, 1 MQXF => 7 FDSX
1 RPWKC => 7 WHVXC
1 ZJGH => 1 ZVMCB
1 RWPCH => 3 MPKR
187 ORE => 8 VJMWM
15 CTVK => 5 GSCG
2 XSNKB, 15 ZVMCB, 3 KDFNZ => 2 RFLX
18 QVNKN => 8 XLFZJ
4 CWBNX => 8 ZSCX
2 ZJGH, 1 JLRM, 1 MGCQ => 9 NPRST
13 BJVQM, 2 BCNV => 2 QWKRZ
2 QWKRZ, 2 BLPJK, 5 XSNKB => 2 VRQR
13 HPKB, 3 VQDT => 9 JLRM
2 SXKT, 1 VJNBT, 5 VLWQB => 6 CTVK
2 MPKR, 2 LMNCH, 24 VRQR => 8 DZFNW
2 VQDT => 1 KDFNZ
1 CTVK, 6 FDSX => 6 QVNKN
3 CTVK, 1 QVNKN => 4 HPKB
3 NPRST, 1 KGSDJ, 1 CTVK => 2 QMBM
4 KZFPJ, 1 PQZXH => 5 VLWQB
2 VQDT => 7 KGSDJ
3 MPKR => 2 JNKH
1 KQDVM => 5 XQBS
3 ZKGMX, 1 XQBS, 11 MZKG, 11 NPRST, 1 DZFNW, 5 VQDT, 2 FHFH => 6 JQNF
2 FJRFG, 17 BMJR, 3 BJVQM, 55 JQNF, 8 DGFG, 13 ZJGH, 29 ZKTX => 1 FUEL
27 KZFPJ, 5 VJNBT => 5 MQXF
11 FDSX, 1 WHVXC, 1 WJDF => 4 ZKGMX
1 ZVMCB => 4 NWDZ
1 XLFZJ => 6 LGLNV
13 ZSCX, 4 XLFZJ => 8 LMNCH
1 RPWKC, 1 FDSX, 2 BJVQM => 8 JFKGV
1 WJDF, 1 LKPQG => 4 XSNKB
fuel
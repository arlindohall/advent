# $_debug = false

def solve
  [
    FoodList.new(read_input).appearances,
    FoodList.new(read_input).canonical_list
  ]
end

class FoodList < Struct.new(:input)
  def recipes
    @recipes ||= input.split("\n").map { |line| Recipe.new(line) }
  end

  def appearances
    non_allergens.map { |nal| recipes.map { |rec| rec.count(nal) }.sum }.sum
  end

  def canonical_list
    allergen_mapping.sort_by(&:first).map(&:second).join(",")
  end

  private

  def allergen_mapping
    cand = candidates
    until cand.values.all? { |l| l.size == 1 }
      set = settled(cand)
      cand = cand.transform_values { |list| remove_settled(list, set) }
      _debug(set:, cand:)
    end
    cand.transform_values(&:only!)
  end

  def settled(candidates)
    candidates.values.filter { |l| l.size == 1 }.map(&:only!)
  end

  def remove_settled(list, settled)
    return list if list.size == 1
    list.reject { |item| settled.include?(item) }
  end

  def non_allergens
    all_ingredients - candidates.values.flatten.to_set
  end

  def candidates
    all_allergens.to_a.hash_by_value do |allergen|
      recipes_containing(allergen).map(&:ingredients).reduce(&:&)
    end
  end

  def recipes_containing(allergen)
    recipes.filter { |rcp| rcp.allergens.include?(allergen) }
  end

  def all_ingredients
    recipes.flat_map(&:ingredients).to_set
  end

  def all_allergens
    recipes.flat_map(&:allergens).to_set
  end
end

class Recipe < Struct.new(:text)
  def allergens
    @allergens ||= text.split("(contains ").second.split(")").first.split(", ")
  end

  def ingredients
    @ingredients ||= text.split(" (").first.split
  end

  def count(ingredient)
    ingredients.count(ingredient)
  end
end

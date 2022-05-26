
IngredientsList = Struct.new(:text)
class IngredientsList
  def ingredients
    @ingredients ||= text.strip.lines.map do |line|
      name, rest = line.split(': capacity ')
      capacity, rest = rest.split(', durability ')
      durability, rest = rest.split(', flavor ')
      flavor, rest = rest.split(', texture ')
      texture, rest = rest.split(', calories ')
      calories = rest

      Ingredient.new(
        name, capacity.to_i, durability.to_i, flavor.to_i, texture.to_i, calories.to_i
      )
    end
  end

  def combinations capacity, ingredients = self.ingredients
    # return [] if capacity == 0 || ingredients.empty?

    head = ingredients.first
    tail = ingredients.drop(1)

    return [Recipe.new(RecipeEntry.new(capacity, head))] if tail.empty?

    0.upto(capacity).flat_map do |amount|
      combinations(capacity - amount, tail).map do |combo|
        Recipe.new(RecipeEntry.new(amount, head)) + combo
      end
    end
  end
end

Ingredient = Struct.new(:name, :capacity, :durability, :flavor, :texture, :calories)

RecipeEntry = Struct.new(:amount, :ingredient)

Recipe = Struct.new(:entries)
class Recipe
  def +(recipe)
    if Array === entries && Array === recipe.entries
      Recipe.new(self.entries + recipe.entries)
    elsif Array === entries
      Recipe.new(self.entries + [recipe.entries])
    elsif Array === recipe.entries
      Recipe.new([self.entries] + recipe.entries)
    else
      Recipe.new([self.entries, recipe.entries])
    end
  end

  def calorie_count
    entries.map{|entry| entry.ingredient.calories * entry.amount}.sum
  end

  def score
    # uncomment for part 2
    # return 0 unless calorie_count == 500
    [
      entries.map{|entry| entry.ingredient.capacity * entry.amount}.sum,
      entries.map{|entry| entry.ingredient.durability * entry.amount}.sum,
      entries.map{|entry| entry.ingredient.flavor * entry.amount}.sum,
      entries.map{|entry| entry.ingredient.texture * entry.amount}.sum,
    ].map do |partial_score|
      partial_score > 0 ? partial_score : 0
    end.reduce(&:*)
  end
end

# @input = %Q(
# Butterscotch: capacity -1, durability -2, flavor 6, texture 3, calories 8
# Cinnamon: capacity 2, durability 3, flavor -2, texture -1, calories 3
# )

@input = %Q(
Sprinkles: capacity 5, durability -1, flavor 0, texture 0, calories 5
PeanutButter: capacity -1, durability 3, flavor 0, texture 0, calories 1
Frosting: capacity 0, durability -1, flavor 4, texture 0, calories 6
Sugar: capacity -1, durability 0, flavor 0, texture 2, calories 8
)
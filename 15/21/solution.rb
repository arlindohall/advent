
Fighter = Struct.new :damage, :armor, :hp
Attack = Struct.new :attacker, :defender
Store = Struct.new :weapons, :armor, :rings
Item = Struct.new :name, :cost, :damage, :armor
Configuration = Struct.new :player, :boss, :items

class Attack
  def attack_score
    [attacker.damage - defender.armor, 1].max
  end
end

class Configuration
  def equip_player
    self.player = Fighter.new(
      player.damage + damage_upgrade,
      player.armor + armor_upgrade,
      player.hp
    )
  end

  def damage_upgrade
    items.map(&:damage).reject(&:nil?).sum
  end

  def armor_upgrade
    items.map(&:armor).reject(&:nil?).sum
  end

  def player_attack
    Attack.new(player, boss).attack_score
  end

  def boss_attack
    Attack.new(boss, player).attack_score
  end

  def simulate
    @rounds = 0
    equip_player
    loop do
      boss.hp -= player_attack
      return :player if boss.hp <= 0
      # puts "Round #{@rounds += 1}: attack: #{player_attack} boss hp: #{boss}"
      player.hp -= boss_attack
      return :boss if player.hp <= 0
      # puts "Round #{@rounds += 1}: attack: #{player_attack} player hp: #{player}"
    end
  end
end

$STORE = Store.new(
# Weapons:    Cost  Damage  Armor
# Dagger        8     4       0
# Shortsword   10     5       0
# Warhammer    25     6       0
# Longsword    40     7       0
# Greataxe     74     8       0
  [
    Item.new('Dagger', 8, 4, 0),
    Item.new('Shortsword', 10, 5, 0),
    Item.new('Warhammer', 25, 6, 0),
    Item.new('Longsword', 40, 7, 0),
    Item.new('Greataxe', 74, 8, 0),
  ],

# Armor:      Cost  Damage  Armor
# Leather      13     0       1
# Chainmail    31     0       2
# Splintmail   53     0       3
# Bandedmail   75     0       4
# Platemail   102     0       5
  [
    Item.new('Leather', 13, 0, 1),
    Item.new('Chainmail', 31, 0, 2),
    Item.new('Splintmail', 53, 0, 3),
    Item.new('Bandedmail', 75, 0, 4),
    Item.new('Platemail', 102, 0, 5),
    # Allowed not to have armor
    Item.new('None', 0, 0, 0),
  ],

# Rings:      Cost  Damage  Armor
# Damage +1    25     1       0
# Damage +2    50     2       0
# Damage +3   100     3       0
# Defense +1   20     0       1
# Defense +2   40     0       2
# Defense +3   80     0       3
  [
    Item.new('Damage +1', 25, 1, 0),
    Item.new('Damage +2', 50, 2, 0),
    Item.new('Damage +3', 100, 3, 0),
    Item.new('Defense +1', 20, 0, 1),
    Item.new('Defense +2', 40, 0, 2),
    Item.new('Defense +3', 80, 0, 3),
    Item.new('None', 0, 0, 0),
    Item.new('None', 0, 0, 0),
  ],
)

# example
# $BOSS = -> {
#   Fighter.new(
#     7, 2, 12
#   )
# }

# puzzle input
# Hit Points: 104
# Damage: 8
# Armor: 1
$BOSS = -> {
  Fighter.new(
    8, 1, 104
  )
}

$SAMPLE_PLAYER = Fighter.new(
  5, 5, 8
)

def sample_configuration
  Configuration.new($SAMPLE_PLAYER, $BOSS[], [])
end

def combinations
  $STORE.weapons.flat_map do |weapon|
    $STORE.armor.flat_map do |armor|
      $STORE.rings.combination(2).map do |rings|
        Configuration.new(
          Fighter.new(0, 0, 100),
          $BOSS[],
          [weapon, armor, *rings]
        )
      end
    end
  end
end

def best_combo
  combinations
    .filter{ |config| config.simulate == :player }
    .min_by{ |config| config.items.map(&:cost).sum }
end

def worst_combo
  combinations
    .filter{ |config| config.simulate == :boss }
    .max_by{ |config| config.items.map(&:cost).sum }
end
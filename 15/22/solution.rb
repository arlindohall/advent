
GameTree = Struct.new(:player, :boss, :all_games)
Game = Struct.new(:wizard, :boss, :turns)
Wizard = Struct.new(:mana, :hp)
Boss = Struct.new(:damage, :hp)

Spell = Struct.new(:name, :mana, :damage, :heal, :effects)
Effect = Struct.new(:timer, :armor, :damage, :mana)

Turn = Struct.new(
  :active_player,
  :player_state,
  :boss_state,
  :effects,
  :spell,
  :damage,
  :mana,
)

SpellBook = [
  Spell.new("Magic Missile", 53, 4, 0, nil),
  Spell.new("Drain", 73, 2, 2, nil),
  Spell.new("Shield", 113, 0, 0, Effect.new(6, 7, 0, 0)),
  Spell.new("Poison", 173, 3, 0, Effect.new(6, 0, 3, 0)),
  Spell.new("Recharge", 229, 0, 0, Effect.new(5, 0, 0, 101))
]

def SpellBook.find(name)
  SpellBook.filter{ |spell| spell.name == name }.first or raise "No spell named #{name}"
end

class Game
  def next_turn(spell = nil)
    if active_player == :player
      turn(SpellBook.find(spell))
    elsif active_player == :boss
      turn
    else
      throw "Invalid active player: #{active_player}"
    end
  end

  def turn(spell = nil)
    Game.new(
      wizard,
      boss,
      turns.clone.push(
        Turn.new(
            active_player,
            player.clone,
            opponent.clone,
            next_effects(spell),
            spell,
            effects_mana,
            effects_damage,
          )
        ),
    )
  end

  def player
    last_turn ? last_turn.player_state : wizard
  end

  def opponent
    last_turn ? last_turn.boss_state : boss
  end

  def effects_damage
    return 0 if last_turn.nil?
    last_turn.damage_effects
  end

  def effects_mana
    return 0 if last_turn.nil? || last_turn.mana_effects.nil?
    last_turn.mana_effects
  end

  def armor_effects
    return 0 if last_turn.nil?
    last_turn.armor_effects
  end

  def mana_tracker
    last_turn ? last_turn.player_state.mana : wizard.mana
  end

  def next_mana(spell = nil)
    mana_tracker +
      effects_mana -
      (spell ? spell.mana : 0)
  end

  def next_effects(spell = nil)
    if last_turn.nil?
      spell && spell.effects ? [spell.effects] : []
    else
      last_turn.next_effects(spell)
    end
  end

  def active_player
    if last_turn.nil?
      :player
    else
      last_turn.next_player
    end
  end

  def last_turn
    turns.last
  end

  def show
    turns.map do |turn|
      turn.show
    end.join("\n\n")
  end
end

class Turn
  def next_effects(spell)
    if spell && spell.effects
      updated_effects.push(spell.effects)
    else
      updated_effects
    end
  end

  def updated_effects
    @updated_effects ||= effects.clone.map do |effect|
      effect.clone
    end.map do |effect|
      effect.tap{ |e| e.timer -= 1 }
    end.filter do |effect|
      effect.timer >= 0
    end
  end

  def mana_effects
    effects.map(&:mana).reject(&:nil?).sum
  end

  def damage_effects
    effects.map(&:damage).reject(&:nil?).sum
  end

  def armor_effects
    effects.map(&:armor).reject(&:nil?).sum
  end

  def next_player
    active_player == :player ? :boss : :player
  end

  def show
    <<~EOS
    -- #{active_player == :player ? 'Player' : 'Boss'} turn --
    - Player has #{player_state.hp} hp, #{armor_effects}, #{player_state.mana} mana
    - Boss has #{boss_state.hp} hp
    EOS
    .strip + "\n" +
    effects.map do |effect|
      effect.to_s
    end.join("\n")
  end
end

class GameTree
  def player_1
    Wizard.new(250, 10)
  end

  def boss_1
    Boss.new(8, 13)
  end

  def boss_2
    Boss.new(8, 14)
  end

  def example_game_1
    Game.new(player_1, boss_1, [])
      .next_turn('Poison')
      .next_turn
      .next_turn('Magic Missile')
      .next_turn
  end

  def example_game_2
    Game.new(player_1, boss_2, [])
  end
end

@game_tree = GameTree.new
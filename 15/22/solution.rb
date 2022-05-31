
Game = Struct.new(:wizard, :boss, :turns)

Wizard = Struct.new(:hp, :mana)
Boss = Struct.new(:hp, :damage)

PlayerState = Struct.new(:hp, :mana, :armor)
OpponentState = Struct.new(:hp, :damage)
Turn = Struct.new(:attacker, :player_state, :opponent_state, :action, :effects)

Spell = Struct.new(:name, :cost, :damage, :heal, :effect)
Effect = Struct.new(:timer, :armor, :damage, :mana)


class Spell
  def player_damage
    0
  end

  def boss_damage
    damage
  end

  def show
    "Player casts #{name}"
  end
end

class Attack
  def initialize damage
    @damage = damage
  end

  def player_damage
    @damage
  end

  def boss_damage
    0
  end

  def show
    "Boss attacks for #{@damage}"
  end
end

class SpellBook
  def book
    @spells ||= [
      Spell.new("Magic Missile", 53, 4, 0, nil),
      Spell.new("Drain", 73, 2, 2, nil),
      Spell.new("Shield", 113, 0, 0, Effect.new(6, 7, 0, 0)),
      Spell.new("Poison", 173, 3, 0, Effect.new(6, 0, 3, 0)),
      Spell.new("Recharge", 229, 0, 0, Effect.new(5, 0, 0, 101))
    ].map do |spell|
      [spell.name, spell]
    end.to_h
  end

  def find(name)
    book[name] or raise "No spell named #{name}"
  end
end

class Turn
  def player_dead?
    next_player_state.hp <= 0
  end

  def boss_dead?
    next_boss_state.hp <= 0
  end

  def next_boss_state
    OpponentState.new(
      opponent_state.hp - action.boss_damage - effects.map(&:damage).reject(&:nil?).sum,
      opponent_state.damage
    )
  end

  def next_player_state
    PlayerState.new(
      player_state.hp + action.player_damage,
      player_state.mana + effects.map(&:mana).sum,
      player_state.armor + effects.map(&:armor).sum,
    )
  end

  def show
    "#{header}#{effects.map(&:to_s).join("\n")}#{player_dead? ? "\nBoss wins" : ''}#{boss_dead? ? "\nPlayer wins" : ''}"
  end

  def header
    <<~EOS
    -- #{attacker == :player ? 'Player' : 'Boss'} turn --
    - Player has #{player_state.hp} hit points, #{player_state.armor} armor, #{player_state.mana} mana
    - Boss has #{opponent_state.hp} hit points
    #{action.show}
    EOS
  end
end

class Game
  def next_turn(spell = nil)
    if [:lose, :win].include? state
      self
    else
      if spell
        spell = SpellBook.new.find(spell)
      end
      Game.new(
        wizard,
        boss,
        turns.clone.push(Turn.new(
          state,
          player_state,
          opponent_state,
          spell ? spell : opponent_attack,
          update_effects,
        ))
      )
    end
  end

  def update_effects
    if turns.empty?
      []
    else
      updated = turns.last.effects.map do |effect|
        effect.clone.tap do |e|
          e.timer -= 1
        end
      end.filter do |effect|
        effect.timer > 0
      end

      case turns.last.action
      when Spell
        updated.push(turns.last.action.effect) 
      else
        updated
      end
    end
  end

  def state
    @state ||= if turns.empty?
      :player
    elsif turns.last.player_dead?
      :lose
    elsif turns.last.boss_dead?
      :win
    elsif turns.length % 2 == 0
      :player
    else
      :opponent
    end
  end

  def player_state
    if turns.empty?
      PlayerState.new(wizard.hp, wizard.mana, 0)
    else
      turns.last.next_player_state
    end
  end

  def opponent_state
    if turns.empty?
      OpponentState.new(boss.hp, boss.damage)
    else
      turns.last.next_boss_state
    end
  end

  def opponent_attack
    Attack.new(boss.damage)
  end

  def show
    turns.map(&:show).join("\n\n")
  end
end

class GameTree
  def wizard_1
    Wizard.new(10, 250)
  end

  def boss_1
    Boss.new(13, 8)
  end

  def boss_2
    Boss.new(14, 8)
  end

  def example_game_1
    Game.new(wizard_1, boss_1, [])
      .next_turn('Poison')
      .next_turn
      .next_turn('Magic Missile')
      .next_turn
  end

  def example_game_2
    Game.new(wizard_1, boss_2, [])
  end
end

@game_tree = GameTree.new
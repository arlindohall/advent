
Game = Struct.new(:wizard, :boss, :turns)

Wizard = Struct.new(:hp, :mana)
Boss = Struct.new(:hp, :damage)

PlayerState = Struct.new(:hp, :mana)
OpponentState = Struct.new(:hp, :damage)
Turn = Struct.new(:attacker, :player_state, :opponent_state, :effects, :action)

Attack = Struct.new(:damage)
Spell = Struct.new(:name, :cost, :damage, :heal, :effect)
Effect = Struct.new(:timer, :armor, :damage, :mana)

class SpellBook
  def book
    @spells ||= [
      Spell.new("Magic Missile", 53, 4, 0, nil),
      Spell.new("Drain", 73, 2, 2, nil),
      Spell.new("Shield", 113, 0, 0, Effect.new(6, 7, 0, 0)),
      Spell.new("Poison", 173, 0, 0, Effect.new(6, 0, 3, 0)),
      Spell.new("Recharge", 229, 0, 0, Effect.new(5, 0, 0, 101))
    ].map do |spell|
      [spell.name, spell]
    end.to_h
  end

  def spells
    book.values
  end

  def find(name)
    book[name] or raise "No spell named #{name}"
  end
end

class Spell
  def is_spell?
    true
  end

  def is_attack?
    false
  end
end

class Attack
  def is_spell?
    false
  end

  def is_attack?
    true
  end
end

class Turn
  def armor
    @armor ||= effects.map(&:armor).compact.sum
  end

  def recharge
    @recharge ||= effects.map(&:mana).compact.sum
  end

  def poison
    @poison ||= effects.map(&:damage).compact.sum
  end

  # Returns [PlayerState, OpponentState]
  def after_effects
    @after_effects ||= [
      PlayerState.new(player_state.hp, player_state.mana + recharge),
      OpponentState.new(opponent_state.hp - poison, opponent_state.damage - armor)
    ]
  end

  def healing
    if action.respond_to? :heal
      action.heal 
    else
      0
    end
  end

  def boss_attack
    if action.is_attack?
      action.damage
    else
      0
    end
  end

  def player_attack
    if action.is_spell?
      action.damage
    else
      0
    end
  end

  def spell_cost
    if action.is_spell?
      action.cost
    else
      0
    end
  end

  # Returns [PlayerState, OpponentState]
  def after_attack
    @after_attack ||= [
      PlayerState.new(player_state.hp - boss_attack + healing, player_state.mana + recharge - spell_cost),
      OpponentState.new(opponent_state.hp - player_attack - poison, opponent_state.damage - armor)
    ]
  end

  def player_wins?
    player, opponent = after_effects
    return true if opponent.hp <= 0

    _, opponent = after_attack
    return true if opponent.hp <= 0 && player.hp > 0

    false
  end

  def boss_wins?
    player, opponent = after_effects
    return true if player.hp <= 0

    _, opponent = after_attack
    return true if player.hp <= 0 && opponent.hp > 0

    false
  end
end

class Game
  def apply(action = Attack.new)
    if action.is_attack?
      action.damage = boss.damage
    end

    Game.new(
      wizard,
      boss,
      turns.clone.push(
        Turn.new(
          next_player,
          *next_states,
          next_effects,
          action,
        )
      )
    )
  end

  private
    def next_player
      if turns.empty?
        :player
      elsif turns.last.attacker == :boss
        :player
      else
        :boss
      end
    end

    def next_states
      if turns.empty?
        [
          PlayerState.new(wizard.hp, wizard.mana),
          OpponentState.new(boss.hp, boss.damage)
        ]
      else
        turns.last.after_attack
      end
    end

    def next_effects
      if turns.empty?
        []
      else
        increment_effects
      end
    end

    # Assumes at least 1 turn
    def increment_effects
      turns.last.effects.clone.push(last_effect).compact.map do |effect|
        effect.clone.tap do |e|
          e.timer -= 1
        end
      end
    end

    def last_effect
      if turns&.last&.action&.is_spell?
        turns&.last&.action&.effect
      end
    end
end

$spell_book = SpellBook.new
$player_1 = Wizard.new(10, 250)
$boss_1 = Boss.new(13, 8)
$boss_2 = Boss.new(14, 8)

class GameTree
  def compute_example_game_1
    Game.new($player_1, $boss_1, [])
      .apply($spell_book.find("Poison"))
      .apply
      .apply($spell_book.find("Magic Missile"))
      .apply
  end

  def example_game_1
    Game.new(
      $player_1,
      $boss_1,
      [
        Turn.new(
          :player,
          PlayerState.new(10, 250),
          OpponentState.new(13, 8),
          [],
          $spell_book.find("Poison"),
        ),
        Turn.new(
          :boss,
          PlayerState.new(10, 77),
          OpponentState.new(13, 8),
          [
            $spell_book.find("Poison").effect.clone.tap{ |e| e.timer = 5 },
          ],
          Attack.new(8),
        ),
        Turn.new(
          :player,
          PlayerState.new(2, 77),
          OpponentState.new(10, 8),
          [
            $spell_book.find("Poison").effect.clone.tap{ |e| e.timer = 4 },
          ],
          $spell_book.find("Magic Missile"),
        ),
        Turn.new(
          :boss,
          PlayerState.new(2, 24),
          OpponentState.new(3, 8),
          [
            $spell_book.find("Poison").effect.clone.tap{ |e| e.timer = 3 },
          ],
          Attack.new(8),
        ),
      ]
    )
  end

  def example_game_2
    Game.new(
      $player_1,
      $boss_2,
    )
  end
end

@game_tree = GameTree.new
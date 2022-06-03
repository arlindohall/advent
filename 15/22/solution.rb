
Game = Struct.new(:wizard, :boss, :turns)

Wizard = Struct.new(:hp, :mana)
Boss = Struct.new(:hp, :damage)

PlayerState = Struct.new(:hp, :mana)
OpponentState = Struct.new(:hp)
Turn = Struct.new(:attacker, :player_state, :opponent_state, :effects, :action)

Attack = Struct.new(:damage)
Spell = Struct.new(:name, :cost, :damage, :heal, :effect, :as_sentence)
Effect = Struct.new(:timer, :armor, :damage, :mana, :name)

class SpellBook
  def book
    @spells ||= [
      Spell.new("Magic Missile", 53, 4, 0, nil,
        "Player casts Magic Missile, dealing 4 damage."),
      Spell.new("Drain", 73, 2, 2, nil,
        "Player casts Drain, dealing 2 damage, and healing 2 hit points."),
      Spell.new("Shield", 113, 0, 0, Effect.new(6, 7, 0, 0, "Shield"),
        "Player casts Shield, increasing armor by 7 for 6 turns."),
      Spell.new("Poison", 173, 0, 0, Effect.new(6, 0, 3, 0, "Poison"),
        "Player casts Poison."),
      Spell.new("Recharge", 229, 0, 0, Effect.new(5, 0, 0, 101, "Recharge"),
        "Player casts Recharge."),
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

class Effect
  def as_sentence
    case name
    when "Shield"
      "Shield's timer is now #{timer}."
    when "Poison"
      "Poison deals 3 damage; its timer is now #{timer}."
    when "Recharge"
      "Recharge provides 101 mana; its timer is now #{timer}."
    end
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

  def cost
    0
  end

  def as_sentence
    "Boss attacks for #{damage} damage"
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
      PlayerState.new(
        player_state.hp - handicap,
        player_state.mana + recharge
      ),
      OpponentState.new(opponent_state.hp - poison),
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
      [action.damage - armor, 1].max
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

  def hard_mode?
    $hard_mode
  end

  def player_turn?
    attacker == :player
  end

  def handicap
    hard_mode? && player_turn? ? 1 : 0
  end

  # Returns [PlayerState, OpponentState]
  def after_attack
    @after_attack ||= [
      PlayerState.new(
        player_state.hp - boss_attack + healing - handicap,
        player_state.mana + recharge - spell_cost
      ),
      OpponentState.new(opponent_state.hp - player_attack - poison),
    ]
  end

  def winner?
    return :boss if after_effects.first.hp <= 0

    return :player if after_effects.last.hp <= 0

    return :player if after_attack.last.hp <= 0

    return :boss if after_attack.first.hp <= 0
  end

  def player_wins?
    winner? == :player
  end

  def boss_wins?
    winner? == :boss
  end

  def remaining_mana
    after_attack.first.mana
  end

  def in_effect?(spell)
    effects.any? do |effect|
      effect.name == spell.name && effect.timer > 0
    end
  end

  def possible_spells
    $spell_book.spells.filter do |spell|
      spell.cost <= remaining_mana
    end.filter do |spell|
      !in_effect?(spell)
    end
  end

  def show
    puts <<~EOS
      -- #{attacker == :player ? "Player" : "Boss"} turn --
      - Player has #{player_state.hp} hp, #{player_state.mana} mana
      - Boss has #{opponent_state.hp} hp
      #{effects.map(&:as_sentence).join("\n")}
      #{action.as_sentence}
      #{player_wins? ? "Player wins" : ""}#{boss_wins? ? "Boss wins" : ""}
    EOS
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

  def boss_wins?
    return false if turns.empty?
    turns.last.boss_wins?
  end

  def player_wins?
    return false if turns.empty?
    turns.last.player_wins?
  end

  def possible_spells
    if turns.empty?
      $spell_book.spells
    else
      turns.last.possible_spells
    end
  end

  def total_mana
    @total_mana ||= turns.map do |turn|
      turn.action.cost
    end.sum
  end

  def spells
    turns.map(&:action).select(&:is_spell?)
  end

  def show
    turns.each(&:show)
    nil
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
          OpponentState.new(boss.hp),
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
      end.filter{|e| e.timer >= 0}
    end

    def last_effect
      if turns&.last&.action&.is_spell?
        turns&.last&.action&.effect
      end
    end
end

$spell_book = SpellBook.new
$player = Wizard.new(50, 500)
$boss = Boss.new(55, 8)

$hard_mode = true

class GameTree
  def player_turns(game)
    game.possible_spells.map do |spell|
      next_game = game.apply(spell)
      if next_game.total_mana < @min_mana && next_game.player_wins?
        @min_mana = next_game.total_mana
        @winner = next_game
      end

      next_game if !next_game.boss_wins? && next_game.total_mana < @min_mana
    end.compact
  end

  def boss_turns(games)
    games.map do |game|
      next_game = game.apply
      if next_game.total_mana < @min_mana && next_game.player_wins?
        @min_mana = next_game.total_mana
        @winner = next_game
      end

      next_game if !next_game.boss_wins? && next_game.total_mana < @min_mana
    end.compact
  end

  def queue_solution
    @queue = [Game.new($player, $boss, [])]
    @min_mana = 10000
    @winner = nil

    while !@queue.empty?
      game = @queue.shift
      pt = player_turns(game)
      bt = boss_turns(pt)

      bt.each{ |g| @queue.push(g) }
    end
  end
end

@game_tree = GameTree.new
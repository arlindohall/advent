
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
    true
  end

  def handicap
    hard_mode? ? 1 : 0
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
    return :boss if player_state.hp - handicap <= 0

    return :player if after_effects[1].hp <= 0

    return :player if after_attack[1].hp <= 0

    return :boss if after_attack[0].hp <= 0
  end

  def player_wins?
    winner? == :player
  end

  def boss_wins?
    winner? == :boss
  end

  # def player_wins?
  #   return false if player_state.hp - handicap <= 0

  #   player, opponent = after_effects
  #   return true if opponent.hp <= 0

  #   player, opponent = after_attack
  #   return true if opponent.hp <= 0 && player.hp > 0

  #   false
  # end

  # def boss_wins?
  #   return true if player_state.hp - handicap <= 0

  #   player, opponent = after_effects
  #   return true if player.hp <= 0
  #   return false if opponent.hp <= 0

  #   player, opponent = after_attack
  #   return true if player.hp <= 0 && opponent.hp > 0

  #   return possible_spells.empty?
  # end

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
$player_1 = Wizard.new(10, 250)
$boss_1 = Boss.new(13, 8)
$boss_2 = Boss.new(14, 8)

$player = Wizard.new(50, 500)
$boss = Boss.new(55, 8)
# $player = $player_1
# $boss = $boss_2

class GameTree
  def compute_example_game_1
    Game.new($player_1, $boss_1, [])
      .apply($spell_book.find("Poison"))
      .apply(Attack.new)
      .apply($spell_book.find("Magic Missile"))
      .apply(Attack.new)
  end

  def example_game_1
    Game.new(
      $player_1,
      $boss_1,
      [
        Turn.new(
          :player,
          PlayerState.new(10, 250),
          OpponentState.new(13),
          [],
          $spell_book.find("Poison"),
        ),
        Turn.new(
          :boss,
          PlayerState.new(10, 77),
          OpponentState.new(13),
          [
            $spell_book.find("Poison").effect.clone.tap{ |e| e.timer = 5 },
          ],
          Attack.new(8),
        ),
        Turn.new(
          :player,
          PlayerState.new(2, 77),
          OpponentState.new(10),
          [
            $spell_book.find("Poison").effect.clone.tap{ |e| e.timer = 4 },
          ],
          $spell_book.find("Magic Missile"),
        ),
        Turn.new(
          :boss,
          PlayerState.new(2, 24),
          OpponentState.new(3),
          [
            $spell_book.find("Poison").effect.clone.tap{ |e| e.timer = 3 },
          ],
          Attack.new(8),
        ),
      ]
    )
  end

  def compute_example_game_2
    Game.new($player_1, $boss_2, [])
      .apply($spell_book.find("Recharge"))
      .apply(Attack.new)
      .apply($spell_book.find("Shield"))
      .apply(Attack.new)
      .apply($spell_book.find("Drain"))
      .apply(Attack.new)
      .apply($spell_book.find("Poison"))
      .apply(Attack.new)
      .apply($spell_book.find("Magic Missile"))
      .apply(Attack.new)
  end

  ###### PART 1 SOLUTION ######

  def min_key
    @games.keys.min
  end

  def merge_games(games)
    games.each do |game|
      @games[game.total_mana] ||= []
      @games[game.total_mana].push(game)
    end
  end

  def winners?(games)
    games.filter(&:player_wins?)
  end

  def player_moves(games)
    games.flat_map do |game|
      game.possible_spells.map do |spell|
        game.apply(spell)
      end
    end.compact
  end

  def boss_moves(games)
    games.map do |game|
      game.apply
    end.filter do |game|
      !game.boss_wins?
    end
  end

  def last_check(winner)
    mana = winner.total_mana

    possible_stragglers = @games.entries.filter do |key, games|
      key < mana
    end.flat_map do |key, games|
      games
    end

    return winner if possible_stragglers.empty?

    while !possible_stragglers.empty?
      possible_stragglers = player_moves(possible_stragglers)
        .filter{ |game| game.total_mana < mana }
      if !(winners = winners?(possible_stragglers)).empty?
        return winners.min_by(&:total_mana)
      end

      possible_stragglers = boss_moves(possible_stragglers)
        .filter{ |game| game.total_mana < mana }
      if !(winners = winners?(possible_stragglers)).empty?
        return winners.min_by(&:total_mana)
      end
    end

    winner
  end

  def part1
    @games ||= {0 => [Game.new($player, $boss, [])]}
    loop do
      next_games = player_moves(@games[min_key])
      # puts "Computing games with mana #{min_key}, found #{next_games.size} games"
      # puts "Manas: #{next_games.map(&:total_mana).join(", ")}"

      if !(winners = winners?(next_games)).empty?
        puts "Winners: #{winners.map(&:total_mana).join(", ")}"
        return last_check(winners.min_by(&:total_mana))
      end

      next_games = boss_moves(next_games)

      if !(winners = winners?(next_games)).empty?
        puts "Winners: #{winners.map(&:total_mana).join(", ")}"
        return last_check(winners.min_by(&:total_mana))
      end

      @games.delete(min_key)
      merge_games(next_games)
    end
  end

  def part2(depth = 0)
    # We know a ceiling for part 2, so we know the max number of spells
    # 26 is the max
    @games ||= [Game.new($player, $boss, [])]
    @winners = []
    if depth > 26
      return 1382
    end

    @games = @games.flat_map do |game|
      player_move = game.possible_spells.map do |spell|
        game.apply(spell)
      end.filter do |game|
        !game.boss_wins?
      end

      player_move = player_move.group_by(&:player_wins?)
      player_move, winners = [player_move[false] || [], player_move[true] || []]
      @winners += winners

      boss_move = player_move.map do |game|
        game.apply
      end.filter do |game|
        !game.boss_wins?
      end

      boss_move = boss_move.group_by(&:player_wins?)
      boss_move, winners = [boss_move[false] || [], boss_move[true] || []]
      @winners += winners

      boss_move
    end

    min = @winners.min_by(&:total_mana)&.total_mana
    puts "Found min mana #{min} of #{@winners.size} at depth #{depth} -> #{@winners.map(&:total_mana).join(", ")}"
    [min || 1382, part2(depth+1)].min
  end
end

@game_tree = GameTree.new

# PART 1
# 801 too low <- got by running @game_tree.part1 but bug on line 337 returned min_key
# 854 too low <- got by running @game_tree.part1.total_mana
# 953 correct <- forgot to exclude double-casted spells

# PART 2
# 1382 <- too high, got by running @game_tree.part1.total_mana
# 1408 <- too high, got by running @game_tree.part1.total_mana with the possible_stragglers
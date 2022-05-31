
Game = Struct.new(:wizard, :boss, :turns)

Wizard = Struct.new(:hp, :mana)
Boss = Struct.new(:hp, :damage)

PlayerState = Struct.new(:hp, :mana, :armor)
OpponentState = Struct.new(:hp, :damage)
Turn = Struct.new(:attacker, :player_state, :opponent_state, :action, :effects)

Spell = Struct.new(:name, :cost, :damage, :heal, :effect)
Effect = Struct.new(:timer, :armor, :damage, :mana)

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


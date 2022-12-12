

class Passport < Struct.new(:fields)
  def valid_values?
    return false unless valid_keys?
    [
      valid_birth_year?,
      valid_issue_year?,
      valid_expr_year?,
      valid_height?,
      valid_hair_color?,
      valid_eye_color?,
      valid_passport_id?,
    ].all?
  end

  def valid_birth_year?
    valid_year?(field('byr'), 1920..2002)
  end

  def valid_issue_year?
    valid_year?(field('iyr'), 2010..2020)
  end

  def valid_expr_year?
    valid_year?(field('eyr'), 2020..2030)
  end

  def valid_height?
    hgt = field('hgt')
    height = hgt.to_i
    if hgt.include?('cm')
      (150..193).include?(height)
    elsif hgt.include?('in')
      (59..76).include?(height)
    else
      false
    end
  end

  def valid_hair_color?
    field('hcl').match(/\A#[0-9a-f]{6}\z/)
  end

  def valid_eye_color?
    %w(amb blu brn gry grn hzl oth).include?(field('ecl'))
  end

  def valid_passport_id?
    field('pid').match(/\A[0-9]{9}\z/)
  end

  def valid_year?(value, range)
    range.include?(value.to_i)
  end

  def field(name)
    fields.filter { |f| f.key == name }
      .map(&:value)
      .first
  end

  def valid_keys?
    all_fields || missing_only_country
  end

  def all_fields
    fields.size == 8
  end

  def missing_only_country
    fields.size == 7 && missing_country
  end

  def missing_country
    fields.map(&:key).exclude?("cid")
  end

  def self.parse(line)
    line.split(/\s+/)
      .map { |pair| Pair.parse(pair) }
      .then { |fields| Passport.new(fields) }
  end

  class Pair < Struct.new(:key, :value)
    def self.parse(fields)
      new(*fields.split(":"))
    end
  end
end

class Scanner < Struct.new(:passports)
  def part1
    passports.count(&:valid_keys?)
  end

  def part2
    passports.count(&:valid_values?)
  end

  def all_fields(name)
    passports.map { |pt| pt.field(name) }
  end

  def fields(name)
    passports.filter(&:valid_values?)
      .map { |pt| pt.field(name) }
  end

  def self.parse(text)
    text.split("\n\n")
      .map { |line| Passport.parse(line) }
      .then { Scanner.new(_1) }
  end
end

def solve
  [
    Scanner.parse(read_input).part1,
    Scanner.parse(read_input).part2,
  ]
end
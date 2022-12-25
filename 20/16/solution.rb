
class Data < Struct.new(:text)
  def validate
    field_mapping.each do |name, index|
      raise 'Does not work on my ticket' unless
        field_list.fields.find { |field| field.name == name }
          .accepts?(your_ticket.fields[index])
    end
    :success
  end

  def my_ticket_mapping
    field_mapping.transform_values { |index| your_ticket.fields[index] }
  end

  def departures_product
    my_ticket_mapping.filter { |name, _| name.start_with?("departure") }
      .values
      .reduce(&:*)
  end

  def field_mapping
    @field_mapping ||= field_mapper.field_mapping
  end

  def field_mapper
    FieldMapper.new([], field_list.fields, valid_tickets)
  end

  def valid_tickets
    nearby_tickets.filter { |ticket| ticket.fields.all? { |field| field_list.accepts?(field) } }
  end

  def scanning_error_rate
    invalid_values.sum
  end

  def invalid_values
    nearby_tickets.flat_map { |ticket| ticket.fields }
      .reject { |field| field_list.accepts?(field) }
  end

  def parts
    text.split("\n\n")
  end

  def field_list
    @field_list ||= FieldList.new(parts.first.split("\n"))
  end

  def your_ticket
    @your_ticket ||= Ticket.new(parts[1].split("\n").last)
  end

  def nearby_tickets
    @nearby_tickets ||= parts.last.split("\n").drop(1).map { |line| Ticket.new(line) }
  end
end

class FieldMapper < Struct.new(:mapped_fields, :remaining_fields, :tickets)
  def field_mapping
    correct_mapping.each_with_index
      .to_h
      .transform_keys { |key| key.name }
  end

  def correct_mapping
    mapper = dup

    matching_fields.sort_by { |_idx, fields| fields.size }.map do |index, fields|
      next_field = (fields - mapped_fields.compact).first
      mapped_fields[index] = next_field
    end

    mapped_fields
  end

  # Note the input is a special case where each field matches
  # 1-20 fields uniquely, so you can take the one that matches once
  # and remove it from remaining, put it in mapped
  def matching_fields
    @matching_fields ||= remaining = tickets.first.fields.each_index.map do |index|
        remaining_fields.filter do |field|
          tickets.all? { |ticket| field.accepts?(ticket.fields[index]) }
        end
      end
      .each_with_index
      .map { |fields, index| [index, fields] }
      .to_h
  end
end

class FieldList < Struct.new(:lines)
  def fields
    @fields ||= lines.map { |line| Field.new(line) }
  end

  def accepts?(number)
    fields.any? { |fld| fld.accepts?(number) }
  end

  class Field < Struct.new(:description)
    def name
      @name ||= description.split(": ").first
    end

    def ranges
      @ranges ||= range_part.split(" or ").map do |range|
        Range.new(*range.split("-").map(&:to_i))
      end
    end

    def range_part
      description.split(": ").last
    end

    def accepts?(number)
      ranges.any? { |range| range.include?(number) }
    end
  end
end

class Ticket < Struct.new(:description)
  def fields
    description.split(",").map(&:to_i)
  end
end

def solve
  [
    Data.new(read_input).scanning_error_rate,
  ]
end
# Provide a mechanism to go from a number to a CSV/Excel column equivalent
# Thanks to sawa https://stackoverflow.com/questions/14632304/generate-letters-to-represent-number-using-ruby

# frozen_string_literal: true

class Numeric
  ALPHABET = ('a'..'z').to_a

  def to_csv_column
    column_name = String.new
    number = self
    while number.positive?
      number, remainder = (number - 1).divmod(26)
      column_name.prepend(ALPHABET[remainder])
    end
    column_name.upcase
  end
end

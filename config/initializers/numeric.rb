# Provide a mechanism to go from a number to a CSV/Excel column equivalent
# Thanks to sawa https://stackoverflow.com/questions/14632304/generate-letters-to-represent-number-using-ruby
class Numeric
  Alphabet = ('a'..'z').to_a

  def to_csv_column
    column_name = ''
    number = self
    while number.positive?
      number, remainder = (number - 1).divmod(26)
      column_name.prepend(Alphabet[remainder])
    end
    column_name.upcase
  end
end

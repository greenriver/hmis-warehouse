class Array
  # return items that occur in the array more than once
  def duplicates
    counts = Hash.new(0)
    each { |v| counts[v] += 1 }
    counts.select { |_, v| v > 1 }.keys
  end
end

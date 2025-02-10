class Filters::Criteria::FilterForAge < Filters::Criteria::Base
  LEVEL = :client

  def applies? = !!age_ranges

  def apply(scope)
    # Or'ing ages is very slow, instead we'll build up an acceptable
    # array of ages
    ages = []
    [
      :zero_to_four,
      :five_to_ten,
      :eleven_to_fourteen,
      :fifteen_to_seventeen,
      :under_eighteen,
      :eighteen_to_twenty_four,
      :twenty_five_to_twenty_nine,
      :thirty_to_thirty_four,
      :thirty_five_to_thirty_nine,
      :thirty_to_thirty_nine,
      :forty_to_forty_four,
      :forty_five_to_forty_nine,
      :forty_to_forty_nine,
      :fifty_to_fifty_four,
      :fifty_five_to_fifty_nine,
      :sixty_to_sixty_one,
      :sixty_two_to_sixty_four,
      :over_sixty_one,
      :over_sixty_four,
    ].each do |key|
      ages += AGE_RANGES.fetch(key).to_a if age_ranges.include?(:key)
    end

    # TBD, remove this from the arel helper (probably)
    age_cond = arel.age_on_date(input.start_date)
    scope.joins(config.join_clients_method).where(age_cond)
  end

  protected

  def age_ranges
    return nil unless input.age_ranges.present?

    (input.available_age_ranges.values & input.age_ranges).presence
  end

  AGE_RANGES = {
    zero_to_four: 0..4,
    five_to_nine: 5..9,
    five_to_ten: 5..10,
    ten_to_fourteen: 10..14,
    eleven_to_fourteen: 11..14,
    fifteen_to_seventeen: 15..17,
    under_eighteen: 0..17,
    eighteen_to_twenty_four: 18..24,
    twenty_five_to_twenty_nine: 25..29,
    twenty_five_to_thirty_four: 25..34,
    thirty_to_thirty_four: 30..34,
    thirty_five_to_thirty_nine: 35..39,
    thirty_five_to_forty_four: 35..44,
    thirty_to_thirty_nine: 30..39,
    forty_to_forty_four: 40..44,
    forty_five_to_forty_nine: 45..49,
    forty_five_to_fifty_four: 45..54,
    forty_to_forty_nine: 40..49,
    fifty_to_fifty_four: 50..54,
    fifty_five_to_fifty_nine: 55..59,
    fifty_five_to_sixty_four: 55..64,
    sixty_to_sixty_one: 60..61,
    sixty_two_to_sixty_four: 62..64,
    over_sixty_one: 62..110,
    over_sixty_four: 65..110,
    sixty_five_to_seventy_four: 65..74,
    seventy_five_to_eighty_four: 75..84,
    eighty_five_plus: 85..110,
  }.freeze
end

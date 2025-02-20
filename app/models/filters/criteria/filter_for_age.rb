class Filters::Criteria::FilterForAge < Filters::Criteria::Base
  def applies? = !!age_ranges

  def apply(scope)
    # Build an array of ages from selected ranges
    ages = collect_ages_from_selected_ranges

    # Apply age condition with collected ages
    age_cond = arel.age_on_date(input.start_date)
    scope.joins(config.join_clients_method).where(age_cond.in(ages))
  end

  protected

  def age_ranges
    return nil unless input.age_ranges.present?

    (input.available_age_ranges.values & input.age_ranges).presence
  end

  def collect_ages_from_selected_ranges
    return [] unless age_ranges

    age_ranges.flat_map { |range_key| AGE_RANGES.fetch(range_key).to_a }
  end

  AGE_RANGES = {
    zero_to_four: 0..4,
    five_to_ten: 5..10,
    eleven_to_fourteen: 11..14,
    fifteen_to_seventeen: 15..17,
    under_eighteen: 0..17,
    eighteen_to_twenty_four: 18..24,
    twenty_five_to_twenty_nine: 25..29,
    thirty_to_thirty_four: 30..34,
    thirty_five_to_thirty_nine: 35..39,
    thirty_to_thirty_nine: 30..39,
    forty_to_forty_four: 40..44,
    forty_five_to_forty_nine: 45..49,
    forty_to_forty_nine: 40..49,
    fifty_to_fifty_four: 50..54,
    fifty_five_to_fifty_nine: 55..59,
    sixty_to_sixty_one: 60..61,
    sixty_two_to_sixty_four: 62..64,
    over_sixty_one: 62..110,
    over_sixty_four: 65..110,
  }.freeze
end

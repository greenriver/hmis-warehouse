###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::Overview::Age
  extend ActiveSupport::Concern

  private def age_buckets
    [
      :under_eighteen,
      :eighteen_to_twenty_four,
      :twenty_five_to_sixty_one,
      :over_sixty_one,
      :unknown,
    ]
  end

  AGE_BUCKET_TITLES = {
    under_eighteen: 'Under 18',
    eighteen_to_twenty_four: '18-24',
    twenty_five_to_sixty_one: '25-61',
    over_sixty_one: 'Over 61',
    unknown: 'Unknown',
  }.freeze
  def age_bucket_titles
    AGE_BUCKET_TITLES
  end

  def age_bucket(age)
    return :unknown unless age

    if age < 18
      :under_eighteen
    elsif age >= 18 && age <= 24
      :eighteen_to_twenty_four
    elsif age >= 25 && age <= 61
      :twenty_five_to_sixty_one
    else
      :over_sixty_one
    end
  end

  def age_query(key)
    return '0=1' unless key

    @age_queries ||= {
      under_eighteen: she_t[:age].lt(18),
      eighteen_to_twenty_four: she_t[:age].between(18..24),
      twenty_five_to_sixty_one: she_t[:age].between(25..61),
      over_sixty_one: she_t[:age].gt(61),
      unknown: she_t[:age].eq(nil),
    }
    @age_queries[key.to_sym]
  end
end

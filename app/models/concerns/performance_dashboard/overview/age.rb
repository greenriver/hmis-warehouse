###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module PerformanceDashboard::Overview::Age # rubocop:disable Style/ClassAndModuleChildren
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

  def age_bucket_titles
    age_buckets.map do |key|
      [
        key,
        key.to_s.humanize,
      ]
    end.to_h
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

###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::Overview::Age
  extend ActiveSupport::Concern
  AGE_BUCKET_TITLES = {
    under_eighteen: '< 18',
    eighteen_to_twenty_four: '18 - 24',
    twenty_five_to_twenty_nine: '25 - 29',
    thirty_to_thirty_nine: '30 - 39',
    forty_to_forty_nine: '40 - 49',
    fifty_to_fifty_four: '50 - 54',
    fifty_five_to_fifty_nine: '55 - 59',
    sixty_to_sixty_one: '60 - 61',
    over_sixty_one: '62+',
    unknown: 'Unknown',
  }.freeze

  private def age_buckets
    AGE_BUCKET_TITLES.keys
  end

  def age_bucket_titles
    AGE_BUCKET_TITLES
  end

  def age_bucket(age)
    return :unknown unless age

    if age < 18
      :under_eighteen
    elsif age >= 18 && age <= 24
      :eighteen_to_twenty_four
    elsif age >= 25 && age <= 29
      :twenty_five_to_twenty_nine
    elsif age >= 30 && age <= 39
      :thirty_to_thirty_nine
    elsif age >= 40 && age <= 49
      :forty_to_forty_nine
    elsif age >= 50 && age <= 54
      :fifty_to_fifty_four
    elsif age >= 55 && age <= 59
      :fifty_five_to_fifty_nine
    elsif age >= 60 && age <= 61
      :sixty_to_sixty_one
    else
      :over_sixty_one
    end
  end

  def age_query(key)
    return '0=1' unless key

    @age_queries ||= {
      under_eighteen: she_t[:age].lt(18),
      eighteen_to_twenty_four: she_t[:age].between(18..24),
      twenty_five_to_twenty_nine: she_t[:age].between(25..29),
      thirty_to_thirty_nine: she_t[:age].between(30..39),
      forty_to_forty_nine: she_t[:age].between(40..49),
      fifty_to_fifty_four: she_t[:age].between(50..54),
      fifty_five_to_fifty_nine: she_t[:age].between(55..59),
      sixty_to_sixty_one: she_t[:age].between(60..61),
      over_sixty_one: she_t[:age].gt(61),
      unknown: she_t[:age].eq(nil),
    }
    @age_queries[key.to_sym]
  end
end

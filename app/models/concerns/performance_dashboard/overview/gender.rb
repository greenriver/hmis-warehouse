###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module PerformanceDashboard::Overview::Gender # rubocop:disable Style/ClassAndModuleChildren
  extend ActiveSupport::Concern

  private def gender_buckets
    # 0 => 'Female',
    #   1 => 'Male',
    #   2 => 'Trans Female (MTF or Male to Female)',
    #   3 => 'Trans Male (FTM or Female to Male)',
    #   4 => 'Gender non-conforming (i.e. not exclusively male or female)',
    #   8 => 'Client doesn’t know',
    #   9 => 'Client refused',
    #   99 => 'Data not collected',
    HUD.genders.keys
  end

  def gender_bucket_titles
    gender_buckets.map do |key|
      [
        key,
        HUD.gender(key),
      ]
    end.to_h
  end

  def gender_bucket(gender)
    return 99 unless gender

    gender
  end

  def gender_query(key)
    return '0=1' unless key

    @gender_queries ||= {
      under_eighteen: she_t[:gender].lt(18),
      eighteen_to_twenty_four: she_t[:gender].between(18..24),
      twenty_five_to_sixty_one: she_t[:gender].between(25..61),
      over_sixty_one: she_t[:gender].gt(61),
      unknown: she_t[:gender].eq(nil),
    }
    @gender_queries[key.to_i]
  end
end

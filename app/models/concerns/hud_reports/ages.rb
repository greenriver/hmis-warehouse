###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Required concerns:
#
# Required accessors:
#   a_t: Arel Type for the universe model
#
# Required universe fields:
#   age: Integer
#   dob_quality: Integer (HUD yes/no/reasons for missing data)
#
module HudReports::Ages
  extend ActiveSupport::Concern

  included do
    private def child_clause
      a_t[:age].between(0..17)
    end

    private def adult_clause
      a_t[:age].gteq(18)
    end

    private def unknown_age_clause
      a_t[:age].eq(nil).or(a_t[:age].lt(0))
    end

    private def adults?(ages)
      ages.reject(&:blank?).any? do |age|
        age >= 18
      end
    end

    private def children?(ages)
      ages.reject(&:blank?).any? do |age|
        age < 18
      end
    end

    private def unknown_ages?(ages)
      ages.any? do |age|
        age.blank? || age < 1
      end
    end

    private def age_ranges
      {
        'Under 5' => a_t[:age].between(0..4),
        '5-12' => a_t[:age].between(5..12),
        '13-17' => a_t[:age].between(13..17),
        '18-24' => a_t[:age].between(18..24),
        '25-34' => a_t[:age].between(25..34),
        '35-44' => a_t[:age].between(35..44),
        '45-54' => a_t[:age].between(45..54),
        '55-61' => a_t[:age].between(55..61),
        '62+' => a_t[:age].gteq(62),
        "Client Doesn't Know/Client Refused" => a_t[:dob_quality].in([8, 9]),
        'Data Not Collected' => a_t[:dob_quality].eq(99).and(a_t[:dob].eq(nil)),
        'Total' => Arel.sql('1=1'), # include everyone
      }
    end
  end
end

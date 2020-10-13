module
  CoreDemographicsReport::AgeCalculations
  extend ActiveSupport::Concern
  included do
    def age_categories
      {
        (0..4) => 'Newborn to 4',
        (5..10) => '5 to 10',
        (11..14) => '11 to 14',
        (15..17) => '15 to 17',
        (18..24) => '18 to 24',
        (25..34) => '25 to 34',
        (35..44) => '35 to 44',
        (45..54) => '45 to 54',
        (55..64) => '55 to 64',
        (65..110) => '65 +',
        [nil] => 'Unknown',
      }
    end

    def adult_count
      report_scope.joins(:client).where(adult_clause).select(:client_id).distinct.count
    end

    def adult_female_count
      report_scope.joins(:client).where(adult_clause.and(c_t[:Gender].eq(0))).select(:client_id).distinct.count
    end

    def adult_male_count
      report_scope.joins(:client).where(adult_clause.and(c_t[:Gender].eq(1))).select(:client_id).distinct.count
    end

    def child_count
      report_scope.joins(:client).where(child_clause).select(:client_id).distinct.count
    end

    def child_female_count
      report_scope.joins(:client).where(child_clause.and(c_t[:Gender].eq(0))).select(:client_id).distinct.count
    end

    def child_male_count
      report_scope.joins(:client).where(child_clause.and(c_t[:Gender].eq(1))).select(:client_id).distinct.count
    end

    def average_adult_age
      average_age(clause: adult_clause)
    end

    def average_adult_male_age
      average_age(clause: adult_clause.and(c_t[:Gender].eq(1)))
    end

    def average_adult_female_age
      average_age(clause: adult_clause.and(c_t[:Gender].eq(0)))
    end

    def average_child_age
      average_age(clause: child_clause)
    end

    def average_child_male_age
      average_age(clause: child_clause.and(c_t[:Gender].eq(1)))
    end

    def average_child_female_age
      average_age(clause: child_clause.and(c_t[:Gender].eq(0)))
    end
  end
end

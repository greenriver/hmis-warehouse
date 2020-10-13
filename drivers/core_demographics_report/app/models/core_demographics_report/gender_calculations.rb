module
  CoreDemographicsReport::GenderCalculations
  extend ActiveSupport::Concern
  included do
    def gender_count(type)
      gender_breakdowns[type].count.presence || 0
    end

    def gender_percentage(type)
      total_count = client_genders_and_ages.count
      return 0 if total_count.zero?

      of_type = gender_count(type)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    private def gender_breakdowns
      client_genders_and_ages.group_by do |_, row|
        row[:gender]
      end
    end

    private def client_genders_and_ages
      @client_genders_and_ages ||= {}.tap do |clients|
        report_scope.joins(:client).order(first_date_in_program: :desc).
          distinct.
          pluck(:client_id, age_calculation, c_t[:Gender], :first_date_in_program).
          each do |client_id, age, gender, _|
            clients[client_id] ||= {
              gender: gender.presence || 99,
              age: age,
            }
          end
      end
    end
  end
end

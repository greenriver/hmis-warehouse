module
  CoreDemographicsReport::GenderCalculations
  extend ActiveSupport::Concern
  included do
    def gender_count(type)
      gender_breakdowns[type]&.count&.presence || 0
    end

    def gender_percentage(type)
      total_count = client_genders_and_ages.count
      return 0 if total_count.zero?

      of_type = gender_count(type)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    def gender_age_count(gender:, age_range:)
      age_range.to_a.map do |age|
        gender_age_breakdowns[[gender, age]]&.count&.presence || 0
      end.sum
    end

    def gender_age_percentage(gender:, age_range:)
      total_count = client_genders_and_ages.count
      return 0 if total_count.zero?

      of_type = gender_age_count(gender: gender, age_range: age_range)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    private def gender_age_breakdowns
      @gender_age_breakdowns ||= client_genders_and_ages.group_by do |_, row|
        [
          row[:gender],
          row[:age],
        ]
      end
    end

    private def gender_breakdowns
      @gender_breakdowns ||= client_genders_and_ages.group_by do |_, row|
        row[:gender]
      end
    end

    private def client_genders_and_ages
      @client_genders_and_ages ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        {}.tap do |clients|
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
end

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
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        report_scope.joins(:client).where(adult_clause).select(:client_id).distinct.count
      end
    end

    def adult_female_count
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        report_scope.joins(:client).where(adult_clause.and(c_t[:Gender].eq(0))).select(:client_id).distinct.count
      end
    end

    def adult_male_count
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        report_scope.joins(:client).where(adult_clause.and(c_t[:Gender].eq(1))).select(:client_id).distinct.count
      end
    end

    def child_count
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        report_scope.joins(:client).where(child_clause).select(:client_id).distinct.count
      end
    end

    def child_female_count
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        report_scope.joins(:client).where(child_clause.and(c_t[:Gender].eq(0))).select(:client_id).distinct.count
      end
    end

    def child_male_count
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        report_scope.joins(:client).where(child_clause.and(c_t[:Gender].eq(1))).select(:client_id).distinct.count
      end
    end

    def average_adult_age
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        average_age(clause: adult_clause)
      end
    end

    def average_adult_male_age
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        average_age(clause: adult_clause.and(c_t[:Gender].eq(1)))
      end
    end

    def average_adult_female_age
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        average_age(clause: adult_clause.and(c_t[:Gender].eq(0)))
      end
    end

    def average_child_age
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        average_age(clause: child_clause)
      end
    end

    def average_child_male_age
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        average_age(clause: child_clause.and(c_t[:Gender].eq(1)))
      end
    end

    def average_child_female_age
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        average_age(clause: child_clause.and(c_t[:Gender].eq(0)))
      end
    end

    def age_count(type)
      client_ages.select { |_, age| age.in?(type) }&.count&.presence || 0
    end

    def age_percentage(type)
      total_count = client_ages.count
      return 0 if total_count.zero?

      of_type = age_count(type)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    def age_data_for_export(rows)
      rows['_Adults Break'] ||= []
      rows['*Adults'] ||= []
      rows['*Adults'] += ['Count', 'Average Age', nil, nil]
      rows['_Adults - All'] ||= []
      rows['_Adults - All'] += [adult_count, average_adult_age, nil, nil]
      rows['_Adults - Female'] ||= []
      rows['_Adults - Female'] += [adult_female_count, average_adult_female_age, nil, nil]
      rows['_Adults - Male'] ||= []
      rows['_Adults - Male'] += [adult_male_count, average_adult_male_age, nil, nil]

      rows['_Children Break'] ||= []
      rows['*Children'] ||= []
      rows['*Children'] += ['Count', 'Average Age', nil, nil]
      rows['_Children - All'] ||= []
      rows['_Children - All'] += [child_count, average_child_age, nil, nil]
      rows['_Children - Female'] ||= []
      rows['_Children - Female'] += [child_female_count, average_child_female_age, nil, nil]
      rows['_Children - Male'] ||= []
      rows['_Children - Male'] += [child_male_count, average_child_male_age, nil, nil]
      rows['_Age Beakdowns Break'] ||= []
      rows['*Age Beakdowns'] ||= []
      rows['*Age Beakdowns'] += ['Age Range', 'Count', 'Percentage', nil]
      age_categories.each do |age_range, age_title|
        rows["_Age Beakdowns#{age_title}"] ||= []
        rows["_Age Beakdowns#{age_title}"] += [
          age_title,
          age_count(age_range),
          age_percentage(age_range),
          nil,
        ]
      end
      rows
    end

    private def client_ages
      @client_ages ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        {}.tap do |clients|
          report_scope.joins(:client).order(first_date_in_program: :desc).
            distinct.
            pluck(:client_id, age_calculation, :first_date_in_program).
            each do |client_id, age, _|
              clients[client_id] ||= age
            end
        end
      end
    end
  end
end

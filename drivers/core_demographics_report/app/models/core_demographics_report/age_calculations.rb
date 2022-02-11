###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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

    def age_detail_hash
      {}.tap do |hashes|
        [
          :adult_scope,
          :adult_female_scope,
          :adult_male_scope,
          :child_scope,
          :child_female_scope,
          :child_male_scope,
        ].each do |key|
          title = key.to_s.sub('_scope', '').titleize.pluralize
          hashes[key.to_s] = {
            title: "Ages - #{title}",
            headers: client_headers,
            columns: client_columns,
            scope: -> { send(key) },
          }
        end
        age_categories.each do |key, title|
          hashes["age_#{key}"] = {
            title: title,
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client).where(client_id: client_ids_in_age_range(key)).distinct },
          }
        end
        age_categories.each do |age_key, age_title|
          HUD.genders.each do |gender, gender_title|
            hashes["age_#{age_key}_gender_#{gender}"] = {
              title: "Age - #{age_title} #{gender_title}",
              headers: client_headers,
              columns: client_columns,
              scope: -> { report_scope.joins(:client).where(client_id: client_ids_in_gender_age(gender, age_key)).distinct },
            }
          end
        end
      end
    end

    def adult_count
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        adult_scope.select(:client_id).distinct.count
      end
    end

    def adult_scope
      report_scope.joins(:client).where(adult_clause)
    end

    def adult_female_count
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        adult_female_scope.select(:client_id).distinct.count
      end
    end

    def adult_female_scope
      report_scope.joins(:client).where(adult_clause.and(female_clause))
    end

    def adult_male_count
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        adult_male_scope.select(:client_id).distinct.count
      end
    end

    def adult_male_scope
      report_scope.joins(:client).where(adult_clause.and(male_clause))
    end

    def child_count
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        child_scope.select(:client_id).distinct.count
      end
    end

    def child_scope
      report_scope.joins(:client).where(child_clause)
    end

    def child_female_count
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        child_female_scope.select(:client_id).distinct.count
      end
    end

    def child_female_scope
      report_scope.joins(:client).where(child_clause.and(female_clause))
    end

    def child_male_count
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        child_male_scope.select(:client_id).distinct.count
      end
    end

    def child_male_scope
      report_scope.joins(:client).where(child_clause.and(male_clause))
    end

    def average_adult_age
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        average_age(clause: adult_clause)
      end
    end

    def average_adult_male_age
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        average_age(clause: adult_clause.and(male_clause))
      end
    end

    def average_adult_female_age
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        average_age(clause: adult_clause.and(female_clause))
      end
    end

    def average_child_age
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        average_age(clause: child_clause)
      end
    end

    def average_child_male_age
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        average_age(clause: child_clause.and(male_clause))
      end
    end

    def average_child_female_age
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        average_age(clause: child_clause.and(female_clause))
      end
    end

    def age_count(type)
      clients_in_age_range(type)&.count&.presence || 0
    end

    def clients_in_age_range(type)
      client_ages.select { |_, age| age.in?(type) }
    end

    def client_ids_in_age_range(type)
      clients_in_age_range(type).keys
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
      rows['*Adults'] += ['Gender', 'Count', 'Average Age', nil, nil]
      rows['_Adults - All'] ||= []
      rows['_Adults - All'] += ['All', adult_count, average_adult_age, nil, nil]
      rows['_Adults - Female'] ||= []
      rows['_Adults - Female'] += ['Female', adult_female_count, average_adult_female_age, nil, nil]
      rows['_Adults - Male'] ||= []
      rows['_Adults - Male'] += ['Male', adult_male_count, average_adult_male_age, nil, nil]

      rows['_Children Break'] ||= []
      rows['*Children'] ||= []
      rows['*Children'] += ['Gender', 'Count', 'Average Age', nil, nil]
      rows['_Children - All'] ||= []
      rows['_Children - All'] += ['All', child_count, average_child_age, nil, nil]
      rows['_Children - Female'] ||= []
      rows['_Children - Female'] += ['Female', child_female_count, average_child_female_age, nil, nil]
      rows['_Children - Male'] ||= []
      rows['_Children - Male'] += ['Male', child_male_count, average_child_male_age, nil, nil]
      rows['_Age Beakdowns Break'] ||= []
      rows['*Age Beakdowns'] ||= []
      rows['*Age Beakdowns'] += ['Age Range', 'Count', 'Percentage', nil]
      age_categories.each do |age_range, age_title|
        rows["_Age Beakdowns_data_#{age_title}"] ||= []
        rows["_Age Beakdowns_data_#{age_title}"] += [
          age_title,
          age_count(age_range),
          age_percentage(age_range) / 100,
          nil,
        ]
      end
      rows
    end

    private def client_ages
      @client_ages ||= Rails.cache.fetch(age_cache_key, expires_in: expiration_length) do
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

    private def age_cache_key
      [self.class.name, cache_slug, 'client_ages']
    end
  end
end

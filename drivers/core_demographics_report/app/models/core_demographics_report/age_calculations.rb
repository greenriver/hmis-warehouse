###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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
          :adult_woman_scope,
          :adult_man_scope,
          :adult_culturally_specific_scope,
          :adult_different_identity,
          :adult_trans_scope,
          :adult_questioning_scope,
          :adult_non_binary_scope,
          :adult_unknown_gender_scope,
          :child_scope,
          :child_woman_scope,
          :child_man_scope,
          :child_culturally_specific_scope,
          :child_different_identity,
          :child_trans_scope,
          :child_questioning_scope,
          :child_non_binary_scope,
          :child_unknown_gender_scope,
        ].each do |key|
          title = key.to_s.sub('_scope', '').titleize.pluralize
          hashes[key.to_s] = {
            title: "Ages - #{title}",
            headers: client_headers,
            columns: client_columns,
            scope: -> { send(key).joins(:client, :enrollment).distinct },
          }
        end
        age_categories.each do |key, title|
          hashes["age_#{key}"] = {
            title: title,
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client, :enrollment).where(client_id: client_ids_in_age_range(key)).distinct },
          }
        end
        age_categories.each do |age_key, age_title|
          HudUtility2024.genders.each do |gender, gender_title|
            hashes["age_#{age_key}_gender_#{gender}"] = {
              title: "Age - #{age_title} #{gender_title}",
              headers: client_headers,
              columns: client_columns,
              scope: -> { report_scope.joins(:client, :enrollment).where(client_id: client_ids_in_gender_age(gender, age_key)).distinct },
            }
          end
        end
      end
    end

    def adult_count
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        mask_small_population(adult_scope.select(:client_id).distinct.count)
      end
    end

    def adult_scope
      report_scope.joins(:client).where(adult_clause)
    end

    def adult_woman_count
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        mask_small_population(adult_woman_scope.select(:client_id).distinct.count)
      end
    end

    def adult_woman_scope
      report_scope.joins(:client).where(adult_clause.and(woman_clause))
    end

    def adult_man_count
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        mask_small_population(adult_man_scope.select(:client_id).distinct.count)
      end
    end

    def adult_man_scope
      report_scope.joins(:client).where(adult_clause.and(man_clause))
    end

    def adult_culturally_specific_count
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        mask_small_population(adult_culturally_specific_scope.select(:client_id).distinct.count)
      end
    end

    def adult_culturally_specific_scope
      report_scope.joins(:client).where(adult_clause.and(culturally_specific_clause))
    end

    def adult_different_identity_count
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        mask_small_population(adult_different_identity_scope.select(:client_id).distinct.count)
      end
    end

    def adult_different_identity_scope
      report_scope.joins(:client).where(adult_clause.and(different_identity_clause))
    end

    def adult_trans_count
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        mask_small_population(adult_trans_scope.select(:client_id).distinct.count)
      end
    end

    def adult_trans_scope
      report_scope.joins(:client).where(adult_clause.and(trans_clause))
    end

    def adult_questioning_count
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        mask_small_population(adult_questioning_scope.select(:client_id).distinct.count)
      end
    end

    def adult_questioning_scope
      report_scope.joins(:client).where(adult_clause.and(questioning_clause))
    end

    def adult_non_binary_count
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        mask_small_population(adult_non_binary_scope.select(:client_id).distinct.count)
      end
    end

    def adult_non_binary_scope
      report_scope.joins(:client).where(adult_clause.and(non_binary_clause))
    end

    def adult_unknown_gender_count
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        mask_small_population(adult_unknown_gender_scope.select(:client_id).distinct.count)
      end
    end

    def adult_unknown_gender_scope
      report_scope.joins(:client).where(adult_clause.and(unknown_gender_clause))
    end

    def child_count
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        mask_small_population(child_scope.select(:client_id).distinct.count)
      end
    end

    def child_scope
      report_scope.joins(:client).where(child_clause)
    end

    def child_woman_count
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        mask_small_population(child_woman_scope.select(:client_id).distinct.count)
      end
    end

    def child_woman_scope
      report_scope.joins(:client).where(child_clause.and(woman_clause))
    end

    def child_man_count
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        mask_small_population(child_man_scope.select(:client_id).distinct.count)
      end
    end

    def child_man_scope
      report_scope.joins(:client).where(child_clause.and(man_clause))
    end

    def child_culturally_specific_count
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        mask_small_population(child_culturally_specific_scope.select(:client_id).distinct.count)
      end
    end

    def child_culturally_specific_scope
      report_scope.joins(:client).where(child_clause.and(culturally_specific_clause))
    end

    def child_different_identity_count
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        mask_small_population(child_different_identity_scope.select(:client_id).distinct.count)
      end
    end

    def child_different_identity_scope
      report_scope.joins(:client).where(child_clause.and(different_identity_clause))
    end

    def child_trans_count
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        mask_small_population(child_trans_scope.select(:client_id).distinct.count)
      end
    end

    def child_trans_scope
      report_scope.joins(:client).where(child_clause.and(trans_clause))
    end

    def child_questioning_count
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        mask_small_population(child_questioning_scope.select(:client_id).distinct.count)
      end
    end

    def child_questioning_scope
      report_scope.joins(:client).where(child_clause.and(questioning_clause))
    end

    def child_non_binary_count
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        mask_small_population(child_non_binary_scope.select(:client_id).distinct.count)
      end
    end

    def child_non_binary_scope
      report_scope.joins(:client).where(child_clause.and(non_binary_clause))
    end

    def child_unknown_gender_count
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        mask_small_population(child_unknown_gender_scope.select(:client_id).distinct.count)
      end
    end

    def child_unknown_gender_scope
      report_scope.joins(:client).where(child_clause.and(unknown_gender_clause))
    end

    def average_adult_age
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        average_age(clause: adult_clause)
      end
    end

    def average_adult_man_age
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        average_age(clause: adult_clause.and(man_clause))
      end
    end

    def average_adult_woman_age
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        average_age(clause: adult_clause.and(woman_clause))
      end
    end

    def average_adult_culturally_specific_age
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        average_age(clause: adult_clause.and(culturally_specific_clause))
      end
    end

    def average_adult_different_identity_age
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        average_age(clause: adult_clause.and(different_identity_clause))
      end
    end

    def average_adult_trans_age
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        average_age(clause: adult_clause.and(trans_clause))
      end
    end

    def average_adult_questioning_age
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        average_age(clause: adult_clause.and(questioning_clause))
      end
    end

    def average_adult_non_binary_age
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        average_age(clause: adult_clause.and(non_binary_clause))
      end
    end

    def average_adult_unknown_gender_age
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        average_age(clause: adult_clause.and(unknown_gender_clause))
      end
    end

    def average_child_age
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        average_age(clause: child_clause)
      end
    end

    def average_child_man_age
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        average_age(clause: child_clause.and(man_clause))
      end
    end

    def average_child_woman_age
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        average_age(clause: child_clause.and(woman_clause))
      end
    end

    def average_child_culturally_specific_age
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        average_age(clause: child_clause.and(culturally_specific_clause))
      end
    end

    def average_child_different_identity_age
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        average_age(clause: child_clause.and(different_identity_clause))
      end
    end

    def average_child_trans_age
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        average_age(clause: child_clause.and(trans_clause))
      end
    end

    def average_child_questioning_age
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        average_age(clause: child_clause.and(questioning_clause))
      end
    end

    def average_child_non_binary_age
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        average_age(clause: child_clause.and(non_binary_clause))
      end
    end

    def average_child_unknown_gender_age
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        average_age(clause: child_clause.and(unknown_gender_clause))
      end
    end

    def age_count(type)
      mask_small_population(clients_in_age_range(type)&.count&.presence || 0)
    end

    def clients_in_age_range(type)
      client_ages.select { |_, age| age.in?(type) }
    end

    def client_ids_in_age_range(type)
      clients_in_age_range(type).keys
    end

    def age_percentage(type)
      total_count = mask_small_population(client_ages.count)
      return 0 if total_count.zero?

      of_type = age_count(type)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    def age_data_for_export(rows)
      rows['_Adults Break'] ||= []
      rows['*Adults'] ||= []
      rows['*Adults'] += ['Gender', nil, 'Count', 'Average Age', nil]
      rows['_Adults - All'] ||= []
      rows['_Adults - All'] += ['All', nil, adult_count, average_adult_age, nil]
      rows['_Adults - Woman'] ||= []
      rows['_Adults - Woman'] += ['Woman', nil, adult_woman_count, average_adult_woman_age, nil]
      rows['_Adults - Man'] ||= []
      rows['_Adults - Man'] += ['Man', nil, adult_man_count, average_adult_man_age, nil]
      rows['_Adults - Culturally Specific'] ||= []
      rows['_Adults - Culturally Specific'] += ['Culturally Specific', nil, adult_culturally_specific_count, average_adult_culturally_specific_age, nil]
      rows['_Adults - Different Identity'] ||= []
      rows['_Adults - Different Identity'] += ['Different Identity', nil, adult_different_identity_count, average_adult_different_identity_age, nil]
      rows['_Adults - Transgender'] ||= []
      rows['_Adults - Transgender'] += ['Transgender', nil, adult_trans_count, average_adult_trans_age, nil]
      rows['_Adults - Questioning'] ||= []
      rows['_Adults - Questioning'] += ['Questioning', nil, adult_questioning_count, average_adult_questioning_age, nil]
      rows['_Adults - Non-Binary'] ||= []
      rows['_Adults - Non-Binary'] += ['Non-Binary', nil, adult_non_binary_count, average_adult_non_binary_age, nil]
      rows['_Adults - Unknown Gender'] ||= []
      rows['_Adults - Unknown Gender'] += ['Unknown Gender', nil, adult_unknown_gender_count, average_adult_unknown_gender_age, nil]

      rows['_Children Break'] ||= []
      rows['*Children'] ||= []
      rows['*Children'] += ['Gender', nil, 'Count', 'Average Age', nil]
      rows['_Children - All'] ||= []
      rows['_Children - All'] += ['All', nil, child_count, average_child_age, nil]
      rows['_Children - Woman'] ||= []
      rows['_Children - Woman'] += ['Woman', nil, child_woman_count, average_child_woman_age, nil]
      rows['_Children - Man'] ||= []
      rows['_Children - Man'] += ['Man', nil, child_man_count, average_child_man_age, nil]
      rows['_Children - Culturally Specific'] ||= []
      rows['_Children - Culturally Specific'] += ['Culturally Specific', nil, child_culturally_specific_count, average_child_culturally_specific_age, nil]
      rows['_Children - Different Identity'] ||= []
      rows['_Children - Different Identity'] += ['Different Identity', nil, child_different_identity_count, average_child_different_identity_age, nil]
      rows['_Children - Transgender'] ||= []
      rows['_Children - Transgender'] += ['Transgender', nil, child_trans_count, average_child_trans_age, nil]
      rows['_Children - Questioning'] ||= []
      rows['_Children - Questioning'] += ['Questioning', nil, child_questioning_count, average_child_questioning_age, nil]
      rows['_Children - Non-Binary'] ||= []
      rows['_Children - Non-Binary'] += ['Non-Binary', nil, child_non_binary_count, average_child_non_binary_age, nil]
      rows['_Children - Unknown Gender'] ||= []
      rows['_Children - Unknown Gender'] += ['Unknown Gender', nil, child_unknown_gender_count, average_child_unknown_gender_age, nil]
      rows['_Age Breakdowns Break'] ||= []
      rows['*Age Breakdowns'] ||= []
      rows['*Age Breakdowns'] += ['Age Range', nil, 'Count', 'Percentage']
      age_categories.each do |age_range, age_title|
        rows["_Age Breakdowns_data_#{age_title}"] ||= []
        rows["_Age Breakdowns_data_#{age_title}"] += [
          age_title,
          nil,
          age_count(age_range),
          age_percentage(age_range) / 100,
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

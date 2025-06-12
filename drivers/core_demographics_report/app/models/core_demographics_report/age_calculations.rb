###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module
  CoreDemographicsReport::AgeCalculations
  extend ActiveSupport::Concern
  included do
    # Defines the age categories and their corresponding ranges for reporting
    # @return [Hash] A hash mapping age ranges to display names
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

    # Returns the age range for a given category (child or adult)
    # @param category [String] The age category ('child' or 'adult')
    # @return [Range] The age range for the specified category
    # @raise [RuntimeError] If an unknown category is provided
    def age_range_for(category)
      return (0..17) if category == 'child'
      return (18..110) if category == 'adult'

      raise "unknown category: #{category}"
    end

    # Generates a hash of detail reports for age-related demographics
    # @return [Hash] A hash containing report configurations for different age categories
    def age_detail_hash
      {}.tap do |hashes|
        genders.each do |gender_col, gender_label|
          [
            'adult',
            'child',
          ].each do |age_category|
            key = "#{age_category}_#{gender_col}".to_sym
            scope = "#{key}_scope".to_sym

            title = "#{age_category.titleize} #{gender_label}"
            hashes[key.to_s] = {
              title: "Ages - #{title}",
              headers: client_headers,
              columns: client_columns,
              scope: -> {
                age_ids = client_ids_in_age_range(age_range_for(age_category)).to_a
                gender_ids = client_ids_in_gender(gender_col).to_a
                ids = age_ids & gender_ids
                send(scope).
                  where(client_id: ids).
                  joins(:client, :enrollment).
                  distinct
              },
            }
          end
          age_categories.each do |age_key, title|
            hashes["age_#{age_key}"] = {
              title: title,
              headers: client_headers,
              columns: client_columns,
              scope: -> { report_scope.joins(:client, :enrollment).where(client_id: client_ids_in_age_range(age_key)).distinct },
            }
          end
          age_categories.each do |age_key, age_title|
            genders.each do |gender, gender_title|
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
    end

    # Counts the number of adult clients
    # @return [Integer] The count of adult clients, masked if appropriate
    def adult_count
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        mask_small_population(adult_scope.select(:client_id).distinct.count)
      end
    end

    # Returns the scope for adult clients
    # @return [ActiveRecord::Relation] The scope for adult clients
    def adult_scope
      report_scope.joins(:client).where(adult_clause)
    end

    # Calculates the average age of adult clients
    # @return [Float] The average age of adult clients
    def average_adult_age
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        average_age(clause: adult_clause)
      end
    end

    # Counts the number of child clients
    # @return [Integer] The count of child clients, masked if population is small
    def child_count
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        mask_small_population(child_scope.select(:client_id).distinct.count)
      end
    end

    # Returns the scope for child clients
    # @return [ActiveRecord::Relation] The scope for child clients
    def child_scope
      report_scope.joins(:client).where(child_clause)
    end

    # Calculates the average age of child clients
    # @return [Float] The average age of child clients
    def average_child_age
      Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        average_age(clause: child_clause)
      end
    end

    # Dynamically defines methods for gender-specific age calculations
    genders.each_key do |gender_col|
      [
        'adult',
        'child',
      ].each do |age_category|
        age_category_clause = "#{age_category}_clause"

        # Defines a scope method for the given age category and gender
        define_method "#{age_category}_#{gender_col}_scope" do
          report_scope.joins(:client).where(send(age_category_clause).and(gender_clause(gender_col)))
        end

        # Defines a count method for the given age category and gender
        define_method "#{age_category}_#{gender_col}_count" do
          Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
            age_ids = client_ids_in_age_range(age_range_for(age_category)).to_a
            gender_ids = client_ids_in_gender(gender_col).to_a
            ids = age_ids & gender_ids
            mask_small_population(send("#{age_category}_#{gender_col}_scope").where(client_id: ids).select(:client_id).distinct.count)
          end
        end

        # Defines an average age method for the given age category and gender
        define_method "average_#{age_category}_#{gender_col}_age" do
          Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
            average_age(clause: send(age_category_clause).and(gender_clause(gender_col)))
          end
        end
      end
    end

    # Counts clients in a specific age category for a given CoC
    # @param age_category [String] The age category to count
    # @param coc_code [Symbol] The CoC code to filter by
    # @return [Integer] The count of clients in the specified age category and CoC
    def age_coc_count(age_category, coc_code)
      age_category_clause = "#{age_category}_clause"
      mask_small_population(
        report_scope.
          in_enrollment_coc(coc_code: coc_code).
          joins(:client).
          where(send(age_category_clause)).
          select(:client_id).distinct.count,
      )
    end

    # Counts clients in a specific age category and gender for a given CoC
    # @param age_category [String] The age category to count
    # @param gender_col [Symbol] The gender column to filter by
    # @param coc_code [Symbol] The CoC code to filter by
    # @return [Integer] The count of clients in the specified age category, gender, and CoC
    def age_gender_coc_count(age_category, gender_col, coc_code)
      age_category_clause = "#{age_category}_clause"
      mask_small_population(
        report_scope.
          in_enrollment_coc(coc_code: coc_code).
          joins(:client).
          where(send(age_category_clause).and(gender_clause(gender_col))).
          select(:client_id).distinct.count,
      )
    end

    # Counts clients in a specific age range
    # @param type [Range] The age range to count
    # @param coc_code [Symbol] The CoC code to filter by (defaults to base_count_sym)
    # @return [Integer] The count of clients in the specified age range
    def age_count(type, coc_code = base_count_sym)
      mask_small_population(clients_in_age_range(type, coc_code)&.count&.presence || 0)
    end

    # Returns clients within a specific age range
    # @param type [Range] The age range to filter by
    # @param coc_code [Symbol] The CoC code to filter by (defaults to base_count_sym)
    # @return [Hash] A hash of client IDs and their ages within the specified range
    def clients_in_age_range(type, coc_code = base_count_sym)
      client_ages[coc_code]&.select { |_, age| age.in?(type) }
    end

    # Returns client IDs within a specific age range
    # @param type [Range] The age range to filter by
    # @return [Array] Array of client IDs within the specified age range
    def client_ids_in_age_range(type)
      clients_in_age_range(type).keys
    end

    # Calculates the percentage of clients in a specific age range
    # @param type [Range] The age range to calculate percentage for
    # @param coc_code [Symbol] The CoC code to filter by (defaults to base_count_sym)
    # @return [Float] The percentage of clients in the specified age range
    def age_percentage(type, coc_code = base_count_sym)
      total_count = mask_small_population(client_ages[coc_code].count)
      return 0 if total_count.zero?

      of_type = age_count(type, coc_code)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    # Prepares age-related data for export
    # @param rows [Hash] The hash to store the export data
    # @return [Hash] The updated rows hash with age-related data
    def age_data_for_export(rows)
      [
        'adult',
        'child',
      ].each do |age_category|
        age_category_title = age_category.titleize.pluralize
        rows["_#{age_category_title} Break"] ||= []
        rows["*#{age_category_title}"] ||= []
        rows["*#{age_category_title}"] += ['Gender', nil, 'Count', 'Average Age', nil]
        available_coc_codes.each do |coc_code|
          rows["*#{age_category_title}"] += [coc_code]
        end
        rows["*#{age_category_title}"] += [nil]
        rows["_#{age_category_title} - All"] ||= []
        rows["_#{age_category_title} - All"] += ['All', nil, send("#{age_category}_count"), send("average_#{age_category}_age"), nil]
        available_coc_codes.each do |coc_code|
          rows["_#{age_category_title} - All"] += [age_coc_count(age_category, coc_code.to_sym)]
        end
        genders.each do |gender_col, gender_label|
          rows["_#{age_category_title} - #{gender_label}"] ||= []
          rows["_#{age_category_title} - #{gender_label}"] += [gender_label, nil, send("#{age_category}_#{gender_col}_count"), send("average_#{age_category}_#{gender_col}_age"), nil]
          available_coc_codes.each do |coc_code|
            rows["_#{age_category_title} - #{gender_label}"] += [age_gender_coc_count(age_category, gender_col, coc_code.to_sym)]
          end
        end
      end

      rows['_Age Breakdowns Break'] ||= []
      rows['*Age Breakdowns'] ||= []
      rows['*Age Breakdowns'] += ['Age Range', nil, 'Count', 'Percentage', nil]
      available_coc_codes.each do |coc_code|
        rows['*Age Breakdowns'] += ["#{coc_code} Client"]
        rows['*Age Breakdowns'] += ["#{coc_code} Percentage"]
      end
      rows['*Age Breakdowns'] += [nil]
      age_categories.each do |age_range, age_title|
        rows["_Age Breakdowns_data_#{age_title}"] ||= []
        rows["_Age Breakdowns_data_#{age_title}"] += [
          age_title,
          nil,
          age_count(age_range),
          age_percentage(age_range) / 100,
          nil,
        ]
        available_coc_codes.each do |coc_code|
          rows["_Age Breakdowns_data_#{age_title}"] += [
            age_count(age_range, coc_code.to_sym),
            age_percentage(age_range, coc_code.to_sym) / 100,
          ]
        end
      end
      rows
    end

    # Retrieves and caches client ages
    # @return [Hash] A hash containing client ages by CoC
    private def client_ages
      @client_ages ||= Rails.cache.fetch(age_cache_key, expires_in: expiration_length) do
        {}.tap do |clients|
          clients[base_count_sym] ||= {}
          report_scope.joins(:client).order(first_date_in_program: :desc).
            distinct.
            pluck(:client_id, age_calculation, :first_date_in_program).
            each do |client_id, age, _|
              clients[base_count_sym][client_id] ||= age
            end
          available_coc_codes.each do |coc_code|
            clients[coc_code.to_sym] ||= {}
            report_scope.joins(:client).order(first_date_in_program: :desc).
              distinct.in_enrollment_coc(coc_code: coc_code.to_sym).
              pluck(:client_id, age_calculation, :first_date_in_program).
              each do |client_id, age, _|
                clients[coc_code.to_sym][client_id] ||= age
              end
          end
        end
      end
    end

    # Generates the cache key for client ages
    # @return [Array] The cache key components
    private def age_cache_key
      [self.class.name, cache_slug, 'client_ages']
    end
  end
end

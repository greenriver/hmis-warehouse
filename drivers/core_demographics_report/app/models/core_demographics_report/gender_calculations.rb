###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module
  CoreDemographicsReport::GenderCalculations
  extend ActiveSupport::Concern
  included do
    # Generates a hash of detail reports for gender data
    # @return [Hash] A hash containing report configurations for different gender categories
    def gender_detail_hash
      {}.tap do |hashes|
        genders.each do |key, title|
          hashes["gender_#{key}"] = {
            title: "Gender - #{title}",
            headers: client_headers,
            columns: client_columns,
            scope: -> {
              report_scope.
                joins(:client, :enrollment).
                where(client_id: client_ids_in_gender(key)).
                distinct
            },
          }
        end
      end
    end

    # Counts the number of clients with a specific gender
    # @param type [Symbol] The gender type to count
    # @param coc_code [Symbol] The CoC code to filter by, defaults to base_count_sym
    # @return [Integer] The count of clients with the specified gender, masked if population is small
    def gender_count(type, coc_code = base_count_sym)
      mask_small_population(client_ids_in_gender(type, coc_code)&.count&.presence || 0)
    end

    # Calculates the percentage of clients with a specific gender
    # @param type [Symbol] The gender type to calculate percentage for
    # @param coc_code [Symbol] The CoC code to filter by, defaults to base_count_sym
    # @return [Float] The percentage of clients with the specified gender
    def gender_percentage(type, coc_code = base_count_sym)
      total_count = mask_small_population(client_genders_and_ages[coc_code].count)
      return 0 if total_count.zero?

      of_type = gender_count(type, coc_code)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    # Counts the number of clients with a specific gender and age range
    # @param gender [Symbol] The gender type to count
    # @param age_range [Range] The age range to count
    # @param coc_code [Symbol] The CoC code to filter by, defaults to base_count_sym
    # @return [Integer] The count of clients with the specified gender and age range, masked if population is small
    def gender_age_count(gender:, age_range:, coc_code: base_count_sym)
      mask_small_population(client_ids_in_gender_age(gender, age_range, coc_code)&.count&.presence || 0)
    end

    # Calculates the percentage of clients with a specific gender and age range
    # @param gender [Symbol] The gender type to calculate percentage for
    # @param age_range [Range] The age range to calculate percentage for
    # @param coc_code [Symbol] The CoC code to filter by, defaults to base_count_sym
    # @return [Float] The percentage of clients with the specified gender and age range
    def gender_age_percentage(gender:, age_range:, coc_code: base_count_sym)
      total_count = mask_small_population(client_genders_and_ages[coc_code].count)
      return 0 if total_count.zero?

      of_type = gender_age_count(gender: gender, age_range: age_range, coc_code: coc_code)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    # Prepares gender and age data for export
    # @param rows [Hash] The hash to store the export data
    # @return [Hash] The updated rows hash with gender and age data
    def gender_data_for_export(rows)
      rows['_Gender Break'] ||= []
      rows['*Gender Breakdowns'] ||= []
      rows['*Gender Breakdowns'] += ['Gender', nil, 'Count', 'Percentage', nil]
      available_coc_codes.each do |coc_code|
        rows['*Gender Breakdowns'] += ["#{coc_code} Client"]
        rows['*Gender Breakdowns'] += ["#{coc_code} Percentage"]
      end
      rows['*Gender Breakdowns'] += [nil]
      genders.each do |id, title|
        rows["_Gender Breakdowns_data_#{title}"] ||= []
        rows["_Gender Breakdowns_data_#{title}"] += [
          title,
          nil,
          gender_count(id),
          gender_percentage(id) / 100,
          nil,
        ]
        available_coc_codes.each do |coc_code|
          rows["_Gender Breakdowns_data_#{title}"] += [
            gender_count(id, coc_code.to_sym),
            gender_percentage(id, coc_code.to_sym) / 100,
          ]
        end
      end
      rows['_Gender/Age Breakdowns Break'] ||= []
      rows['*Gender/Age Breakdowns'] ||= []
      rows['*Gender/Age Breakdowns'] += ['Gender', 'Age Range', 'Count', 'Percentage', nil]
      available_coc_codes.each do |coc_code|
        rows['*Gender/Age Breakdowns'] += ["#{coc_code} Client"]
        rows['*Gender/Age Breakdowns'] += ["#{coc_code} Percentage"]
      end
      rows['*Gender/Age Breakdowns'] += [nil]
      genders.each do |gender, gender_title|
        age_categories.each do |age_range, age_title|
          rows["_Gender/Age_data_#{gender_title} #{age_title}"] ||= []
          rows["_Gender/Age_data_#{gender_title} #{age_title}"] += [
            gender_title,
            age_title,
            gender_age_count(gender: gender, age_range: age_range),
            gender_age_percentage(gender: gender, age_range: age_range) / 100,
            nil,
          ]
          available_coc_codes.each do |coc_code|
            rows["_Gender/Age_data_#{gender_title} #{age_title}"] += [
              gender_age_count(gender: gender, age_range: age_range, coc_code: coc_code.to_sym),
              gender_age_percentage(gender: gender, age_range: age_range, coc_code: coc_code.to_sym) / 100,
            ]
          end
        end
      end
      rows
    end

    # Groups clients by their gender and age for a specific CoC code
    # @param coc_code [Symbol] The CoC code to group by, defaults to base_count_sym
    # @return [Hash] A hash mapping gender and age combinations to sets of client IDs
    private def gender_age_breakdowns(coc_code = base_count_sym)
      client_genders_and_ages[coc_code].group_by do |_, row|
        [
          row[:gender],
          row[:age],
        ]
      end
    end

    # Retrieves client IDs for a specific gender and age range
    # @param gender [Symbol] The gender type to filter by
    # @param age [Range] The age range to filter by
    # @param coc_code [Symbol] The CoC code to filter by, defaults to base_count_sym
    # @return [Set] Set of client IDs matching the specified criteria
    def client_ids_in_gender_age(gender, age, coc_code = base_count_sym)
      ids = Set.new
      age.to_a.each do |age_old|
        client_ids = gender_age_breakdowns(coc_code)[[gender_column_to_numeric(gender), age_old]]&.map(&:first)
        ids += client_ids if client_ids
      end
      ids
    end

    # Groups clients by their gender for a specific CoC code
    # @param coc_code [Symbol] The CoC code to group by, defaults to base_count_sym
    # @return [Hash] A hash mapping gender types to sets of client IDs
    private def gender_breakdowns(coc_code = base_count_sym)
      client_genders_and_ages[coc_code].group_by do |_, row|
        row[:gender]
      end
    end

    # Converts a gender column name to its numeric ID
    # @param column [Symbol] The gender column name to convert
    # @return [Integer] The numeric ID for the gender column
    private def gender_column_to_numeric(column)
      HudUtility2024.gender_id_to_field_name.detect { |_, l| l == column }.first
    end

    # Retrieves client IDs for a specific gender
    # @param column [Symbol] The gender type to filter by
    # @param coc_code [Symbol] The CoC code to filter by, defaults to base_count_sym
    # @return [Array] Array of client IDs with the specified gender
    def client_ids_in_gender(column, coc_code = base_count_sym)
      gender_breakdowns(coc_code)[gender_column_to_numeric(column)]&.map(&:first)
    end

    # Retrieves and caches client gender and age data
    # @return [Hash] A hash mapping CoC codes to client gender and age data
    def client_genders_and_ages
      @client_genders_and_ages ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        {}.tap do |clients|
          clients[base_count_sym] ||= {}
          available_coc_codes.each do |id, _|
            clients[id.to_sym] = {}
          end
          report_scope.joins(:client).order(first_date_in_program: :desc).
            distinct.
            pluck(:client_id, age_calculation, :first_date_in_program, *genders.keys.map { |col| c_t[col] }).
            each do |row|
              client_id, age, _, *gender_values = row
              client = genders.keys.zip(gender_values).to_h
              # HudUtility2024.gender_id_to_field_name includes multiple :GenderNone records. We are mapping
              # all of these to the id "8" so they all will be included in the Unknown Gender counts.
              gender = GrdaWarehouse::Hud::Client.gender_binary(client).presence || 8
              gender = 8 if gender.in?([9, 99])
              clients[base_count_sym][client_id] ||= {
                gender: gender,
                age: age,
              }
            end
          available_coc_codes.each do |coc_code|
            report_scope.joins(:client).order(first_date_in_program: :desc).
              distinct.in_enrollment_coc(coc_code: coc_code).
              pluck(:client_id, age_calculation, :first_date_in_program, *genders.keys.map { |col| c_t[col] }).
              each do |row|
                client_id, age, _, *gender_values = row
                client = genders.keys.zip(gender_values).to_h
                # HudUtility2024.gender_id_to_field_name includes multiple :GenderNone records. We are mapping
                # all of these to the id "8" so they all will be included in the Unknown Gender counts.
                gender = GrdaWarehouse::Hud::Client.gender_binary(client).presence || 8
                gender = 8 if gender.in?([9, 99])
                clients[coc_code.to_sym][client_id] ||= {
                  gender: gender,
                  age: age,
                }
              end
          end
        end
      end
    end
  end
end

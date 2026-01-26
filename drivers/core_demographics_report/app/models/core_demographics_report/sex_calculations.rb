###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module CoreDemographicsReport::SexCalculations
  extend ActiveSupport::Concern
  included do
    # Generates a hash of detail reports for sex data
    # @return [Hash] A hash containing report configurations for different sex categories
    def sex_detail_hash
      {}.tap do |hashes|
        sexes.each do |key, title|
          hashes["sex_#{key}"] = {
            title: "Sex - #{title}",
            headers: client_headers,
            columns: client_columns,
            scope: -> {
              report_scope.
                joins(:client, :enrollment).
                where(client_id: client_ids_in_sex(key)).
                distinct
            },
          }
        end
        age_categories.each do |age_key, age_title|
          sexes.each do |sex, sex_title|
            hashes["age_#{age_key}_sex_#{sex}"] = {
              title: "Age - #{age_title} #{sex_title}",
              headers: client_headers,
              columns: client_columns,
              scope: -> { report_scope.joins(:client, :enrollment).where(client_id: client_ids_in_sex_age(sex, age_key)).distinct },
            }
          end
        end
      end
    end

    # Counts the number of clients with a specific sex
    # @param type [Integer] The sex type to count (0=Female, 1=Male, 8=Client doesn't know, 9=Client prefers not to answer, 99=Data not collected)
    # @param coc_code [Symbol] The CoC code to filter by, defaults to base_count_sym
    # @return [Integer] The count of clients with the specified sex, masked if population is small
    def sex_count(type, coc_code = base_count_sym)
      mask_small_population(client_ids_in_sex(type, coc_code)&.count&.presence || 0)
    end

    # Calculates the percentage of clients with a specific sex
    # @param type [Integer] The sex type to calculate percentage for
    # @param coc_code [Symbol] The CoC code to filter by, defaults to base_count_sym
    # @return [Float] The percentage of clients with the specified sex
    def sex_percentage(type, coc_code = base_count_sym)
      total_count = mask_small_population(client_sexes_and_ages[coc_code].count)
      return 0 if total_count.zero?

      of_type = sex_count(type, coc_code)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    # Counts the number of clients with a specific sex and age range
    # @param sex [Integer] The sex type to count
    # @param age_range [Range] The age range to count
    # @param coc_code [Symbol] The CoC code to filter by, defaults to base_count_sym
    # @return [Integer] The count of clients with the specified sex and age range, masked if population is small
    def sex_age_count(sex:, age_range:, coc_code: base_count_sym)
      mask_small_population(client_ids_in_sex_age(sex, age_range, coc_code)&.count&.presence || 0)
    end

    # Calculates the percentage of clients with a specific sex and age range
    # @param sex [Integer] The sex type to calculate percentage for
    # @param age_range [Range] The age range to calculate percentage for
    # @param coc_code [Symbol] The CoC code to filter by, defaults to base_count_sym
    # @return [Float] The percentage of clients with the specified sex and age range
    def sex_age_percentage(sex:, age_range:, coc_code: base_count_sym)
      total_count = mask_small_population(client_sexes_and_ages[coc_code].count)
      return 0 if total_count.zero?

      of_type = sex_age_count(sex: sex, age_range: age_range, coc_code: coc_code)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    # Prepares sex and age data for export
    # @param rows [Hash] The hash to store the export data
    # @return [Hash] The updated rows hash with sex and age data
    def sex_data_for_export(rows)
      rows['_Sex Break'] ||= []
      rows['*Sex Breakdowns'] ||= []
      rows['*Sex Breakdowns'] += ['Sex', nil, 'Count', 'Percentage', nil]
      available_coc_codes.each do |coc_code|
        rows['*Sex Breakdowns'] += ["#{coc_code} Client"]
        rows['*Sex Breakdowns'] += ["#{coc_code} Percentage"]
      end
      rows['*Sex Breakdowns'] += [nil]
      sexes.each do |id, title|
        rows["_Sex Breakdowns_data_#{title}"] ||= []
        rows["_Sex Breakdowns_data_#{title}"] += [
          title,
          nil,
          sex_count(id),
          sex_percentage(id) / 100,
          nil,
        ]
        available_coc_codes.each do |coc_code|
          rows["_Sex Breakdowns_data_#{title}"] += [
            sex_count(id, coc_code.to_sym),
            sex_percentage(id, coc_code.to_sym) / 100,
          ]
        end
      end
      rows['_Sex/Age Breakdowns Break'] ||= []
      rows['*Sex/Age Breakdowns'] ||= []
      rows['*Sex/Age Breakdowns'] += ['Sex', 'Age Range', 'Count', 'Percentage', nil]
      available_coc_codes.each do |coc_code|
        rows['*Sex/Age Breakdowns'] += ["#{coc_code} Client"]
        rows['*Sex/Age Breakdowns'] += ["#{coc_code} Percentage"]
      end
      rows['*Sex/Age Breakdowns'] += [nil]
      sexes.each do |sex, sex_title|
        age_categories.each do |age_range, age_title|
          rows["_Sex/Age_data_#{sex_title} #{age_title}"] ||= []
          rows["_Sex/Age_data_#{sex_title} #{age_title}"] += [
            sex_title,
            age_title,
            sex_age_count(sex: sex, age_range: age_range),
            sex_age_percentage(sex: sex, age_range: age_range) / 100,
            nil,
          ]
          available_coc_codes.each do |coc_code|
            rows["_Sex/Age_data_#{sex_title} #{age_title}"] += [
              sex_age_count(sex: sex, age_range: age_range, coc_code: coc_code.to_sym),
              sex_age_percentage(sex: sex, age_range: age_range, coc_code: coc_code.to_sym) / 100,
            ]
          end
        end
      end
      rows
    end

    # Groups clients by their sex and age for a specific CoC code
    # @param coc_code [Symbol] The CoC code to group by, defaults to base_count_sym
    # @return [Hash] A hash mapping sex and age combinations to sets of client IDs
    private def sex_age_breakdowns(coc_code = base_count_sym)
      client_sexes_and_ages[coc_code].group_by do |_, row|
        [
          row[:sex],
          row[:age],
        ]
      end
    end

    # Retrieves client IDs for a specific sex and age range
    # @param sex [Integer] The sex type to filter by
    # @param age [Range] The age range to filter by
    # @param coc_code [Symbol] The CoC code to filter by, defaults to base_count_sym
    # @return [Set] Set of client IDs matching the specified criteria
    def client_ids_in_sex_age(sex, age, coc_code = base_count_sym)
      ids = Set.new
      age.to_a.each do |age_old|
        client_ids = sex_age_breakdowns(coc_code)[[sex, age_old]]&.map(&:first)
        ids += client_ids if client_ids
      end
      ids
    end

    # Groups clients by their sex for a specific CoC code
    # @param coc_code [Symbol] The CoC code to group by, defaults to base_count_sym
    # @return [Hash] A hash mapping sex types to sets of client IDs
    private def sex_breakdowns(coc_code = base_count_sym)
      client_sexes_and_ages[coc_code].group_by do |_, row|
        row[:sex]
      end
    end

    # Retrieves client IDs for a specific sex
    # @param sex_type [Integer] The sex type to filter by
    # @param coc_code [Symbol] The CoC code to filter by, defaults to base_count_sym
    # @return [Array] Array of client IDs with the specified sex
    def client_ids_in_sex(sex_type, coc_code = base_count_sym)
      sex_breakdowns(coc_code)[sex_type]&.map(&:first)
    end

    # Retrieves and caches client sex and age data
    # @return [Hash] A hash mapping CoC codes to client sex and age data
    def client_sexes_and_ages
      @client_sexes_and_ages ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        {}.tap do |clients|
          clients[base_count_sym] ||= {}
          available_coc_codes.each do |id, _|
            clients[id.to_sym] = {}
          end
          report_scope.joins(:client).order(first_date_in_program: :desc).
            distinct.
            pluck(:client_id, age_calculation, :first_date_in_program, c_t[:Sex]).
            each do |row|
              client_id, age, _, sex_value = row
              # Map nil to 99 (Data not collected), preserve 8, 9, 99 as separate values
              sex = sex_value.presence || 99
              clients[base_count_sym][client_id] ||= {
                sex: sex,
                age: age,
              }
            end
          available_coc_codes.each do |coc_code|
            report_scope.joins(:client).order(first_date_in_program: :desc).
              distinct.in_enrollment_coc(coc_code: coc_code).
              pluck(:client_id, age_calculation, :first_date_in_program, c_t[:Sex]).
              each do |row|
                client_id, age, _, sex_value = row
                # Map nil to 99 (Data not collected), preserve 8, 9, 99 as separate values
                sex = sex_value.presence || 99
                clients[coc_code.to_sym][client_id] ||= {
                  sex: sex,
                  age: age,
                }
              end
          end
        end
      end
    end
  end
end

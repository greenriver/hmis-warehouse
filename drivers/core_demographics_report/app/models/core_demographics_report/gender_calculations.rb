###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module
  CoreDemographicsReport::GenderCalculations
  extend ActiveSupport::Concern
  included do
    def gender_detail_hash
      {}.tap do |hashes|
        genders.each do |key, title|
          hashes["gender_#{key}"] = {
            title: "Gender - #{title}",
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client, :enrollment).where(client_id: client_ids_in_gender(key)).distinct },
          }
        end
      end
    end

    def gender_count(type, coc_code = base_count_sym)
      mask_small_population(gender_breakdowns(coc_code)[gender_column_to_numeric(type)]&.count&.presence || 0)
    end

    def gender_percentage(type, coc_code = base_count_sym)
      total_count = mask_small_population(client_genders_and_ages[coc_code].count)
      return 0 if total_count.zero?

      of_type = gender_count(type, coc_code)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    def gender_age_count(gender:, age_range:, coc_code: base_count_sym)
      population_count = age_range.to_a.map do |age|
        gender_age_breakdowns(coc_code)[[gender_column_to_numeric(gender), age]]&.count&.presence || 0
      end.sum
      mask_small_population(population_count)
    end

    def gender_age_percentage(gender:, age_range:, coc_code: base_count_sym)
      total_count = mask_small_population(client_genders_and_ages[coc_code].count)
      return 0 if total_count.zero?

      of_type = gender_age_count(gender: gender, age_range: age_range, coc_code: coc_code)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

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

    private def gender_age_breakdowns(coc_code = base_count_sym)
      client_genders_and_ages[coc_code].group_by do |_, row|
        [
          row[:gender],
          row[:age],
        ]
      end
    end

    def client_ids_in_gender_age(gender, age)
      ids = Set.new
      age.to_a.each do |age_old|
        client_ids = gender_age_breakdowns[[gender_column_to_numeric(gender), age_old]]&.map(&:first)
        ids += client_ids if client_ids
      end
      ids
    end

    # Grouped by numeric gender
    private def gender_breakdowns(coc_code = base_count_sym)
      client_genders_and_ages[coc_code].group_by do |_, row|
        row[:gender]
      end
    end

    private def gender_column_to_numeric(column)
      HudUtility2024.gender_id_to_field_name.detect { |_, l| l == column }.first
    end

    def client_ids_in_gender(column, coc_code = base_count_sym)
      gender_breakdowns(coc_code)[gender_column_to_numeric(column)]&.map(&:first)
    end

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
              distinct.in_coc(coc_code: coc_code).
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

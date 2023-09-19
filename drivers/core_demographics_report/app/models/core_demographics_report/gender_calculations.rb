###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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

    def gender_count(type)
      mask_small_population(gender_breakdowns[gender_column_to_numeric(type)]&.count&.presence || 0)
    end

    def gender_percentage(type)
      total_count = mask_small_population(client_genders_and_ages.count)
      return 0 if total_count.zero?

      of_type = gender_count(type)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    def gender_age_count(gender:, age_range:)
      age_range.to_a.map do |age|
        mask_small_population(gender_age_breakdowns[[gender_column_to_numeric(gender), age]]&.count&.presence || 0)
      end.sum
    end

    def gender_age_percentage(gender:, age_range:)
      total_count = mask_small_population(client_genders_and_ages.count)
      return 0 if total_count.zero?

      of_type = gender_age_count(gender: gender, age_range: age_range)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    def gender_data_for_export(rows)
      rows['_Gender Break'] ||= []
      rows['*Gender Breakdowns'] ||= []
      rows['*Gender Breakdowns'] += ['Gender', nil, 'Count', 'Percentage', nil]
      genders.each do |id, title|
        rows["_Gender Breakdowns_data_#{title}"] ||= []
        rows["_Gender Breakdowns_data_#{title}"] += [
          title,
          nil,
          gender_count(id),
          gender_percentage(id) / 100,
          nil,
        ]
      end
      rows['_Gender/Age Breakdowns Break'] ||= []
      rows['*Gender/Age Breakdowns'] ||= []
      rows['*Gender/Age Breakdowns'] += ['Gender', 'Age Range', 'Count', 'Percentage', nil]
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
        end
      end
      rows
    end

    private def gender_age_breakdowns
      @gender_age_breakdowns ||= client_genders_and_ages.group_by do |_, row|
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
    private def gender_breakdowns
      @gender_breakdowns ||= client_genders_and_ages.group_by do |_, row|
        row[:gender]
      end
    end

    private def gender_column_to_numeric(column)
      HudUtility2024.gender_id_to_field_name.detect { |_, l| l == column }.first
    end

    def client_ids_in_gender(column)
      gender_breakdowns[gender_column_to_numeric(column)]&.map(&:first)
    end

    def client_genders_and_ages
      @client_genders_and_ages ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        {}.tap do |clients|
          report_scope.joins(:client).order(first_date_in_program: :desc).
            distinct.
            pluck(:client_id, age_calculation, :first_date_in_program, *genders.keys.map { |col| c_t[col] }).
            each do |row|
              client_id, age, _, *gender_values = row
              client = genders.keys.zip(gender_values).to_h
              clients[client_id] ||= {
                gender: GrdaWarehouse::Hud::Client.gender_binary(client).presence || 99,
                age: age,
              }
            end
        end
      end
    end
  end
end

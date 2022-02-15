###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module
  CoreDemographicsReport::GenderCalculations
  extend ActiveSupport::Concern
  included do
    def gender_detail_hash
      {}.tap do |hashes|
        HUD.genders.each do |key, title|
          hashes["gender_#{key}"] = {
            title: "Gender - #{title}",
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client).where(client_id: client_ids_in_gender(key)).distinct },
          }
        end
      end
    end

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

    def gender_data_for_export(rows)
      rows['_Gender Break'] ||= []
      rows['*Gender Breakdowns'] ||= []
      rows['*Gender Breakdowns'] += ['Gender', 'Count', 'Percentage', nil, nil]
      HUD.genders.each do |id, title|
        rows["_Gender Breakdowns_data_#{title}"] ||= []
        rows["_Gender Breakdowns_data_#{title}"] += [
          title,
          gender_count(id),
          gender_percentage(id) / 100,
          nil,
          nil,
        ]
      end
      rows['_Gender/Age Beakdowns Break'] ||= []
      rows['*Gender/Age Beakdowns'] ||= []
      rows['*Gender/Age Beakdowns'] += ['Gender', 'Age Range', 'Count', 'Percentage', nil]
      HUD.genders.each do |gender, gender_title|
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
        client_ids = gender_age_breakdowns[[gender, age_old]]&.map(&:first)
        ids += client_ids if client_ids
      end
      ids
    end

    private def gender_breakdowns
      @gender_breakdowns ||= client_genders_and_ages.group_by do |_, row|
        row[:gender]
      end
    end

    def client_ids_in_gender(gender)
      gender_breakdowns[gender]&.map(&:first)
    end

    private def client_genders_and_ages
      @client_genders_and_ages ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        {}.tap do |clients|
          report_scope.joins(:client).order(first_date_in_program: :desc).
            distinct.
            pluck(:client_id, age_calculation, c_t[:Female], c_t[:Male], c_t[:NoSingleGender], c_t[:Transgender], c_t[:Questioning], c_t[:GenderNone], :first_date_in_program).
            each do |client_id, age, female, male, no_single_gender, transgender, questioning, gender_none, _|
              genders = {
                Male: male,
                Female: female,
                NoSingleGender: no_single_gender,
                Transgender: transgender,
                Questioning: questioning,
                GenderNone: gender_none,
              }
              clients[client_id] ||= {
                gender: GrdaWarehouse::Hud::Client.gender_binary(genders).presence || 99,
                age: age,
              }
            end
        end
      end
    end
  end
end

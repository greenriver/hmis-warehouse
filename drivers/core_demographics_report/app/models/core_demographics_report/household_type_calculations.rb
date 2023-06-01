###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module
  CoreDemographicsReport::HouseholdTypeCalculations
  extend ActiveSupport::Concern
  included do
    def household_detail_hash
      {}.tap do |hashes|
        available_household_types.invert.each do |key, title|
          # HoH counts
          hashes["household_type_#{key}"] = {
            title: "Household Type - #{title}",
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client, :enrollment).where(client_id: hoh_ids_in_household_type(key)).distinct },
          }
          # All client counts
          hashes["household_type_client_#{key}"] = {
            title: "Household Type - #{title}",
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client, :enrollment).where(client_id: client_ids_in_household_type(key)).distinct },
          }
        end
      end
    end

    def household_type_hoh_count(type)
      hoh_households[type]&.count&.presence || 0
    end

    def household_type_hoh_percentage(type)
      total_count = hoh_count
      return 0 if total_count.zero?

      of_type = household_type_hoh_count(type)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    def household_type_client_count(type)
      client_households[type]&.count&.presence || 0
    end

    def household_type_client_percentage(type)
      total_count = total_client_count
      return 0 if total_count.zero?

      of_type = household_type_client_count(type)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    def household_type_data_for_export(rows)
      rows['_Household Types'] ||= []
      rows['*Household Types'] ||= []
      rows['*Household Types'] += ['Household Type', 'Count', 'Percentage', nil, nil]
      @filter.available_household_types.invert.each do |id, title|
        rows["_Household Types_data_#{title}"] ||= []
        rows["_Household Types_data_#{title}"] += [
          title,
          household_type_hoh_count(id),
          household_type_hoh_percentage(id) / 100,
          nil,
        ]
      end
      rows
    end

    private def client_ids_in_household_type(key)
      client_households[key]
    end

    private def hoh_ids_in_household_type(key)
      hoh_households[key]
    end

    def available_household_types
      @filter.available_household_types.merge('Youth Only' => :unaccompanied_youth)
    end

    private def hoh_households
      @hoh_households ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        {}.tap do |clients|
          hoh_scope.
            distinct.
            order(first_date_in_program: :desc).
            pluck(:client_id, :first_date_in_program).
            each do |client_id, _|
              clients[:all] ||= Set.new
              clients[:all] << client_id
            end
          hoh_scope.adult_only_households.
            distinct.
            order(first_date_in_program: :desc).
            pluck(:client_id, :first_date_in_program).
            each do |client_id, _|
              clients[:without_children] ||= Set.new
              clients[:without_children] << client_id
            end
          hoh_scope.adults_with_children.
            distinct.
            order(first_date_in_program: :desc).
            pluck(:client_id, :first_date_in_program).
            each do |client_id, _|
              clients[:with_children] ||= Set.new
              clients[:with_children] << client_id
            end
          hoh_scope.child_only_households.
            distinct.
            order(first_date_in_program: :desc).
            pluck(:client_id, :first_date_in_program).
            each do |client_id, _|
              clients[:only_children] ||= Set.new
              clients[:only_children] << client_id
            end
          hoh_scope.unaccompanied_youth.
            distinct.
            order(first_date_in_program: :desc).
            pluck(:client_id, :first_date_in_program).
            each do |client_id, _|
              clients[:unaccompanied_youth] ||= Set.new
              clients[:unaccompanied_youth] << client_id
            end
        end
      end
    end

    private def client_households
      @client_households ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        {}.tap do |clients|
          report_scope.distinct.
            order(first_date_in_program: :desc).
            pluck(:client_id, :first_date_in_program).
            each do |client_id, _|
              clients[:all] ||= Set.new
              clients[:all] << client_id
            end
          report_scope.adult_only_households.
            distinct.
            order(first_date_in_program: :desc).
            pluck(:client_id, :first_date_in_program).
            each do |client_id, _|
              clients[:without_children] ||= Set.new
              clients[:without_children] << client_id
            end
          report_scope.adults_with_children.
            distinct.
            order(first_date_in_program: :desc).
            pluck(:client_id, :first_date_in_program).
            each do |client_id, _|
              clients[:with_children] ||= Set.new
              clients[:with_children] << client_id
            end
          report_scope.child_only_households.
            distinct.
            order(first_date_in_program: :desc).
            pluck(:client_id, :first_date_in_program).
            each do |client_id, _|
              clients[:only_children] ||= Set.new
              clients[:only_children] << client_id
            end
          report_scope.unaccompanied_youth.
            distinct.
            order(first_date_in_program: :desc).
            pluck(:client_id, :first_date_in_program).
            each do |client_id, _|
              clients[:unaccompanied_youth] ||= Set.new
              clients[:unaccompanied_youth] << client_id
            end
        end
      end
    end
  end
end

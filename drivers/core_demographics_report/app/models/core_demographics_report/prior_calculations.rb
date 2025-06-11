###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module
  CoreDemographicsReport::PriorCalculations
  extend ActiveSupport::Concern
  included do
    # Generates a hash of detail reports for prior living situation data
    # @return [Hash] A hash containing report configurations for different prior living situation categories
    def prior_detail_hash
      {}.tap do |hashes|
        ::HudUtility2024.times_homeless_options.each do |id, title|
          hashes["prior_times_#{id}"] = {
            title: "Number of Times on the Streets, ES, or SH in The Past 3 Years #{title}",
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client, :enrollment).where(client_id: client_ids_in_prior_times(id)).distinct },
          }
        end
        ::HudUtility2024.month_categories.each do |id, title|
          hashes["prior_months_#{id}"] = {
            title: "Number of Months on the Streets, ES, or SH in The Past 3 Years #{title}",
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client, :enrollment).where(client_id: client_ids_in_prior_months(id)).distinct },
          }
        end
        ::HudUtility2024.living_situations.each do |id, title|
          hashes["prior_situation_#{id}"] = {
            title: "Prior Living Situation #{title}",
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client, :enrollment).where(client_id: client_ids_in_prior_situation(id)).distinct },
          }
        end
      end
    end

    # Counts the number of clients with a specific number of times homeless
    # @param type [Integer] The number of times homeless to count, using HUD-defined times_homeless_options
    # @return [Integer] The count of clients with the specified number of times homeless, masked if population is small
    def times_on_street_count(type)
      mask_small_population(times_on_street_breakdowns[type]&.count&.presence || 0)
    end

    # Calculates the percentage of clients with a specific number of times homeless
    # @param type [Integer] The number of times homeless to calculate percentage for, using HUD-defined times_homeless_options
    # @return [Float] The percentage of clients with the specified number of times homeless
    def times_on_street_percentage(type)
      total_count = mask_small_population(client_entry_data.count)
      return 0 if total_count.zero?

      of_type = times_on_street_count(type)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    # Groups clients by their number of times homeless
    # @return [Hash] A hash mapping HUD-defined times_homeless_options to sets of client IDs
    private def times_on_street_breakdowns
      @times_on_street_breakdowns ||= client_entry_data.group_by do |_, row|
        row[:times]
      end
    end

    # Retrieves client IDs for a specific number of times homeless
    # @param key [Integer] The number of times homeless to filter by, using HUD-defined times_homeless_options
    # @return [Array] Array of client IDs with the specified number of times homeless
    private def client_ids_in_prior_times(key)
      times_on_street_breakdowns[key]&.map(&:first)
    end

    # Counts the number of clients with a specific number of months homeless
    # @param type [Integer] The number of months homeless to count
    # @return [Integer] The count of clients with the specified number of months homeless, masked if population is small
    def months_on_street_count(type)
      mask_small_population(months_on_street_breakdowns[type]&.count&.presence || 0)
    end

    # Calculates the percentage of clients with a specific number of months homeless
    # @param type [Integer] The number of months homeless to calculate percentage for
    # @return [Float] The percentage of clients with the specified number of months homeless
    def months_on_street_percentage(type)
      total_count = mask_small_population(client_entry_data.count)
      return 0 if total_count.zero?

      of_type = months_on_street_count(type)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    # Groups clients by their number of months homeless
    # @return [Hash] A hash mapping number of months homeless to sets of client IDs
    private def months_on_street_breakdowns
      @months_on_street_breakdowns ||= client_entry_data.group_by do |_, row|
        row[:months]
      end
    end

    # Retrieves client IDs for a specific number of months homeless
    # @param key [Integer] The number of months homeless to filter by
    # @return [Array] Array of client IDs with the specified number of months homeless
    private def client_ids_in_prior_months(key)
      months_on_street_breakdowns[key]&.map(&:first)
    end

    # Counts the number of clients with a specific prior living situation
    # @param type [Integer] The prior living situation to count
    # @return [Integer] The count of clients with the specified prior living situation, masked if population is small
    def prior_living_situations_count(type)
      mask_small_population(prior_living_situations_breakdowns[type]&.count&.presence || 0)
    end

    # Calculates the percentage of clients with a specific prior living situation
    # @param type [Integer] The prior living situation to calculate percentage for
    # @return [Float] The percentage of clients with the specified prior living situation
    def prior_living_situations_percentage(type)
      total_count = mask_small_population(client_entry_data.count)
      return 0 if total_count.zero?

      of_type = prior_living_situations_count(type)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    # Retrieves client IDs for a specific prior living situation
    # @param key [Integer] The prior living situation to filter by
    # @return [Array] Array of client IDs with the specified prior living situation
    private def client_ids_in_prior_situation(key)
      prior_living_situations_breakdowns[key]&.map(&:first)
    end

    # Prepares prior living situation data for export
    # @param rows [Hash] The hash to store the export data
    # @return [Hash] The updated rows hash with prior living situation data
    def priors_data_for_export(rows)
      rows['_Number of Times on the Streets, ES, or SH in The Past 3 Years break'] ||= []
      rows['*Number of Times on the Streets, ES, or SH in The Past 3 Years'] ||= []
      rows['*Number of Times Response'] ||= []
      rows['*Number of Times Response'] += ['Times', nil, 'Count', 'Percentage', nil]
      ::HudUtility2024.times_homeless_options.each do |id, title|
        rows["_Number of Times Response_data_#{title}"] ||= []
        rows["_Number of Times Response_data_#{title}"] += [
          title,
          nil,
          times_on_street_count(id),
          times_on_street_percentage(id) / 100,
        ]
      end
      rows['_Number of Months on the Streets, ES, or SH in The Past 3 Years break'] ||= []
      rows['*Number of Months on the Streets, ES, or SH in The Past 3 Years'] ||= []
      rows['*Number of Months Response'] ||= []
      rows['*Number of Months Response'] += ['Time', nil, 'Count', 'Percentage', nil]
      ::HudUtility2024.month_categories.each do |id, title|
        rows["_Number of Months_data_#{title}"] ||= []
        rows["_Number of Months_data_#{title}"] += [
          title,
          nil,
          months_on_street_count(id),
          months_on_street_percentage(id) / 100,
        ]
      end
      rows['_Prior Living Situation break'] ||= []
      rows['*Prior Living Situation'] ||= []
      rows['*Prior Living Situation'] += ['Situation', nil, 'Count', 'Percentage', nil]
      ::HudUtility2024.living_situations.each do |id, title|
        rows["_Prior Living Situation_data_#{title}"] ||= []
        rows["_Prior Living Situation_data_#{title}"] += [
          title,
          nil,
          prior_living_situations_count(id),
          prior_living_situations_percentage(id) / 100,
        ]
      end
      rows
    end

    # Groups clients by their prior living situation
    # @return [Hash] A hash mapping prior living situations to sets of client IDs
    private def prior_living_situations_breakdowns
      @prior_living_situations_breakdowns ||= client_entry_data.group_by do |_, row|
        row[:living_situation]
      end
    end

    # Retrieves and caches client entry data including times homeless, months homeless, and living situation
    # @return [Hash] A hash mapping client IDs to their entry data
    private def client_entry_data
      @client_entry_data ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        {}.tap do |clients|
          report_scope.joins(:enrollment).order(first_date_in_program: :desc).
            distinct.
            pluck(:client_id, e_t[:TimesHomelessPastThreeYears], e_t[:MonthsHomelessPastThreeYears], e_t[:LivingSituation], :first_date_in_program).
            each do |client_id, times_homeless, months_homeless, living_situation, _|
              clients[client_id] ||= {
                times: times_homeless,
                months: months_homeless,
                living_situation: living_situation,
              }
            end
        end
      end
    end
  end
end

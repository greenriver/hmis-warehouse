###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudChronicDefinition
  extend ActiveSupport::Concern
  # TODO: Investigate if we need to integrate LivingSituation (3.917.1) into the chronic calculation
  # per the updated 2020 Reporting Glossary

  # added as instance methods
  included do
    attr_accessor :hud_chronic_data

    has_many :hud_chronics, class_name: 'GrdaWarehouse::HudChronic', inverse_of: :client

    has_many :hud_chronics_in_range, ->(range) do
      where(date: range)
    end, class_name: 'GrdaWarehouse::HudChronic', inverse_of: :client

    # HUD Chronic:
    # Client must be disabled
    # Must be homeless for all of the last 12 months
    #   OR
    # Must be homeless 12 of the last 36 with 4 episodes
    def hud_chronic?(on_date: Date.current, scope: source_enrollments, disability_join: :source_enrollment_disabilities, client_join: :destination_client)
      @hud_chronic_data = {}
      return unless disabled?(on_date: on_date, client_id: id, scope: scope, disability_join: disability_join, client_join: client_join)

      if months_12_homeless?(on_date: on_date, scope: scope)
        @hud_chronic_data[:trigger] = 'All 12 of the last 12 months homeless'
        true
      elsif times_4_homeless?(on_date: on_date, scope: scope)
        @hud_chronic_data[:trigger] = 'Four or more episodes of homelessness in the past three years and '
        if months_homeless_past_three_years_more_than_12?(on_date: on_date, scope: scope)
          @hud_chronic_data[:trigger] += '12+ months homeless'
          true
        elsif total_months_homeless_more_than_12?(on_date: on_date, scope: scope)
          @hud_chronic_data[:trigger] += '12+ month on the street or in ES or SH'
          true
        end
      end
    end

    # Has is been at least 12 months since client was
    # first homeless to on_date?
    def months_12_homeless?(on_date:, scope: source_enrollments)
      @hud_chronic_data ||= {}
      date_to_street = scope.in_project_type(HudUtility2024.chronic_project_types).
        ongoing(on_date: on_date).
        order(entry_date: :desc).
        first&.DateToStreetESSH
      return false unless date_to_street

      # how many unique months between data_to_street and on_date
      months_on_street = (on_date.year * 12 + on_date.month) - (date_to_street.year * 12 + date_to_street.month) + 1 # plus one for current month
      hud_chronic_data[:months_in_last_three_years] = (months_on_street > 36 ? 36 : months_on_street)
      months_on_street >= 12
    end

    # Has the client been homeless 4 times within the past
    # 3 years?
    def times_4_homeless?(on_date:, scope: source_enrollments)
      times_on_street = scope.in_project_type(HudUtility2024.chronic_project_types).
        ongoing(on_date: on_date).
        order(entry_date: :desc).
        first&.TimesHomelessPastThreeYears
      times_on_street == 4
    end

    # Has the client been homeless for more than 12 months
    # in the past 3 years
    #
    # MonthsHomelessPastThreeYears
    # ----------------------------
    # 8   Client doesn't know
    # 9   Client refused
    # 99  Data not collected
    # 101 1
    # 102 2
    # 103 3
    # 104 4
    # 105 5
    # 106 6
    # 107 7
    # 108 8
    # 109 9
    # 110 10
    # 111 11
    # 112 12
    # 113 More than 12 months

    def months_homeless_past_three_years_more_than_12?(on_date:, scope: source_enrollments)
      months_on_street = scope.in_project_type(HudUtility2024.chronic_project_types).
        ongoing(on_date: on_date).
        order(entry_date: :desc).
        first&.MonthsHomelessPastThreeYears
      return false unless months_on_street

      # 8, 9, 99 are missing, reused etc.
      hud_chronic_data[:months_in_last_three_years] = months_on_street - 100
      months_on_street > 111
    end

    # Has the client been homeless more than 12 months
    def total_months_homeless_more_than_12?(on_date:, scope: source_enrollments)
      entry = scope.in_project_type(HudUtility2024.chronic_project_types).
        ongoing(on_date: on_date).
        order(entry_date: :desc).first
      months_on_street = entry&.MonthsHomelessPastThreeYears
      return false unless months_on_street
      return false unless months_on_street > 100

      months_in_project = (on_date.year * 12 + on_date.month) - (entry.entry_date.year * 12 + entry.entry_date.month) + 1
      months_homeless = (months_on_street - 100) + months_in_project
      hud_chronic_data[:months_in_last_three_years] = (months_homeless > 36 ? 36 : months_homeless)
      months_homeless >= 12
    end

    def disabled?(on_date:, client_id: id, scope: source_enrollments, disability_join: :source_enrollment_disabilities, client_join: :destination_client)
      @disabled_clients ||= Rails.cache.fetch('chronically_disabled_clients', expires_in: 8.hours) do
        d_ids = GrdaWarehouse::Hud::Client.chronically_disabled(on_date, join: disability_join).pluck(:id)
        c_ids = scope.joins(client_join).pluck(c_t[:id])
        # return the ids of clients who have a disabling condition and are also in the enrollment
        d_ids & c_ids
      end
      @disabled_clients.include?(client_id)
    end
  end
end

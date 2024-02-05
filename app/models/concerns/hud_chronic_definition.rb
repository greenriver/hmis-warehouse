###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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
    def hud_chronic?(on_date: Date.current, scope: nil)
      @hud_chronic_data = {}

      return unless disabled?(on_date: on_date, client_id: id, scope: scope)

      if months_12_homeless?(on_date: on_date, scope: scope)
        @hud_chronic_data[:trigger] = 'All 12 of the last 12 months homeless'
        return true
      elsif times_4_homeless?(on_date: on_date, scope: scope)
        @hud_chronic_data[:trigger] = 'Four or more episodes of homelessness in the past three years and '
        if months_homeless_past_three_years_more_than_12?(on_date: on_date, scope: scope)
          @hud_chronic_data[:trigger] += '12+ months homeless'
          return true
        elsif total_months_homeless_more_than_12?(on_date: on_date, scope: scope)
          @hud_chronic_data[:trigger] += '12+ month on the street or in ES or SH'
          return true
        end
      end
    end

    # Has is been at least 12 months since client was
    # first homeless to on_date?
    def months_12_homeless?(on_date:, scope:)
      scope = source_enrollments if scope.nil?
      @hud_chronic_data ||= {}
      date_to_street = scope.with_project_type(HudUtility2024.chronic_project_types).
        ongoing(on_date: on_date).
        # Using the earliest DateToStreetESSH for any open enrollment in a homeless project
        where.not(DateToStreetESSH: nil).
        order(DateToStreetESSH: :asc).
        first&.DateToStreetESSH
      return false unless date_to_street

      # how many unique months between data_to_street and on_date
      months_on_street = (on_date.year * 12 + on_date.month) - (date_to_street.year * 12 + date_to_street.month) + 1 # plus one for current month
      hud_chronic_data[:months_in_last_three_years] = (months_on_street > 36 ? 36 : months_on_street)
      months_on_street >= 12
    end

    # Has the client been homeless 4 times within the past
    # 3 years? (3.917.4)
    def times_4_homeless?(on_date:, scope:)
      scope = source_enrollments if scope.nil?
      scope.with_project_type(HudUtility2024.chronic_project_types).
        ongoing(on_date: on_date).
        # Look for any open enrollment where the client has been homeless 4 or more times
        where(TimesHomelessPastThreeYears: 4).
        exists?
    end

    # Has the client been homeless for more than 12 months
    # in the past 3 years
    #
    # MonthsHomelessPastThreeYears (3.917.5)
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

    def months_homeless_past_three_years_more_than_12?(on_date:, scope:)
      scope = source_enrollments if scope.nil?
      months_on_street = scope.with_project_type(HudUtility2024.chronic_project_types).
        ongoing(on_date: on_date).
        # Only return records where the client answered the question
        where.not(MonthsHomelessPastThreeYears: nil).
        order(MonthsHomelessPastThreeYears: :desc).
        first&.MonthsHomelessPastThreeYears
      return false unless months_on_street

      # 8, 9, 99 are missing, reused etc.
      hud_chronic_data[:months_in_last_three_years] = months_on_street - 100
      months_on_street > 111
    end

    # Has the client been homeless more than 12 months (3.917.5)
    def total_months_homeless_more_than_12?(on_date:, scope:)
      scope = source_enrollments if scope.nil?
      entry = scope.with_project_type(HudUtility2024.chronic_project_types).
        ongoing(on_date: on_date).
        # Only return records where the client answered the question
        where.not(MonthsHomelessPastThreeYears: nil).
        order(MonthsHomelessPastThreeYears: :desc).first
      months_on_street = entry&.MonthsHomelessPastThreeYears
      return false unless months_on_street
      return false unless months_on_street > 100

      months_in_project = (on_date.year * 12 + on_date.month) - (entry.entry_date.year * 12 + entry.entry_date.month) + 1
      months_homeless = (months_on_street - 100) + months_in_project
      hud_chronic_data[:months_in_last_three_years] = (months_homeless > 36 ? 36 : months_homeless)
      months_homeless >= 12
    end

    # Scope must be a set of source enrollments.  If provided it is used to limit the source of the disability response
    # NOTE: providing a scope will cause an extra SQL query
    # client_id is always expected to be a destination client ID
    def disabled?(on_date:, client_id: id, scope: nil)
      @disabled_clients ||= Rails.cache.fetch('chronically_disabled_clients', expires_in: 8.hours) do
        GrdaWarehouse::Hud::Client.destination.chronically_disabled(on_date).pluck(:id).to_set
      end
      disabled = @disabled_clients.include?(client_id)
      return false unless disabled
      return true if scope.nil?

      # at this point, the destination client is considered to have a disabling condition,
      # but we were given a scope, and need to confirm the source of the condition is within the scope
      scope.where(id: GrdaWarehouse::Hud::Client.destination.chronically_disabled(on_date).select(e_t[:id])).exists?
    end
  end
end

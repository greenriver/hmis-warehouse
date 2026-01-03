# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Required concerns:
#   HudReports::Ages
#   HudReports:Households
#
# Required accessors:
#   a_t: Arel Type for the universe model
#
# Required universe fields:
#   veteran_status: Integer (HUD yes/no/reasons for missing data)
#   chronic_status: Boolean
#
module HudReports::Veterans
  extend ActiveSupport::Concern

  included do
    private def veteran_clause
      adult_clause.and(a_t[:veteran_status].eq(1))
    end

    # Note: household_adults is normally provided by HudReports::Households.
    # This fallback allows Veterans logic to work without the full Households concern overhead.
    # We define it only if it is not already defined by another included concern.
    unless method_defined?(:household_adults)
      private def household_adults(universe_client)
        return [] unless universe_client.respond_to?(:household_members) && universe_client.household_members.present?

        date = [universe_client.first_date_in_program, @report.start_date].max
        universe_client.household_members.select do |member|
          next false if member['dob'].blank?

          age = GrdaWarehouse::Hud::Client.age(date: date, dob: member['dob'].to_date)
          age.present? && age >= 18
        end
      end
    end

    private def household_veterans_chronically_homeless?(universe_client)
      return universe_client.hh_any_veteran_chronic == true if universe_client.respond_to?(:hh_any_veteran_chronic)

      adults = household_adults(universe_client)
      veterans = household_veterans(adults)
      household_chronically_homeless_clients(veterans).any?
    end

    private def household_veterans_non_chronically_homeless?(universe_client)
      return universe_client.hh_any_veteran_non_chronic == true if universe_client.respond_to?(:hh_any_veteran_non_chronic)

      adults = household_adults(universe_client)
      veterans = household_veterans(adults)
      household_non_chronically_homeless_clients(veterans).any?
    end

    private def all_household_adults_veterans?(universe_client)
      # No pre-computed flag for "all adults are veterans", but we can keep the legacy check
      # or add one if needed. For now, we'll keep the legacy check but check if we have data.
      return false if universe_client.respond_to?(:household_members) && universe_client.household_members.blank? && universe_client.respond_to?(:hh_ctx)

      household_adults(universe_client).all? do |member|
        member['veteran_status'] == 1
      end
    end

    private def all_household_adults_non_veterans?(universe_client)
      return universe_client.hh_all_adult_non_veteran == true if universe_client.respond_to?(:hh_all_adult_non_veteran)

      household_adults(universe_client).all? do |member|
        member['veteran_status']&.zero?
      end
    end

    # accepts a household_members cell from clients
    private def household_veterans(household_members)
      return [] unless household_members

      household_members.select do |member|
        member['veteran_status'] == 1
      end
    end

    private def household_non_veterans(household_members)
      return [] unless household_members

      household_members.select do |member|
        member['veteran_status']&.zero?
      end
    end

    private def household_adults_refused_veterans(universe_client)
      return [] if universe_client.respond_to?(:hh_any_adult_refused_veteran) && universe_client.hh_any_adult_refused_veteran == false

      household_adults(universe_client).select do |member|
        member['veteran_status']&.in?([8, 9])
      end
    end

    private def household_adults_missing_veterans(universe_client)
      return [] if universe_client.respond_to?(:hh_any_adult_missing_veteran) && universe_client.hh_any_adult_missing_veteran == false

      household_adults(universe_client).select do |member|
        member['veteran_status'] == 99
      end
    end

    private def household_chronically_homeless_clients(household_members)
      return [] unless household_members

      household_members.select do |member|
        member['chronic_status'] == true
      end
    end

    private def household_non_chronically_homeless_clients(household_members)
      return [] unless household_members

      household_members.select do |member|
        member['chronic_status'] == false
      end
    end
  end
end

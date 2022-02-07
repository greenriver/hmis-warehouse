###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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

    private def household_veterans_chronically_homeless?(universe_client)
      adults = household_adults(universe_client)
      veterans = household_veterans(adults)
      household_chronically_homeless_clients(veterans).any?
    end

    private def household_veterans_non_chronically_homeless?(universe_client)
      adults = household_adults(universe_client)
      veterans = household_veterans(adults)
      household_non_chronically_homeless_clients(veterans).any?
    end

    private def all_household_adults_veterans?(universe_client)
      household_adults(universe_client).all? do |member|
        member['veteran_status'] == 1
      end
    end

    private def all_household_adults_non_veterans?(universe_client)
      household_adults(universe_client).all? do |member|
        member['veteran_status'].zero?
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
        member['veteran_status'].zero?
      end
    end

    private def household_adults_refused_veterans(universe_client)
      household_adults(universe_client).select do |member|
        member['veteran_status'].in?([8, 9])
      end
    end

    private def household_adults_missing_veterans(universe_client)
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

###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Single source of truth for the configurable columns in the client dashboard
# demographic table. The header and the body rows both iterate the same list so
# they cannot drift apart.
#
# Config controls visibility only; order always comes from ALL.
module GrdaWarehouse
  class ClientDemographicColumns
    CONFIG_KEY = :client_demographic_columns

    # Canonical display order.
    ALL = [
      { key: 'name', label: 'Name', tooltip: :name, width: '15em' },
      { key: 'ssn', label: 'SSN', tooltip: :ssn, width: '10em' },
      { key: 'dob', label: 'Age', tooltip: :dob, width: '11em' },
      { key: 'sex', label: 'Sex', tooltip: :sex },
      { key: 'gender', label: 'Gender', tooltip: :gender },
      { key: 'race', label: 'Race', tooltip: :race },
      { key: 'veteran_status', label: 'Veteran Status', tooltip: :veteran_status },
    ].freeze

    # The columns the table rendered before it became configurable. Sex is
    # deliberately absent: Gender is the HUD Data Standards element, and no
    # installation's dashboard should change until an admin opts in.
    DEFAULT_KEYS = ['name', 'ssn', 'dob', 'gender', 'race', 'veteran_status'].freeze

    def self.available_for_select
      ALL.map { |column| [column[:label], column[:key]] }
    end

    # Labels for the default set, in canonical order, so the admin hint can name
    # the columns a blank selection will show without duplicating the list.
    def self.default_labels
      ALL.select { |column| DEFAULT_KEYS.include?(column[:key]) }.map { |column| column[:label] }
    end

    # Keys an admin selected, ignoring blanks and keys that no longer name a
    # column. Falls back to the default set rather than rendering a table with
    # no demographic columns at all.
    def self.configured_keys
      stored = Array.wrap(GrdaWarehouse::Config.get(CONFIG_KEY)).map { |key| key.to_s.presence }.compact
      known = stored & ALL.map { |column| column[:key] }

      known.presence || DEFAULT_KEYS
    end

    def self.visible
      keys = configured_keys
      ALL.select { |column| keys.include?(column[:key]) }
    end

    # Render one cell's value. PII always goes through the provider so masking
    # policy is honored.
    def self.value_for(key, client:, pii:)
      case key
      when 'name'
        pii.brief_name
      when 'ssn'
        pii.ssn
      when 'dob'
        pii.dob_and_age
      when 'sex'
        HudHelper.util.sex(client.Sex)
      when 'gender'
        client.gender
      when 'race'
        client.race_description(include_missing_reason: true)
      when 'veteran_status'
        HudHelper.util.no_yes_reasons_for_missing_data(client.VeteranStatus)
      end
    end
  end
end

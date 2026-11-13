###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::ClientDemographicColumns, type: :model do
  # The columns the demographic table renders today. No installation's dashboard may
  # change until an admin opts in, so this list is the regression pin for the whole feature.
  let(:current_columns) { ['name', 'ssn', 'dob', 'gender', 'race', 'veteran_status'] }

  let(:client) do
    create(
      :grda_warehouse_hud_client,
      FirstName: 'Bob',
      LastName: 'Ross',
      SSN: '123456789',
      DOB: '1999-12-11',
      Sex: 1,
    )
  end

  let(:allow_pii) { GrdaWarehouse::PiiProvider.new(client, policy: GrdaWarehouse::AuthPolicies::AllowPiiPolicy.instance) }
  let(:deny_pii) { GrdaWarehouse::PiiProvider.new(client, policy: GrdaWarehouse::AuthPolicies::DenyPiiPolicy.instance) }

  # Never stub Config.get. It memoizes for 30 seconds in a class ivar, so a stub would
  # both bypass the real read path and leak into unrelated examples.
  def store_columns(value)
    GrdaWarehouse::Config.first_or_create.update!(client_demographic_columns: value)
    GrdaWarehouse::Config.invalidate_cache
  end

  def visible_keys
    described_class.visible.map { |column| column[:key] }
  end

  before do
    GrdaWarehouse::Config.delete_all
    GrdaWarehouse::Config.invalidate_cache
  end

  after do
    GrdaWarehouse::Config.invalidate_cache
  end

  describe '.visible' do
    it 'returns exactly the columns rendered today when no config row has ever been saved' do
      expect(visible_keys).to eq(current_columns)
    end

    it 'returns the columns rendered today when the stored value is an empty array' do
      store_columns([])

      expect(visible_keys).to eq(current_columns)
    end

    it 'returns the columns rendered today when the stored value is the blank entry a cleared multi-select posts' do
      # simple_form emits a hidden blank field for a multiple select, so clearing the
      # picker in the admin stores [''], not [].
      store_columns([''])

      expect(visible_keys).to eq(current_columns)
    end

    it 'returns only the columns an admin selected' do
      store_columns(['name', 'race'])

      expect(visible_keys).to eq(['name', 'race'])
    end

    it 'orders columns canonically rather than in the order they were stored' do
      store_columns(['veteran_status', 'name'])

      expect(visible_keys).to eq(['name', 'veteran_status'])
    end

    it 'ignores a stored key that no longer names a column' do
      # Config outlives a removed column; an unknown key must not raise or render a cell.
      store_columns(['name', 'no_such_column'])

      expect(visible_keys).to eq(['name'])
    end

    it 'falls back to the default columns rather than rendering a table with no columns when nothing stored is recognized' do
      store_columns(['no_such_column'])

      expect(visible_keys).to eq(current_columns)
    end

    it 'adds sex only once an admin selects it' do
      expect(visible_keys).not_to include('sex')

      store_columns(['name', 'sex'])

      expect(visible_keys).to eq(['name', 'sex'])
    end

    it 'exposes the label and tooltip key each column header needs' do
      store_columns(['sex'])

      expect(visible_keys).to eq(['sex'])
      expect(described_class.visible.first).to include(key: 'sex', label: 'Sex', tooltip: :sex)
    end
  end

  describe 'the registry itself' do
    it 'offers every column to the admin picker as a [label, key] pair' do
      # simple_form collections are [label, value]; the value has to be the registry key
      # or the admin's selection will never match a column.
      expect(described_class.available_for_select).to contain_exactly(
        ['Name', 'name'],
        ['SSN', 'ssn'],
        ['Age', 'dob'],
        ['Sex', 'sex'],
        ['Gender', 'gender'],
        ['Race', 'race'],
        ['Veteran Status', 'veteran_status'],
      )
    end

    it 'knows about sex but leaves it out of the defaults, so no installation gains the column on deploy' do
      expect(described_class::ALL.map { |column| column[:key] }).to include('sex')
      expect(described_class::DEFAULT_KEYS).to eq(current_columns)
    end
  end

  describe '.value_for' do
    it 'renders the HUD label for a collected Sex value' do
      expect(described_class.value_for('sex', client: client, pii: allow_pii)).to eq('Male')
    end

    it 'renders nothing, and does not raise, when Sex was never collected' do
      client.update!(Sex: nil)

      expect(described_class.value_for('sex', client: client, pii: allow_pii)).to be_blank
    end

    it 'renders the HUD label for veteran status' do
      client.update!(VeteranStatus: 9)

      expect(described_class.value_for('veteran_status', client: client, pii: allow_pii)).to eq('Client prefers not to answer')
    end

    it 'renders the HUD label for gender' do
      client.update!(Man: 1)

      expect(described_class.value_for('gender', client: client, pii: allow_pii)).to eq('Man (Boy, if child)')
    end

    it 'renders the race description including the reason race is missing' do
      client.update!(RaceNone: 9)

      expect(described_class.value_for('race', client: client, pii: allow_pii)).to eq('Client prefers not to answer')
    end

    it 'shows the full SSN when the policy allows it' do
      expect(described_class.value_for('ssn', client: client, pii: allow_pii)).to eq('123-45-6789')
    end

    it 'fully redacts the SSN when the policy denies it' do
      expect(described_class.value_for('ssn', client: client, pii: deny_pii)).to eq(GrdaWarehouse::PiiProvider::REDACTED)
    end

    it 'shows the name when the policy allows it' do
      expect(described_class.value_for('name', client: client, pii: allow_pii)).to eq('Bob Ross')
    end

    it 'redacts the name when the policy denies names' do
      expect(described_class.value_for('name', client: client, pii: deny_pii)).to eq('Name Redacted')
    end

    it 'shows the full date of birth with age when the policy allows it' do
      travel_to Date.new(2026, 6, 15) do
        expect(described_class.value_for('dob', client: client, pii: allow_pii)).to eq('Dec 11, 1999 (26)')
      end
    end

    it 'reduces the date of birth to a year when the policy denies full DOB' do
      travel_to Date.new(2026, 6, 15) do
        expect(described_class.value_for('dob', client: client, pii: deny_pii)).to eq('1999 (26)')
      end
    end
  end
end

###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Pins attribute coercion, defaults and persistence for ModelForm descendants so changes to
# how ModelForm declares attributes can be shown to be behavior-neutral.
RSpec.describe ModelForm, type: :model do
  let(:today) { Date.new(2026, 1, 15) }

  around { |example| travel_to(today) { example.run } }

  describe Filters::StepRange do
    let(:route) { 'Route Two' }

    before do
      [['Intake', 1], ['Review', 2], ['Match', 3]].each do |step, order|
        create_cas_report(match_route: route, match_id: 1, match_step: step, decision_order: order)
      end
      create_cas_report(match_route: 'Route One', match_id: 2, match_step: 'Other', decision_order: 1)
      create_cas_report(match_route: 'Route One', match_id: 2, match_step: 'Other Two', decision_order: 2)
    end

    def create_cas_report(match_route:, match_id:, match_step:, decision_order:)
      # CasReport is read-only as a model
      GrdaWarehouse::CasReport.insert_all!(
        [
          {
            client_id: 1,
            match_id: match_id,
            decision_id: decision_order,
            decision_order: decision_order,
            match_step: match_step,
            decision_status: 'complete',
            match_route: match_route,
            created_at: Time.current,
            updated_at: Time.current,
          },
        ],
      )
    end

    it 'derives first_step and second_step from the assigned route' do
      filter = described_class.new(route: route)

      expect(filter.route).to eq('Route Two')
      expect(filter.first_step).to eq('(1) Intake')
      expect(filter.second_step).to eq('(2) Review')
    end

    it 'derives steps from the first available route when no route is assigned' do
      filter = described_class.new

      expect(filter.route).to eq('Route One')
      expect(filter.first_step).to eq('(1) Other')
      expect(filter.second_step).to eq('(2) Other Two')
    end

    it 'keeps an explicitly assigned first_step instead of deriving it' do
      filter = described_class.new(route: route, first_step: 'chosen')

      expect(filter.first_step).to eq('chosen')
    end
  end

  describe HudLsa::Filters::LsaFilter do
    let(:user) { create(:acl_user) }
    let(:hic_scope) { HudLsa::Fy2026::Report.available_lsa_scopes['HIC'].to_s }

    it 'clears on for a non-HIC run' do
      filter = described_class.new(user_id: user.id)
      filter.update(coc_code: 'XX-500', lsa_scope: '1', on: '2025-06-30', start: '2024-10-01', end: '2025-09-30')

      expect(filter.on).to be_nil
      expect(filter.start).to eq(Date.new(2024, 10, 1))
      expect(filter.end).to eq(Date.new(2025, 9, 30))
    end

    it 'sets start and end from on for a HIC run and keeps on' do
      filter = described_class.new(user_id: user.id)
      filter.update(coc_code: 'XX-500', lsa_scope: hic_scope, on: '2025-06-30')

      expect(filter.on).to eq(Date.new(2025, 6, 30))
      expect(filter.start).to eq(Date.new(2025, 6, 30))
      expect(filter.end).to eq(Date.new(2025, 6, 30))
    end
  end

  describe Filters::OutflowReport do
    let(:user) { create(:acl_user) }
    let(:dates) { { start: '2025-01-01', end: '2025-01-31' } }
    let(:filter) { described_class.new(user_id: user.id) }

    it 'sets no_service_after_date to nil when none is given' do
      filter.update(dates)

      expect(filter.no_service_after_date).to be_nil
    end

    it 'casts no_service_after_date to a Date when given' do
      filter.update(dates.merge(no_service_after_date: '2025-02-01'))

      expect(filter.no_service_after_date).to eq(Date.new(2025, 2, 1))
    end

    it 'treats nil no_recent_service_project_ids as an empty array' do
      filter.update(dates.merge(no_recent_service_project_ids: nil))

      expect(filter.no_recent_service_project_ids).to eq([])
    end

    it 'casts submitted no_recent_service_project_ids to integers and drops blanks' do
      filter.update(dates.merge(no_recent_service_project_ids: ['', '3', '4']))

      expect(filter.no_recent_service_project_ids).to eq([3, 4])
    end
  end

  describe Filters::FilterBase do
    it 'coerces nil coc_codes to an empty array' do
      expect(described_class.new(coc_codes: nil).coc_codes).to eq([])
    end

    it 'wraps a scalar project_ids in an array' do
      expect(described_class.new(project_ids: '5').project_ids).to eq(['5'])
    end

    it 'defaults coc_codes and project_ids to empty arrays' do
      filter = described_class.new

      expect(filter.coc_codes).to eq([])
      expect(filter.project_ids).to eq([])
    end
  end

  describe Filters::HmisExport do
    it 'coerces symbol, date and integer attributes from strings' do
      filter = described_class.new(comparison_pattern: 'no_comparison_period', start_date: '2025-01-01', hash_status: '1')

      expect(filter.comparison_pattern).to eq(:no_comparison_period)
      expect(filter.start_date).to eq(Date.new(2025, 1, 1))
      expect(filter.hash_status).to eq(1)
    end

    it 'falls back to the declared defaults for unassigned attributes' do
      filter = described_class.new

      expect(filter.end_date).to eq(today)
      expect(filter.start_date).to eq(1.year.ago.to_date)
      expect(filter.source_type).to eq(3)
      expect(filter.include_deleted).to be(false)
    end
  end

  describe Filters::DateRangeAndProject do
    it 'defaults project_type to an empty array' do
      expect(described_class.new.project_type).to eq([])
    end
  end

  describe Filters::DateRange do
    it 'derives start from the assigned end' do
      range = described_class.new(end: '2025-03-31')

      expect(range.end).to eq(Date.new(2025, 3, 31))
      expect(range.start).to eq(Date.new(2025, 3, 24))
    end

    it 'derives end from today when nothing is assigned' do
      range = described_class.new

      expect(range.end).to eq(today)
      expect(range.start).to eq(today - 1.week)
    end

    it 'keeps the lazy default on the original after a dup is assigned' do
      original = described_class.new
      copy = original.dup
      copy.start = Date.new(2020, 1, 1)

      expect(copy.start).to eq(Date.new(2020, 1, 1))
      expect(original.start).to eq(today - 1.week)
    end
  end

  [Filters::Chronic, Filters::HudChronic].each do |klass|
    describe klass do
      it 'leaves blank on, min_age and last_service_after as empty strings' do
        filter = klass.new(on: '', min_age: '', last_service_after: '')

        expect([filter.on, filter.min_age, filter.last_service_after]).to eq(['', '', ''])
      end

      it 'casts submitted values' do
        filter = klass.new(on: '2025-05-01', min_age: '18', last_service_after: '60', veteran: '1')

        expect(filter.on).to eq(Date.new(2025, 5, 1))
        expect(filter.min_age).to eq(18)
        expect(filter.last_service_after).to eq(60)
        expect(filter.veteran).to be(true)
      end

      it 'defaults min_age and last_service_after when unassigned' do
        filter = klass.new

        expect(filter.min_age).to eq(0)
        expect(filter.last_service_after).to eq(30)
        expect(filter.on).to eq(today)
      end
    end
  end

  describe CohortColumns::Active do
    let(:column) { described_class.new }

    it 'has a string column and true visible and editable defaults' do
      expect(column.column).to eq('active')
      expect(column.visible).to be(true)
      expect(column.editable).to be(true)
    end

    it 'translates the title from the translation key' do
      expect(column.translation_key).to eq('Active')
      expect(column.title).to eq(Translation.translate('Active'))
    end

    it 'exposes attributes with symbol keys including translation_key' do
      expect(column.attributes.keys).to include(:translation_key, :column, :visible, :editable)
      expect(column.attributes.keys).to all(be_a(Symbol))
    end

    it 'lets an explicit visible assignment override the default' do
      expect(described_class.new(visible: false).visible).to be(false)
    end
  end

  describe 'cohort column_state serialization' do
    let(:fixture) { Rails.root.join('spec/fixtures/files/cohort_column_state_virtus.yml').read }
    let(:cohort) { create(:cohort) }

    # Raw SQL: the serialized attribute rejects a String, and the fixture must be loaded as stored.
    def store_fixture
      GrdaWarehouse::Cohort.where(id: cohort.id).update_all(['column_state = ?', fixture])
      GrdaWarehouse::Cohort.find(cohort.id)
    end

    it 'loads column objects written by the previous implementation' do
      active, last_name, age = store_fixture.column_state

      expect(active).to be_a(CohortColumns::Active)
      expect(active.column).to eq('active')
      expect(active.visible).to be(false)
      expect(active.editable).to be(true)
      expect(active.title).to eq(Translation.translate('Active'))

      expect(last_name).to be_a(CohortColumns::LastName)
      expect(last_name.column).to eq('last_name')
      expect(last_name.visible).to be(true)
      expect(last_name.title).to eq(Translation.translate('Last Name'))

      expect(age).to be_a(CohortColumns::Age)
      expect(age.column).to eq('age')
      expect(age.editable).to be(true)
      expect(age.title).to eq(Translation.translate('Age*'))
    end

    it 'round-trips the same values through save and reload' do
      loaded = store_fixture
      loaded.column_state_will_change!
      loaded.save!
      active, last_name, age = GrdaWarehouse::Cohort.find(cohort.id).column_state

      expect([active.column, active.visible, active.editable, active.title]).
        to eq(['active', false, true, Translation.translate('Active')])
      expect([last_name.column, last_name.visible, last_name.editable, last_name.title]).
        to eq(['last_name', true, true, Translation.translate('Last Name')])
      expect([age.column, age.visible, age.editable, age.title]).
        to eq(['age', true, true, Translation.translate('Age*')])
    end

    it 'persists a changed visible flag' do
      loaded = store_fixture
      loaded.column_state.first.visible = true
      loaded.save!

      expect(GrdaWarehouse::Cohort.find(cohort.id).column_state.map(&:visible)).to eq([true, true, true])
    end
  end
end

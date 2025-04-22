###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Hmis::Unit, type: :model do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  include_context 'hmis base setup'
  include_context 'hmis service setup'
  let!(:project) { create :hmis_hud_project }
  let!(:unit_type) { create :hmis_unit_type }
  let!(:unit1) { create :hmis_unit, project: p1 }

  let(:c1) { create :hmis_hud_client, data_source: ds1 }
  let(:c2) { create :hmis_hud_client, data_source: ds1 }

  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, entry_date: 2.weeks.ago }
  let!(:e2) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c2, entry_date: 2.weeks.ago, household_id: e1.household_id }

  describe 'with several occupants' do
    let!(:uo1) { create :hmis_unit_occupancy, unit: unit1, enrollment: e1 }
    let!(:uo2) { create :hmis_unit_occupancy, unit: unit1, enrollment: e2 }

    it 'counts occupants' do
      expect(unit1.current_occupants).to contain_exactly(e1, e2)

      expect(e1.current_unit).to eq(unit1)
      expect(e2.current_unit).to eq(unit1)
    end

    it 'handles overlapping occupancy periods' do
      uo1.occupancy_period.update(start_date: 1.month.ago, end_date: 1.week.ago)
      uo2.occupancy_period.update(start_date: 2.weeks.ago, end_date: 2.days.ago)

      expect(unit1.occupants_on(2.months.ago)).to be_empty
      expect(unit1.occupants_on(1.month.ago)).to contain_exactly(e1)
      expect(unit1.occupants_on(9.days.ago)).to contain_exactly(e1, e2)
      expect(unit1.occupants_on(3.days.ago)).to contain_exactly(e2)
      expect(unit1.occupants_on(2.days.ago)).to be_empty # exclusive
      expect(unit1.current_occupants).to be_empty # defaults to today

      expect(Hmis::Unit.occupied_on(2.months.ago)).to be_empty
      expect(Hmis::Unit.occupied_on(1.months.ago)).to contain_exactly(unit1)
      expect(Hmis::Unit.occupied_on(9.days.ago)).to contain_exactly(unit1)
      expect(Hmis::Unit.occupied_on(3.days.ago)).to contain_exactly(unit1)
      expect(Hmis::Unit.occupied_on(2.days.ago)).to be_empty
    end
  end

  describe 'with no occupants' do
    it 'counts occupants' do
      expect(unit1.current_occupants).to be_empty
    end
  end

  describe 'with historical occupancy' do
    let!(:uo1) { create :hmis_unit_occupancy, unit: unit1, enrollment: e1, start_date: 1.month.ago, end_date: 1.week.ago }
    let!(:uo2) { create :hmis_unit_occupancy, unit: unit1, enrollment: e2, start_date: 2.days.ago, end_date: nil }

    it 'counts occupants' do
      expect(unit1.current_occupants).to contain_exactly(e2)
      expect(e1.current_unit).to be_nil # nil because no longer assigned
      expect(e2.current_unit).to eq(unit1)
    end
  end

  describe 'with a specified Unit Type' do
    let!(:unit_type) { create :hmis_unit_type }
    let!(:unit2) { create :hmis_unit, unit_type: unit_type, project: p1 }

    it 'works' do
      expect(Hmis::Unit.of_type(unit_type)).to contain_exactly(unit2)
      expect(unit_type.units).to contain_exactly(unit2)
    end
  end

  describe 'with occupancy tied to a HUD BedNight service' do
    let!(:hud_service) { create :hmis_hud_service, data_source: ds1, client: c1, enrollment: e1, record_type: 200, type_provided: 200 }
    let!(:hmis_service) { Hmis::Hud::HmisService.find_by(owner: hud_service) }
    let!(:uo1) { create :hmis_unit_occupancy, unit: unit1, enrollment: e1, hmis_service: hmis_service }

    it 'works' do
      expect(uo1.hmis_service).to eq(hmis_service)
      expect(Hmis::UnitOccupancy.for_service_type(hmis_service.custom_service_type_id)).to contain_exactly(uo1)
    end
  end

  describe 'with occupancy tied to a CustomService' do
    let!(:custom_service) { create :hmis_custom_service, custom_service_type: cst1, data_source: ds1, client: c1, enrollment: e1 }
    let!(:hmis_service) { Hmis::Hud::HmisService.find_by(owner: custom_service) }
    let!(:uo1) { create :hmis_unit_occupancy, unit: unit1, enrollment: e1, hmis_service: hmis_service }

    it 'works' do
      expect(uo1.hmis_service).to eq(hmis_service)
      expect(Hmis::UnitOccupancy.for_service_type(hmis_service.custom_service_type_id)).to contain_exactly(uo1)
    end
  end

  describe 'opportunity uniqueness validator' do
    let!(:unit) { create(:hmis_unit, project: project) }

    context 'when there is an existing open opportunity' do
      let!(:opportunity) { create(:hmis_ce_opportunity, owner: unit, project: project, status: :open) }

      it 'disallows saving a new opportunity' do
        new_opportunity = build(:hmis_ce_opportunity, owner: unit, project: project, status: :open)
        expect(new_opportunity).not_to be_valid
        expect(new_opportunity.errors[:owner]).to include('can only have one opportunity')
      end
    end

    context 'when there is an existing locked opportunity' do
      let!(:opportunity) { create(:hmis_ce_opportunity, owner: unit, project: project, status: :locked) }
      let!(:referral) { create(:hmis_ce_referral, opportunity: opportunity, status: :in_progress) }

      it 'disallows saving a new opportunity' do
        new_opportunity = build(:hmis_ce_opportunity, owner: unit, project: project, status: :open)
        expect(new_opportunity).not_to be_valid
        expect(new_opportunity.errors[:owner]).to include('can only have one opportunity')
      end
    end

    context 'when there is an existing closed opportunity' do
      let!(:opportunity) { create(:hmis_ce_opportunity, owner: unit, project: project, status: :closed) }
      let!(:referral) { create(:hmis_ce_referral, opportunity: opportunity, status: :accepted) }

      it 'allows saving a new opportunity' do
        new_opportunity = build(:hmis_ce_opportunity, owner: unit, project: project, status: :open)
        expect(new_opportunity).to be_valid
      end
    end
  end

  describe 'latest_opportunity and active_referral scopes' do
    let!(:unit) { create(:hmis_unit, project: project) }
    let!(:today) { Date.current }
    let!(:yesterday) { today - 1.day }

    context 'when there are many opportunities' do
      let!(:opportunity) { create(:hmis_ce_opportunity, owner: unit, project: project, status: :locked, created_at: today - 3.days) }
      let!(:referral) { create(:hmis_ce_referral, opportunity: opportunity, status: :in_progress, created_at: today - 2.days) }

      before do
        3.times do
          opportunity = create(:hmis_ce_opportunity, owner: unit, project: project, status: :closed, created_at: yesterday)
          create(:hmis_ce_referral, opportunity: opportunity, status: :rejected, created_at: yesterday)
        end
      end

      it 'returns the latest opportunity and active referral, prioritizing open/locked over closed' do
        expect(unit.latest_opportunity).to eq(opportunity)
        expect(unit.active_referral).to eq(referral)
      end
    end
  end
end

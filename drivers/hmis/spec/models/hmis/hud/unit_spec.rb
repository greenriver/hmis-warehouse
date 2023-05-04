###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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
  let!(:project) { create :hmis_hud_project }
  let!(:unit_type) { create :hmis_unit_type }
  let!(:unit1) { create :hmis_unit }

  let(:c1) { create :hmis_hud_client, data_source: ds1 }
  let(:c2) { create :hmis_hud_client, data_source: ds1 }

  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1, entry_date: 2.weeks.ago }
  let!(:e2) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c2, entry_date: 2.weeks.ago, household_id: e1.household_id }

  describe 'with several occupants' do
    let!(:uo1) { create :hmis_unit_occupancy, unit: unit1, enrollment: e1 }
    let!(:uo2) { create :hmis_unit_occupancy, unit: unit1, enrollment: e2 }

    it 'counts occupants' do
      expect(unit1.occupants.count).to eq(2)
      expect(unit1.occupants).to contain_exactly(e1, e2)
    end

    it 'handles overlapping occupancy periods' do
      uo1.occupancy_period.update(start_date: 1.month.ago, end_date: 1.week.ago)
      uo2.occupancy_period.update(start_date: 2.weeks.ago, end_date: 2.days.ago)

      expect(unit1.occupants_on(2.months.ago)).to be_empty
      expect(unit1.occupants_on(1.month.ago)).to contain_exactly(e1)
      expect(unit1.occupants_on(9.days.ago)).to contain_exactly(e1, e2)
      expect(unit1.occupants_on(2.days.ago)).to contain_exactly(e2)
      expect(unit1.occupants).to be_empty # defaults to today
    end
  end

  describe 'with no occupants' do
    it 'counts occupants' do
      expect(unit1.occupants.count).to eq(0)
      expect(unit1.occupants).to be_empty
    end
  end

  describe 'with a specified Unit Type' do
    let!(:unit_type) { create :hmis_unit_type }
    let!(:unit2) { create :hmis_unit, unit_type: unit_type }

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
end

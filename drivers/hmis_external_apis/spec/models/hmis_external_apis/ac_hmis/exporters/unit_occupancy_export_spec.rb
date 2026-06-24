###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Exporters::UnitOccupancyExport, type: :model do
  let!(:ds) { create(:hmis_data_source) }
  let(:subject) { described_class.new }

  let!(:project) { create :hmis_hud_project, data_source: ds }
  let!(:unit_type) { create :hmis_unit_type }
  let!(:unit_group) { create :hmis_unit_group, project: project, unit_type: unit_type }
  let!(:unit) { create :hmis_unit, project: project, unit_group: unit_group, unit_type: unit_type }
  let!(:enrollment) { create :hmis_hud_enrollment, data_source: ds, project: project }
  let!(:unit_occupancy) do
    create(
      :hmis_unit_occupancy,
      unit: unit,
      enrollment: enrollment,
      start_date: Date.new(2024, 1, 1),
      end_date: Date.new(2024, 6, 30),
    )
  end

  let(:output) do
    subject.output.rewind
    subject.output.read
  end

  it 'gets unit occupancies' do
    subject.run!
    expect(subject.send(:unit_occupancies).length).to eq(1)
  end

  it 'makes a csv' do
    subject.run!
    result = CSV.parse(output, headers: true)

    expect(result.length).to eq(1)
    expect(result.first['UnitOccupancyID']).to eq(unit_occupancy.id.to_s)
    expect(result.first['UnitID']).to eq(unit.id.to_s)
    expect(result.first['UnitTypeName']).to eq(unit_type.description)
    expect(result.first['ProjectID']).to eq(project.id.to_s)
    expect(result.first['ProjectName']).to eq(project.project_name)
    expect(result.first['EnrollmentID']).to eq(enrollment.id.to_s)
    expect(result.first['StartDate']).to eq('2024-01-01')
    expect(result.first['EndDate']).to eq('2024-06-30')
    expect(result.first['DateCreated']).to be_present
    expect(result.first['DateUpdated']).to be_present
  end

  context 'when the unit occupancy is still active' do
    before { unit_occupancy.occupancy_period.update!(end_date: nil) }

    it 'still exports the record' do
      subject.run!
      result = CSV.parse(output, headers: true)

      expect(result.length).to eq(1)
      expect(result.first['UnitOccupancyID']).to eq(unit_occupancy.id.to_s)
      expect(result.first['StartDate']).to eq('2024-01-01')
      expect(result.first['EndDate']).to be_nil
    end
  end

  context 'when the unit occupancy is soft-deleted' do
    before { unit_occupancy.destroy! }

    it 'still exports the record' do
      subject.run!
      result = CSV.parse(output, headers: true)

      expect(result.length).to eq(1)
      expect(result.first['UnitOccupancyID']).to eq(unit_occupancy.id.to_s)
    end
  end

  context 'when the enrollment is soft-deleted' do
    before { enrollment.destroy! }

    it 'still exports the record' do
      subject.run!
      result = CSV.parse(output, headers: true)

      expect(result.length).to eq(1)
      expect(result.first['EnrollmentID']).to eq(enrollment.id.to_s)
    end
  end

  context 'when the unit is soft-deleted' do
    before { unit.destroy! }

    it 'still exports the record with unit and project details' do
      subject.run!
      result = CSV.parse(output, headers: true)

      expect(result.length).to eq(1)
      expect(result.first['UnitID']).to eq(unit.id.to_s)
      expect(result.first['UnitTypeName']).to eq(unit_type.description)
      expect(result.first['ProjectID']).to eq(project.id.to_s)
      expect(result.first['ProjectName']).to eq(project.project_name)
    end
  end
end

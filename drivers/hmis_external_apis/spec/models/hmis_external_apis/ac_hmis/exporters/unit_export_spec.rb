###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Exporters::UnitExport, type: :model do
  let!(:ds) { create(:hmis_data_source) }
  let(:subject) { HmisExternalApis::AcHmis::Exporters::UnitExport.new }

  let!(:project) { create :hmis_hud_project, data_source: ds }
  let!(:unit_type) { create :hmis_unit_type }
  let!(:unit_group) { create :hmis_unit_group, project: project, unit_type: unit_type }
  let!(:unit) { create :hmis_unit, project: project, unit_group: unit_group, unit_type: unit_type }
  let(:output) do
    subject.output.rewind
    subject.output.read
  end

  it 'gets units' do
    subject.run!
    expect(subject.send(:units).length).to eq(1)
  end

  it 'makes a csv' do
    subject.run!
    result = CSV.parse(output, headers: true)

    expect(result.length).to eq(1)
    expect(result.first['UnitID']).to eq(unit.id.to_s)
    expect(result.first['UnitGroupID']).to eq(unit_group.id.to_s)
    expect(result.first['UnitTypeName']).to eq(unit_type.description)
    expect(result.first['ProjectID']).to eq(project.id.to_s)
    expect(result.first['ProjectName']).to eq(project.project_name)
    expect(result.first['DateCreated']).to be_present
    expect(result.first['DateUpdated']).to be_present
    expect(result.first['DateDeleted']).to be_blank
  end

  context 'when a unit is soft-deleted' do
    let!(:deleted_unit) { create :hmis_unit, project: project, unit_group: unit_group, unit_type: unit_type }

    before { deleted_unit.destroy! }

    it 'includes both active and deleted units' do
      subject.run!
      result = CSV.parse(output, headers: true)

      expect(result.length).to eq(2)
      expect(result.map { |row| row['UnitID'] }).to contain_exactly(unit.id.to_s, deleted_unit.id.to_s)

      deleted_row = result.find { |row| row['UnitID'] == deleted_unit.id.to_s }
      expect(deleted_row['DateDeleted']).to eq(deleted_unit.reload.deleted_at.strftime('%Y-%m-%d %H:%M:%S'))
      expect(deleted_row['UnitGroupID']).to eq(unit_group.id.to_s)
      expect(deleted_row['UnitTypeName']).to eq(unit_type.description)
      expect(deleted_row['ProjectID']).to eq(project.id.to_s)

      active_row = result.find { |row| row['UnitID'] == unit.id.to_s }
      expect(active_row['DateDeleted']).to be_blank
    end
  end

  context 'when a unit group is soft-deleted' do
    before do
      # Unit type must come from the (deleted) unit group, not the unit's own type association
      unit.update_column(:unit_type_id, nil)
      unit_group.destroy!
    end

    it 'still exports the unit with unit group id and unit type name' do
      subject.run!
      result = CSV.parse(output, headers: true)

      expect(result.length).to eq(1)
      expect(result.first['UnitID']).to eq(unit.id.to_s)
      expect(result.first['UnitGroupID']).to eq(unit_group.id.to_s)
      expect(result.first['UnitTypeName']).to eq(unit_type.description)
      expect(result.first['ProjectID']).to eq(project.id.to_s)
      expect(result.first['DateDeleted']).to be_present
    end
  end
end

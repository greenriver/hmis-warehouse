###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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
  end
end

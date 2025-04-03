###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: false

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Exporters::CaseNoteExport, type: :model do
  let!(:ds) { create(:hmis_data_source) }
  let!(:p1) { create(:hmis_hud_project, data_source: ds) }
  let!(:client) { create(:hmis_hud_client_with_warehouse_client, data_source: ds) }
  let!(:enrollment) { create(:hmis_hud_enrollment, data_source: ds, client: client, project: p1) }
  let!(:case_note_1) { create(:hmis_hud_custom_case_note, data_source: ds, client: client, enrollment: enrollment) }

  let(:subject) { HmisExternalApis::AcHmis::Exporters::CaseNoteExport.new }
  let(:output) do
    subject.output.rewind
    subject.output.read
  end

  it 'gets case notes' do
    subject.run!
    expect(subject.send(:case_notes).length).to eq(1)
  end

  it 'makes a csv' do
    subject.run!
    result = CSV.parse(output, headers: true)
    expect(result.length).to eq(1)

    expect(result.first['CaseNoteID']).to eq(case_note_1.id.to_s)
    expect(result.first['EnrollmentID']).to eq(enrollment.id.to_s)
    expect(result.first['PersonalID']).to eq(client.warehouse_id.to_s)
    expect(result.first['NoteContent']).to eq(case_note_1.content)
  end

  it 'quotes newlines' do
    case_note_1.update!(content: "first\nsecond")

    subject.run!

    result = CSV.parse(output, headers: true)

    expect(result.length).to eq(1)
    expect(result.first['NoteContent']).to eq(case_note_1.content)
  end
end

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Exporters::CustomAssessmentExport, type: :model do
  let!(:ds) { create(:hmis_data_source) }
  let!(:client) { create(:hmis_hud_client_with_warehouse_client, data_source: ds) }
  let!(:enrollment) { create(:hmis_hud_enrollment, data_source: ds, client: client) }

  # HUD user associated to the assessment
  let!(:hud_user) { create(:hmis_hud_user, data_source: ds) }

  # Create a custom assessment definition (role: CUSTOM_ASSESSMENT)
  let!(:form_definition) { create(:custom_assessment_with_custom_fields) }

  let!(:assessment) do
    create(
      :hmis_custom_assessment,
      data_source: ds,
      user: hud_user,
      client: client,
      enrollment: enrollment,
      definition: form_definition,
      AssessmentDate: Date.current,
    )
  end

  let(:subject) { described_class.new }

  let(:output) do
    subject.output.rewind
    subject.output.read
  end

  it 'gets custom assessments' do
    subject.run!
    expect(subject.send(:custom_assessments).length).to eq(1)
  end

  it 'makes a csv with expected values' do
    subject.run!

    result = CSV.parse(output, headers: true)
    expect(result.length).to eq(1)

    row = result.first
    expect(row['CustomAssessmentID']).to eq(assessment.id.to_s)
    expect(row['EnrollmentID']).to eq(enrollment.id.to_s)
    expect(row['PersonalID']).to eq(client.warehouse_id.to_s)
    expect(row['AssessmentDate']).to eq(assessment.assessment_date.to_fs(:db))
    expect(row['AssessmentKey']).to eq(form_definition.identifier)
    expect(row['AssessmentTitle']).to eq(form_definition.title)
    expect(row['DateCreated']).to eq(assessment.date_created.strftime('%Y-%m-%d %H:%M:%S'))
    expect(row['DateUpdated']).to eq(assessment.date_updated.strftime('%Y-%m-%d %H:%M:%S'))
    expect(row['CreatedByUserID']).to eq(hud_user.id.to_s)
    expect(row['UpdatedByUserID']).to eq(hud_user.id.to_s)
  end
end

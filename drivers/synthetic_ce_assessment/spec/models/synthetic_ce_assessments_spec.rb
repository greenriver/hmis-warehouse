###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe 'Synthetic CE Assessment sync', type: :model do
  let!(:data_source) { create :data_source_fixed_id }
  let!(:project) { create :hud_project, data_source_id: data_source.id }
  let!(:project2) { create :hud_project, data_source_id: data_source.id }
  let!(:client) { create :hud_client, data_source_id: data_source.id }
  let!(:enrollment) { create :hud_enrollment, PersonalID: client.PersonalID, ProjectID: project.ProjectID, data_source_id: data_source.id }
  let!(:enrollment2) { create :hud_enrollment, PersonalID: client.PersonalID, ProjectID: project2.ProjectID, data_source_id: data_source.id }

  let!(:project_config) { create :synthetic_ce_assessment_project_config, project: project, assessment_type: 3, assessment_level: 1, prioritization_status: 2 }

  it 'creates synthetic assessments for the enrollment where the project is flagged' do
    scope = SyntheticCeAssessment::EnrollmentCeAssessment.all
    expect do
      SyntheticCeAssessment::EnrollmentCeAssessment.sync
    end.to change(scope, :count).by(1)
    expect(scope.first&.source).to eq(enrollment)
  end

  it 'removes orphaned synthetic assessments' do
    SyntheticCeAssessment::EnrollmentCeAssessment.sync
    expect do
      enrollment.destroy
      SyntheticCeAssessment::EnrollmentCeAssessment.sync
    end.to change(SyntheticCeAssessment::EnrollmentCeAssessment, :count).by(-1)
  end
end

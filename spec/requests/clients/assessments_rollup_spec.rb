###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/hidden_project_enrollment_context'

RSpec.describe 'Client dashboard assessment rollups', type: :request do
  include_context 'hidden project enrollment context'

  let!(:config) { create :config_b }

  # Pathways, so the Boston limited dashboard links it.
  def build_pathways(enrollment, date)
    assessment = create(:hud_assessment, data_source_id: ds.id, PersonalID: hmis_client.PersonalID, EnrollmentID: enrollment.EnrollmentID, AssessmentDate: date)
    GrdaWarehouse::AssessmentAnswerLookup.create!(assessment_question: 'c_housing_assessment_name', response_code: assessment.AssessmentID.to_s, response_text: 'Pathways 2024')
    create(
      :hud_assessment_question,
      data_source_id: ds.id,
      AssessmentID: assessment.AssessmentID,
      AssessmentQuestion: 'c_housing_assessment_name',
      AssessmentAnswer: assessment.AssessmentID.to_s,
    )
    assessment
  end

  let!(:visible_hud_assessment) { build_pathways(visible_enrollment, Date.new(2024, 3, 3)) }
  let!(:hidden_hud_assessment) { build_pathways(hidden_enrollment, Date.new(2023, 4, 4)) }
  let!(:visible_hmis_assessment) { create(:hmis_custom_assessment, data_source: ds, client: hmis_client, enrollment: visible_enrollment, AssessmentDate: Date.new(2024, 5, 5)) }
  let!(:hidden_hmis_assessment) { create(:hmis_custom_assessment, data_source: ds, client: hmis_client, enrollment: hidden_enrollment, AssessmentDate: Date.new(2023, 6, 6)) }

  before { sign_in_with(viewer_role) }

  it 'lists only HUD and HMIS assessments recorded at the visible project' do
    config.update(client_dashboard: :default)

    get rollup_client_path(destination, partial: :assessments), xhr: true

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(visible_hud_assessment.AssessmentDate.to_s, visible_hmis_assessment.AssessmentDate.to_s)
    expect(response.body).not_to include(hidden_hud_assessment.AssessmentDate.to_s)
    expect(response.body).not_to include(hidden_hmis_assessment.AssessmentDate.to_s)
  end

  it 'lists only the Pathways assessment recorded at the visible project on the limited dashboard' do
    config.update(client_dashboard: :boston)

    get rollup_client_path(destination, partial: :boston_assessments_with_limited_data), xhr: true

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(client_coordinated_entry_hud_assessment_path(destination, visible_hud_assessment))
    expect(response.body).not_to include(client_coordinated_entry_hud_assessment_path(destination, hidden_hud_assessment))
  end
end

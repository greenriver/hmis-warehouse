###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'HmisExternalApis::TcHmis::Importers::SyntheticCeAssessmentsForCustomAssessment', type: :model do
  let(:ds) do
    create(:hmis_data_source)
  end

  let!(:custom_assessment) do
    create(:hmis_custom_assessment, data_source: ds)
  end

  let!(:custom_assessment_with_ce) do
    create(:hmis_custom_assessment, data_source: ds).tap do |ca|
      ce_assessment = create(:hmis_hud_assessment, enrollment: ca.enrollment, client: ca.client, data_source: ds)
      ca.form_processor.update!(ce_assessment: ce_assessment)
    end
  end

  let!(:canary) do
    create(:hmis_custom_assessment)
  end

  let(:ce_attrs) do
    {
      assessment_type: 3, # in person
      assessment_level: 1, # crisis needs assessment
      prioritization_status: 1, # placed on prioritization list
    }
  end

  it 'populates ce missing assessments' do
    custom_assessments = Hmis::Hud::CustomAssessment.where(data_source: ds)
    expect do
      HmisExternalApis::TcHmis::Importers::SyntheticCeAssessmentsForCustomAssessment.new.perform(custom_assessments: custom_assessments, **ce_attrs)
      [custom_assessment, custom_assessment_with_ce, canary].each(&:reload)
    end.to(
      [
        change { Hmis::Hud::Assessment.count }.by(1),
        change { Hmis::Form::FormProcessor.where(ce_assessment: nil).count }.by(-1),
        not_change { [custom_assessment_with_ce, canary].map { |r| r.form_processor.custom_assessment&.attributes } },
        change { custom_assessment.form_processor.ce_assessment_id },
      ].reduce(&:and),
    )

    new_ce_assessment = custom_assessment.form_processor.ce_assessment
    {
      **ce_attrs,
      synthetic: true,
      EnrollmentID: custom_assessment.EnrollmentID,
      PersonalID: custom_assessment.PersonalID,
      UserID: custom_assessment.UserID,
      AssessmentDate: custom_assessment.AssessmentDate,
      data_source_id: ds.id,
      DateCreated: custom_assessment.DateCreated,
      DateUpdated: custom_assessment.DateUpdated,
    }.each do |field, value|
      expect(new_ce_assessment.send(field)).to(eq(value))
    end
  end
end

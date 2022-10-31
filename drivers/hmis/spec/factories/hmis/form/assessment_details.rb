FactoryBot.define do
  factory :hmis_form_assessment_detail, class: 'Hmis::Form::AssessmentDetail' do
    definition { association :hmis_form_definition }
    assessment { association :hmis_hud_assessment }
    data_collection_stage { 1 }
    role { 'INTAKE' }
    status { 'draft' }
  end
end

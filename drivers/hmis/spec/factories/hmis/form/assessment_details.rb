FactoryBot.define do
  factory :hmis_form_assessment_detail, class: 'Hmis::Form::Definition' do
    association :definition, factory: :hmis_form_definition
    association :assessment, factory: :hmis_hud_assessment
    data_collection_stage { 1 }
    role { 'INTAKE' }
    status { 'draft' }
  end
end

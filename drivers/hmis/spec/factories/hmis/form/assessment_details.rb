FactoryBot.define do
  factory :hmis_form_custom_form, class: 'Hmis::Form::CustomForm' do
    definition { association :hmis_form_definition }
    assessment { association :hmis_hud_assessment }
    data_collection_stage { 1 }
    role { 'INTAKE' }
    status { 'draft' }
  end
end

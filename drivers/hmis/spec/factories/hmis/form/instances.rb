FactoryBot.define do
  factory :hmis_form_instance, class: 'Hmis::Form::Instance' do
    association :entity, factory: :hmis_hud_project
    association :definition, factory: :hmis_form_definition
  end
end

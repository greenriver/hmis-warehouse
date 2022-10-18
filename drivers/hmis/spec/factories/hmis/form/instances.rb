FactoryBot.define do
  factory :hmis_form_instance, class: 'Hmis::Form::Instance' do
    entity { association :hmis_hud_project }
    definition { association :hmis_form_definition }
  end
end

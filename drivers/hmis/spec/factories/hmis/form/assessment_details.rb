###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_form_custom_form, class: 'Hmis::Form::CustomForm' do
    definition { association :hmis_form_definition }
    owner { association :hmis_hud_assessment }
    values { {} }
    hud_values { {} }
  end
end

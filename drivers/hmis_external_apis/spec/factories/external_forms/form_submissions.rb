###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_external_form_submission, class: 'HmisExternalApis::ExternalForms::FormSubmission' do
    association :definition, factory: :hmis_external_form_definition
    submitted_at { Time.current }
    status { 'new' }
    spam_score { 1.0 }
    sequence(:object_key)
    raw_data { { 'your_name' => 'value' } }
  end
end

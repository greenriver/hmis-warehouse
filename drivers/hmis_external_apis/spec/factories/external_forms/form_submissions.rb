FactoryBot.define do
  factory :hmis_external_form_submission, class: 'HmisExternalApis::ExternalForms::FormSubmission' do
    association :definition, factory: :hmis_external_form_definition
    submitted_at { Time.current }
    status { 'new' }
    spam_score { 1.0 }
    sequence(:object_key)
    raw_data { { 'your_name' => 'value' } }
    cleaned_values { { 'your_name' => 'value' } }
  end
end

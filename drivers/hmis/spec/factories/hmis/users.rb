FactoryBot.define do
  factory :hmis_user, class: 'Hmis::User', parent: :user do
    first_name { 'Test' }
    last_name { 'User' }
    transient do
      data_source { nil }
    end
    after(:create) do |hmis_user, evaluator|
      hmis_user.hmis_data_source_id = evaluator.data_source.id if evaluator.data_source.present?
    end
  end
end

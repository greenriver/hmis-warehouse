FactoryBot.define do
  factory :hmis_user, class: 'Hmis::User', parent: :user do
    first_name { 'Test' }
    last_name { 'User' }

    # FIXME ?? ...

    # data_source { association :hmis_data_source }

    # before(:create) do |user, _evaluator|
    #   user.add_viewable(user.data_source)
    #   user.related_hmis_user(user.data_source)
    # end
  end
end

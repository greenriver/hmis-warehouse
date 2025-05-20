FactoryBot.define do
  factory :hmis_health_import_config, class: 'Health::ImportConfig' do
    name { "Claims Reporting SFTP" }
    active { true }
    kind { :claims_reporting }
    host { "sftp.example.com" }
    username { "testuser" }
    password { "testpass" }
    path { "/uploads" }

    trait :inactive do
      active { false }
    end
  end
end

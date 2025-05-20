FactoryBot.define do
  factory :hmis_claims_reporting_import, class: 'ClaimsReporting::Import' do
    source_url { "sftp://example.com/files/claims_jan_2023.zip" }
    started_at { Time.current }
    importer { "ClaimsReporting::Importer" }
    add_attribute(:method) { "import_from_health_sftp" }
    args { { replace_all: false } }
    content_hash { "abc123hash" }
    successful { false }

    trait :successful do
      successful { true }
      completed_at { Time.current }
      results { { "member_roster.csv" => { count: 10 }, "medical_claims.csv" => { count: 30 } } }
    end
  end
end

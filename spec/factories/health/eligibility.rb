FactoryBot.define do
  factory :eligibility_inquiry, class: 'Health::EligibilityInquiry' do
    service_date { Date.current }
  end

  factory :eligibility_response, class: 'Health::EligibilityResponse'
end

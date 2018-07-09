FactoryGirl.define do
  factory :hud_income_benefit, class: 'GrdaWarehouse::Hud::IncomeBenefit' do
    sequence(:IncomeBenefitsID, 7)
    sequence(:EnrollmentID, 1)
    sequence(:PersonalID, 10)
  end
end

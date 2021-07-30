FactoryBot.define do
  factory :program_to_project, class: 'CasCeEvents::GrdaWarehouse::ProgramToProject' do
    sequence(:program_id, 100)
  end

  factory :cas_referral_event, class: 'CasCeEvents::GrdaWarehouse::CasReferralEvent' do
  end
end

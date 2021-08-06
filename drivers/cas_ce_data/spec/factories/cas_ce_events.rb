FactoryBot.define do
  factory :program_to_project, class: 'CasCeData::GrdaWarehouse::ProgramToProject' do
    program_id { 100 }
  end

  factory :cas_referral_event, class: 'CasCeData::GrdaWarehouse::CasReferralEvent' do
  end
end

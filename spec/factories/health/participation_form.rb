FactoryBot.define do
  factory :signed_participation_form, class: 'Health::ParticipationForm' do
    signature_on { Date.current }
    location { 'Storage' }
  end
end

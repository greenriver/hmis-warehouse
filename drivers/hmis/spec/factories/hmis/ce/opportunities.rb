FactoryBot.define do
  factory :hmis_ce_opportunity, class: 'Hmis::Ce::Opportunity' do
    sequence(:name) { |n| "Opportunity #{n}" }
    association(:project, factory: :hmis_hud_project)
  end
end

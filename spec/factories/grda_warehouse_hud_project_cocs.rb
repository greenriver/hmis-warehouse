FactoryGirl.define do
  factory :hud_project_coc, class: 'GrdaWarehouse::Hud::ProjectCoc' do
    sequence(:ProjectID, 100)
    sequence(:ProjectCoCID, 1)
  end
end

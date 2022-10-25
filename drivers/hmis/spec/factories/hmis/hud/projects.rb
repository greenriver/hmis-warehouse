FactoryBot.define do
  factory :hmis_hud_project, class: 'Hmis::Hud::Project' do
    data_source { association :hmis_data_source }
    user { association :hmis_hud_user, data_source: data_source }
    sequence(:ProjectID, 200)
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
    ProjectName { 'Project' }
    OperatingStartDate { Date.parse('2019-01-01') }
    ContinuumProject { 0 }
    HMISParticipatingProject { 1 }
    ProjectType { 1 }
  end
end

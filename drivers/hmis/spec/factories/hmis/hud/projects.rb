FactoryBot.define do
  factory :hmis_hud_project, class: 'Hmis::Hud::Project' do
    association :data_source, factory: :hmis_data_source
    sequence(:ProjectID, 200)
    sequence(:UserID, 100)
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
    ProjectName { 'Project' }
    OperatingStartDate { Date.parse('2019-01-01') }
    ContinuumProject { 0 }
    HMISParticipatingProject { 1 }
    ProjectType { 1 }
  end
end

###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_hud_project, class: 'Hmis::Hud::Project' do
    data_source { association :hmis_data_source }
    user { association :hmis_hud_user, data_source: data_source }
    organization { association :hmis_hud_organization, data_source: data_source }
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

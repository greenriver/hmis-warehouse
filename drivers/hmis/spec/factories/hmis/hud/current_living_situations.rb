###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_current_living_situation, class: 'Hmis::Hud::CurrentLivingSituation', parent: :hmis_base_factory do
    client { association :hmis_hud_client, data_source: data_source }
    enrollment { association :hmis_hud_enrollment, data_source: data_source, client: client }
    sequence(:CurrentLivingSitID, 500)
    information_date { Date.yesterday }
    current_living_situation { 1 }
    verified_by_project_id { association :hmis_hud_project, data_source: data_source }
    DateCreated { Date.parse('2019-01-01') }
    DateUpdated { Date.parse('2019-01-01') }
    after(:create) do |cls|
      cls.update(VerifiedBy: Hmis::Hud::Project.find(cls.verified_by_project_id).name) if cls.verified_by_project_id
    end
  end
end

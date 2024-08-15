###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :csg_engage_agency, class: 'MaReports::CsgEngage::Agency' do
    sequence(:name) { |n| "Agency #{n}" }
    sequence(:csg_engage_agency_id) { |n| n }
  end

  factory :csg_engage_report, class: 'MaReports::CsgEngage::Report' do
    project_ids { [] }
    agency { association :csg_engage_agency }
  end

  factory :csg_engage_program_mapping, class: 'MaReports::CsgEngage::ProgramMapping' do
    sequence(:clarity_name) { |n| "Clarity Project #{n}" }
    program { association :csg_engage_program }
    project { association :hud_project }
  end

  factory :csg_engage_program, class: 'MaReports::CsgEngage::Program' do
    sequence(:csg_engage_name) { |n| "CSG Engage Project #{n}" }
    sequence(:csg_engage_import_keyword) { |n| "CSG Engage Keyword #{n}" }
    agency { association :csg_engage_agency }
  end
end

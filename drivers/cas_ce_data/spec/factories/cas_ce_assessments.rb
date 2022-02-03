###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :cas_ce_assessment, class: 'CasCeData::GrdaWarehouse::CasCeAssessment' do
    assessment_location { 'Unknown' }
    assessment_type { 3 }
    assessment_level { 1 }
    assessment_status { 1 }
  end
end

###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_staff_assignment, class: 'Hmis::StaffAssignment' do
    staff_assignment_type { association :hmis_staff_assignment_type }
    data_source { association :hmis_data_source }
    user { association :hmis_user, data_source: data_source }
    transient do
      enrollment { association :hmis_hud_enrollment, data_source: data_source }
    end
    after(:build) do |record, evaluator|
      # enrollment = create :hmis_hud_enrollment, data_source: record.data_source
      record.household = evaluator.enrollment.household
    end
  end

  factory :hmis_staff_assignment_type, class: 'Hmis::StaffAssignmentType' do
    name { 'Case Manager' }
  end
end

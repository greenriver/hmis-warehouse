###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :talentlms_completed_training, class: 'Talentlms::CompletedTraining' do
    association :login, factory: :talentlms_login
    association :config, factory: :talentlms_config
    association :course, factory: :default_course
    completion_date { Date.today }
  end
end

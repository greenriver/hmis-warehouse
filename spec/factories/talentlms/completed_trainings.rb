###
# Copyright Green River Data Group, Inc.
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

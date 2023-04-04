###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_hud_exit, class: 'Hmis::Hud::Exit' do
    sequence(:ExitID, 50)
    sequence(:EnrollmentID, 20)
    sequence(:PersonalID, 30)
    sequence(:ExitDate) do |n|
      dates = [
        Date.yesterday,
        15.days.ago,
        16.days.ago,
        17.days.ago,
        4.weeks.ago,
      ]
      dates[n % 5].to_date
    end
    destination { 1 }
    user { association :hmis_hud_user, data_source: data_source }

    after(:build) do |exit|
      return unless exit.enrollment.present?

      # Set exit date to be after entry date (but not in the future) to ensure validity
      distances = [
        15.days,
        16.days,
        17.days,
        4.weeks,
      ]

      exit.exit_date = [exit.enrollment.entry_date + distances.sample, Date.yesterday].min
    end
  end
end

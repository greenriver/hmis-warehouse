###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

FactoryBot.define do
  factory :hmis_base_hud_exit, class: 'Hmis::Hud::Exit', parent: :hmis_base_factory do
    client { association :hmis_hud_client, data_source: data_source }
    enrollment { association :hmis_hud_enrollment, data_source: data_source, client: client }
    sequence(:ExitID, 50)
    destination { 1 }
    exit_date { Date.today }
    enrollment_slug { "#{enrollment_id}:#{personal_id}:#{data_source_id}" }
  end

  factory :hmis_hud_exit, class: 'Hmis::Hud::Exit', parent: :hmis_base_hud_exit do
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

    after(:build) do |exit|
      next unless exit.enrollment.present?

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

FactoryBot.define do
  factory :hmis_hud_exit, class: 'Hmis::Hud::Exit' do
    sequence(:ExitID, 50)
    sequence(:EnrollmentID, 20)
    sequence(:PersonalID, 30)
    sequence(:ExitDate) do |n|
      dates = [
        Date.current,
        15.days.ago,
        16.days.ago,
        17.days.ago,
        4.weeks.ago,
      ]
      dates[n % 5].to_date
    end
    destination { 1 }
    user { association :hmis_hud_user, data_source: data_source }
  end
end

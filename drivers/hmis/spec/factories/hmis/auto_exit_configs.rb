FactoryBot.define do
  factory :hmis_auto_exit_config, class: 'Hmis::AutoExitConfig' do
    length_of_absence_days { 30 }
  end
end

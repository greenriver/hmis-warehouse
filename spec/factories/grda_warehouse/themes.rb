FactoryBot.define do
  factory :theme, class: 'GrdaWarehouse::Theme' do
    client { 'test' }
  end

  factory :hmis_theme, parent: :theme do
    hmis_value { { 'palette' => { 'primary' => { 'main' => '#41596B' } } } }
  end
end

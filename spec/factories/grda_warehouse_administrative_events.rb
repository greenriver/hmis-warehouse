FactoryGirl.define do
  factory :grda_warehouse_administrative_event, class: 'GrdaWarehouse::AdministrativeEvent' do
    user
    date "2018-05-30"
    title "Title"
    description "Description"
  end
end

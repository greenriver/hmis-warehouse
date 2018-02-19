FactoryGirl.define do
  factory :available_file_tag, class: 'GrdaWarehouse::AvailableFileTag' do
    name 'Tag'
    group 'Group'
    included_info 'This is included'
  end
end
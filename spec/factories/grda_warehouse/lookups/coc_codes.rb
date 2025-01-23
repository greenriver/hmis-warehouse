FactoryBot.define do
  factory :lookup_coc, class: 'GrdaWarehouse::Lookups::CocCode' do
    # these are required by db schema
    active { true }
    sequence(:official_name) { |n| "Fake CoC 5#{n.to_s.rjust(2, '0')}" }
    sequence(:coc_code) { |n| "XX-5#{n.to_s.rjust(2, '0')}" }
  end
end

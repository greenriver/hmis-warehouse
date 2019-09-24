FactoryBot.define do
  factory :grda_warehouse_available_file_tag, class: 'GrdaWarehouse::AvailableFileTag' do
    name { 'MyString' }
    group { 'MyString' }
    weight { 1 }
  end

  factory :coc_roi_tag, class: 'GrdaWarehouse::AvailableFileTag' do
    name { 'HAN Release' }
    group { 'Consent Forms' }
    weight { 1 }
    consent_form { true }
    full_release { true }
    requires_effective_date { true }
    coc_available { true }
  end
end

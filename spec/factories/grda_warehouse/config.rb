FactoryBot.define do
  factory :config, class: 'GrdaWarehouse::Config' do
  end

  factory :config_b, class: 'GrdaWarehouse::Config' do
    project_type_override { true }
    family_calculation_method { 'multiple_people' }
    release_duration { 'Indefinite' }
    allow_partial_release { true }
    window_access_requires_release { false }
    show_partial_ssn_in_window_search_results { false }
    so_day_as_month { true }
    infer_family_from_household_id { false }
    vispdat_prioritization_scheme { 'length_of_time' }
    multi_coc_installation { false }
  end

  factory :config_s, class: 'GrdaWarehouse::Config' do
    project_type_override { true }
    family_calculation_method { 'adult_child' }
    release_duration { 'One Year' }
    allow_partial_release { false }
    window_access_requires_release { true }
    show_partial_ssn_in_window_search_results { false }
    so_day_as_month { true }
    infer_family_from_household_id { false }
    vispdat_prioritization_scheme { 'length_of_time' }
    multi_coc_installation { false }
  end

  factory :config_3c, class: 'GrdaWarehouse::Config' do
    project_type_override { true }
    family_calculation_method { 'adult_child' }
    release_duration { 'One Year' }
    allow_partial_release { true }
    window_access_requires_release { false }
    show_partial_ssn_in_window_search_results { true }
    so_day_as_month { true }
    infer_family_from_household_id { true }
    vispdat_prioritization_scheme { 'length_of_time' }
    multi_coc_installation { false }
  end

  factory :config_tc, class: 'GrdaWarehouse::Config' do
    project_type_override { true }
    family_calculation_method { 'multiple_people' }
    release_duration { 'Use Expiration Date' }
    allow_partial_release { false }
    window_access_requires_release { false }
    show_partial_ssn_in_window_search_results { true }
    so_day_as_month { true }
    infer_family_from_household_id { true }
    vispdat_prioritization_scheme { 'veteran_status' }
    multi_coc_installation { false }
  end

  factory :config_ma, class: 'GrdaWarehouse::Config' do
    project_type_override { true }
    family_calculation_method { 'adult_child' }
    release_duration { 'One Year' }
    allow_partial_release { false }
    window_access_requires_release { true }
    show_partial_ssn_in_window_search_results { true }
    so_day_as_month { true }
    infer_family_from_household_id { true }
    vispdat_prioritization_scheme { 'length_of_time' }
    multi_coc_installation { true }
  end

  factory :config_mi, class: 'GrdaWarehouse::Config' do
    project_type_override { true }
    family_calculation_method { 'adult_child' }
    release_duration { 'One Year' }
    allow_partial_release { false }
    window_access_requires_release { true }
    show_partial_ssn_in_window_search_results { false }
    so_day_as_month { true }
    infer_family_from_household_id { true }
    vispdat_prioritization_scheme { 'length_of_time' }
    multi_coc_installation { true }
  end

  factory :config_va, class: 'GrdaWarehouse::Config' do
    project_type_override { true }
    family_calculation_method { 'adult_child' }
    release_duration { 'Indefinite' }
    allow_partial_release { false }
    window_access_requires_release { false }
    show_partial_ssn_in_window_search_results { false }
    so_day_as_month { true }
    infer_family_from_household_id { true }
    vispdat_prioritization_scheme { 'length_of_time' }
    multi_coc_installation { true }
    roi_model { :implicit }
  end
end

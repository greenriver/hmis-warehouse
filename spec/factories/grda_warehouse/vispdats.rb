FactoryBot.define do
  factory :vispdat, class: 'GrdaWarehouse::Vispdat::Individual' do
    association :client, factory: :grda_warehouse_hud_client
    association :user, factory: :user
    nickname { 'Test' }
    language_answer { 1 }
    hiv_release { 1 }
    sleep_answer { 1 }
    sleep_answer_other { 'Test' }
    homeless { 1 }
    homeless_period { :months }
    homeless_refused { false }
    episodes_homeless { 2 }
    episodes_homeless_refused { false }
    emergency_healthcare { nil }
    emergency_healthcare_refused { true }
    ambulance { nil }
    ambulance_refused { true }
    inpatient { nil }
    inpatient_refused { true }
    crisis_service { nil }
    crisis_service_refused { true }
    talked_to_police { nil }
    talked_to_police_refused { true }
    jail { nil }
    jail_refused { true }
    attacked_answer { 2 }
    threatened_answer { 2 }
    legal_answer { 2 }
    tricked_answer { 2 }
    risky_answer { 2 }
    owe_money_answer { 2 }
    get_money_answer { 2 }
    activities_answer { 2 }
    basic_needs_answer { 2 }
    abusive_answer { 2 }
    leave_answer { 2 }
    chronic_answer { 2 }
    hiv_answer { 2 }
    disability_answer { 2 }
    avoid_help_answer { 2 }
    pregnant_answer { 2 }
    eviction_answer { 2 }
    drinking_answer { 2 }
    mental_answer { 2 }
    head_answer { 2 }
    learning_answer { 2 }
    brain_answer { 2 }
    medication_answer { 2 }
    sell_answer { 2 }
    trauma_answer { 2 }
    find_location { 'Test' }
    find_time { '2pm' }
    when_answer { :morning }
    phone { '123-123-1234' }
    email { 'test@example.com' }
    picture_answer { 2 }
    score { nil }
    priority_score { nil }
    recommendation { nil }
    release_signed_on { nil }
    drug_release { nil }
    contact_method { :contact_phone }
  end

  factory :family_vispdat, class: 'GrdaWarehouse::Vispdat::Family' do
    association :client, factory: :grda_warehouse_hud_client
    association :user, factory: :user
  end
  factory :youth_vispdat, class: 'GrdaWarehouse::Vispdat::Youth' do
    association :client, factory: :grda_warehouse_hud_client
    association :user, factory: :user
  end
end

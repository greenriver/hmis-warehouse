require 'rails_helper'

RSpec.describe "vispdats/new", type: :view do
  before(:each) do
    assign(:vispdat, Vispdat.new(
      :first_name => "MyString",
      :nickname => "MyString",
      :last_name => "MyString",
      :language => 1,
      :ssn => "MyString",
      :consent => false,
      :where_sleep => 1,
      :where_sleep_other => "MyString",
      :where_sleep_refused => false,
      :years_homeless => 1,
      :years_homeless_refused => false,
      :episodes_homeless => 1,
      :episodes_homeless_refused => false,
      :emergency_healthcare => 1,
      :emergency_healthcare_refused => false,
      :ambulance => 1,
      :ambulance_refused => false,
      :inpatient => 1,
      :inpatient_refused => false,
      :crisis_service => 1,
      :crisis_service_refused => false,
      :talked_to_police => 1,
      :talked_to_police_refused => false,
      :jail => 1,
      :jail_refused => false,
      :attacked => false,
      :attacked_refused => false,
      :threatened => false,
      :threatened_refused => false,
      :legal_issue => false,
      :legal_issue_refused => false,
      :tricked => false,
      :tricked_refused => false,
      :risky => false,
      :risky_refused => false,
      :owe_money => false,
      :owe_money_refused => false,
      :receive_money => false,
      :receive_money_refused => false,
      :planned_activities => false,
      :planned_activities_refused => false,
      :basic_needs => false,
      :basic_needs_refused => false,
      :abusive_relationship => false,
      :abusive_relationship_refused => false,
      :leave_due_to_health => false,
      :leave_due_to_health_refused => false,
      :chronic_health => false,
      :chronic_health_refused => false,
      :hiv_program_interest => false,
      :hiv_program_interest_refused => false,
      :physical_disabilities => false,
      :physical_disabilities_refused => false,
      :avoid_help => false,
      :avoid_help_refused => false,
      :pregnant => false,
      :pregnant_refused => false,
      :substance_eviction => false,
      :substance_eviction_refused => false,
      :substance_housing => false,
      :substance_housing_refused => false,
      :housing_mental => false,
      :housing_mental_refused => false,
      :housing_head_injury => false,
      :housing_head_injury_refused => false,
      :housing_learning => false,
      :housing_learning_refused => false,
      :brain_issues => false,
      :brain_issues_refused => false,
      :not_taking_medications => false,
      :not_taking_medications_refused => false,
      :sell_medications => false,
      :sell_medications_refused => false,
      :trauma => false,
      :trauma_refused => false,
      :find_location => "MyString",
      :find_time => "MyString",
      :find_period => 1,
      :phone => "MyString",
      :email => "MyString",
      :picture => false,
      :picture_refused => false,
      score: 0
    ))
  end

  skip "renders new vispdat form" do
    render

    assert_select "form[action=?][method=?]", vispdats_path, "post" do

      assert_select "input#vispdat_first_name[name=?]", "vispdat[first_name]"

      assert_select "input#vispdat_nickname[name=?]", "vispdat[nickname]"

      assert_select "input#vispdat_last_name[name=?]", "vispdat[last_name]"

      assert_select "input#vispdat_language[name=?]", "vispdat[language]"

      assert_select "input#vispdat_ssn[name=?]", "vispdat[ssn]"

      assert_select "input#vispdat_consent[name=?]", "vispdat[consent]"

      assert_select "input#vispdat_sleep[name=?]", "vispdat[where_sleep]"

      assert_select "input#vispdat_sleep_other[name=?]", "vispdat[where_sleep_other]"

      assert_select "input#vispdat_sleep_refused[name=?]", "vispdat[where_sleep_refused]"

      assert_select "input#vispdat_years_homeless[name=?]", "vispdat[years_homeless]"

      assert_select "input#vispdat_years_homeless_refused[name=?]", "vispdat[years_homeless_refused]"

      assert_select "input#vispdat_episodes_homeless[name=?]", "vispdat[episodes_homeless]"

      assert_select "input#vispdat_episodes_homeless_refused[name=?]", "vispdat[episodes_homeless_refused]"

      assert_select "input#vispdat_emergency_healthcare[name=?]", "vispdat[emergency_healthcare]"

      assert_select "input#vispdat_emergency_healthcare_refused[name=?]", "vispdat[emergency_healthcare_refused]"

      assert_select "input#vispdat_ambulance[name=?]", "vispdat[ambulance]"

      assert_select "input#vispdat_ambulance_refused[name=?]", "vispdat[ambulance_refused]"

      assert_select "input#vispdat_inpatient[name=?]", "vispdat[inpatient]"

      assert_select "input#vispdat_inpatient_refused[name=?]", "vispdat[inpatient_refused]"

      assert_select "input#vispdat_crisis_service[name=?]", "vispdat[crisis_service]"

      assert_select "input#vispdat_crisis_service_refused[name=?]", "vispdat[crisis_service_refused]"

      assert_select "input#vispdat_talked_to_police[name=?]", "vispdat[talked_to_police]"

      assert_select "input#vispdat_talked_to_police_refused[name=?]", "vispdat[talked_to_police_refused]"

      assert_select "input#vispdat_jail[name=?]", "vispdat[jail]"

      assert_select "input#vispdat_jail_refused[name=?]", "vispdat[jail_refused]"

      assert_select "input#vispdat_attacked[name=?]", "vispdat[attacked]"

      assert_select "input#vispdat_attacked_refused[name=?]", "vispdat[attacked_refused]"

      assert_select "input#vispdat_threatened[name=?]", "vispdat[threatened]"

      assert_select "input#vispdat_threatened_refused[name=?]", "vispdat[threatened_refused]"

      assert_select "input#vispdat_legal_issue[name=?]", "vispdat[legal_issue]"

      assert_select "input#vispdat_legal_issue_refused[name=?]", "vispdat[legal_issue_refused]"

      assert_select "input#vispdat_tricked[name=?]", "vispdat[tricked]"

      assert_select "input#vispdat_tricked_refused[name=?]", "vispdat[tricked_refused]"

      assert_select "input#vispdat_risky[name=?]", "vispdat[risky]"

      assert_select "input#vispdat_risky_refused[name=?]", "vispdat[risky_refused]"

      assert_select "input#vispdat_owe_money[name=?]", "vispdat[owe_money]"

      assert_select "input#vispdat_owe_money_refused[name=?]", "vispdat[owe_money_refused]"

      assert_select "input#vispdat_receive_money[name=?]", "vispdat[receive_money]"

      assert_select "input#vispdat_receive_money_refused[name=?]", "vispdat[receive_money_refused]"

      assert_select "input#vispdat_planned_activities[name=?]", "vispdat[planned_activities]"

      assert_select "input#vispdat_planned_activities_refused[name=?]", "vispdat[planned_activities_refused]"

      assert_select "input#vispdat_basic_needs[name=?]", "vispdat[basic_needs]"

      assert_select "input#vispdat_basic_needs_refused[name=?]", "vispdat[basic_needs_refused]"

      assert_select "input#vispdat_abusive_relationship[name=?]", "vispdat[abusive_relationship]"

      assert_select "input#vispdat_abusive_relationship_refused[name=?]", "vispdat[abusive_relationship_refused]"

      assert_select "input#vispdat_leave_due_to_health[name=?]", "vispdat[leave_due_to_health]"

      assert_select "input#vispdat_leave_due_to_health_refused[name=?]", "vispdat[leave_due_to_health_refused]"

      assert_select "input#vispdat_chronic_health[name=?]", "vispdat[chronic_health]"

      assert_select "input#vispdat_chronic_health_refused[name=?]", "vispdat[chronic_health_refused]"

      assert_select "input#vispdat_hiv_program_interest[name=?]", "vispdat[hiv_program_interest]"

      assert_select "input#vispdat_hiv_program_interest_refused[name=?]", "vispdat[hiv_program_interest_refused]"

      assert_select "input#vispdat_physical_disabilities[name=?]", "vispdat[physical_disabilities]"

      assert_select "input#vispdat_physical_disabilities_refused[name=?]", "vispdat[physical_disabilities_refused]"

      assert_select "input#vispdat_avoid_help[name=?]", "vispdat[avoid_help]"

      assert_select "input#vispdat_avoid_help_refused[name=?]", "vispdat[avoid_help_refused]"

      assert_select "input#vispdat_pregnant[name=?]", "vispdat[pregnant]"

      assert_select "input#vispdat_pregnant_refused[name=?]", "vispdat[pregnant_refused]"

      assert_select "input#vispdat_substance_eviction[name=?]", "vispdat[substance_eviction]"

      assert_select "input#vispdat_substance_eviction_refused[name=?]", "vispdat[substance_eviction_refused]"

      assert_select "input#vispdat_substance_housing[name=?]", "vispdat[substance_housing]"

      assert_select "input#vispdat_substance_housing_refused[name=?]", "vispdat[substance_housing_refused]"

      assert_select "input#vispdat_housing_mental[name=?]", "vispdat[housing_mental]"

      assert_select "input#vispdat_housing_mental_refused[name=?]", "vispdat[housing_mental_refused]"

      assert_select "input#vispdat_housing_head_injury[name=?]", "vispdat[housing_head_injury]"

      assert_select "input#vispdat_housing_head_injury_refused[name=?]", "vispdat[housing_head_injury_refused]"

      assert_select "input#vispdat_housing_learning[name=?]", "vispdat[housing_learning]"

      assert_select "input#vispdat_housing_learning_refused[name=?]", "vispdat[housing_learning_refused]"

      assert_select "input#vispdat_brain_issues[name=?]", "vispdat[brain_issues]"

      assert_select "input#vispdat_brain_issues_refused[name=?]", "vispdat[brain_issues_refused]"

      assert_select "input#vispdat_not_taking_medications[name=?]", "vispdat[not_taking_medications]"

      assert_select "input#vispdat_not_taking_medications_refused[name=?]", "vispdat[not_taking_medications_refused]"

      assert_select "input#vispdat_sell_medications[name=?]", "vispdat[sell_medications]"

      assert_select "input#vispdat_sell_medications_refused[name=?]", "vispdat[sell_medications_refused]"

      assert_select "input#vispdat_trauma[name=?]", "vispdat[trauma]"

      assert_select "input#vispdat_trauma_refused[name=?]", "vispdat[trauma_refused]"

      assert_select "input#vispdat_find_location[name=?]", "vispdat[find_location]"

      assert_select "input#vispdat_find_time[name=?]", "vispdat[find_time]"

      assert_select "input#vispdat_find_period[name=?]", "vispdat[find_period]"

      assert_select "input#vispdat_phone[name=?]", "vispdat[phone]"

      assert_select "input#vispdat_email[name=?]", "vispdat[email]"

      assert_select "input#vispdat_picture[name=?]", "vispdat[picture]"

      assert_select "input#vispdat_picture_refused[name=?]", "vispdat[picture_refused]"
    end
  end
end

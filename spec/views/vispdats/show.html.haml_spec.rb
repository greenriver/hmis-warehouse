require 'rails_helper'

RSpec.describe "vispdats/show", type: :view do
  before(:each) do
    @vispdat = assign(:vispdat, Vispdat.create!(
      :first_name => "First Name",
      :nickname => "Nickname",
      :last_name => "Last Name",
      :language => 2,
      :ssn => "Ssn",
      :consent => false,
      :where_sleep => 3,
      :where_sleep_other => "Sleep Other",
      :where_sleep_refused => false,
      :years_homeless => 4,
      :years_homeless_refused => false,
      :episodes_homeless => 5,
      :episodes_homeless_refused => false,
      :emergency_healthcare => 6,
      :emergency_healthcare_refused => false,
      :ambulance => 7,
      :ambulance_refused => false,
      :inpatient => 8,
      :inpatient_refused => false,
      :crisis_service => 9,
      :crisis_service_refused => false,
      :talked_to_police => 10,
      :talked_to_police_refused => false,
      :jail => 11,
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
      :find_location => "Find Location",
      :find_time => "Find Time",
      :find_period => 12,
      :phone => "Phone",
      :email => "Email",
      :picture => false,
      :picture_refused => false,
      score: 0
    ))
  end

  skip "renders attributes in <p>" do
    render
    expect(rendered).to match(/First Name/)
    expect(rendered).to match(/Nickname/)
    expect(rendered).to match(/Last Name/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/Ssn/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/3/)
    expect(rendered).to match(/Where Sleep Other/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/4/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/5/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/6/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/7/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/8/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/9/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/10/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/11/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/Find Location/)
    expect(rendered).to match(/Find Time/)
    expect(rendered).to match(/12/)
    expect(rendered).to match(/Phone/)
    expect(rendered).to match(/Email/)
    expect(rendered).to match(/false/)
    expect(rendered).to match(/false/)
  end
end

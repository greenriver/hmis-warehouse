FactoryGirl.define do
  factory :hud_chronic do
    date "2017-10-26"
    client nil
    days_in_last_three_years 1
    months_in_last_three_years 1
    individual false
    age 1
    homeless_since "2017-10-26"
    dmh false
    trigger "MyString"
    project_names "MyString"
  end
end

FactoryGirl.define do
  factory :date_range, class: 'Filters::DateRange' do
    start Date.parse('2019-01-01')
    add_attribute(:end) { Date.parse('2019-03-31') }
  end

  factory :homeless_youth_report, class: 'GrdaWarehouse::WarehouseReports::Youth::HomelessYouthReport' do
    transient do
      date_range { FactoryGirl.build :date_range }
    end
    initialize_with { GrdaWarehouse::WarehouseReports::Youth::HomelessYouthReport.new(date_range) }
  end

  factory :intake, class: 'GrdaWarehouse::YouthIntake::Entry' do
    sequence(:client_id)
    staff_name 'RSpec'
    staff_email 'nobody@example.com'
    unaccompanied 'No'
    street_outreach_contact 'No'
    housing_status 'Unknown'
    other_agency_involvement 'No'
    owns_cell_phone 'No'
    secondary_education 'Unknown'
    attending_college 'No'
    health_insurance 'No'
    requesting_financial_assistance 'No'
    staff_believes_youth_under_24 'Yes'
    client_gender 0
    client_lgbtq 'No'
    client_race ['RaceNone']
    client_ethnicity 0
    client_primary_language 'Unknown'
    pregnant_or_parenting 'No'
    disabilities ['None']
    needs_shelter 'No'
    in_stable_housing 'No'
    youth_experiencing_homelessness_at_start 'No'
    how_hear 'Example'
    turned_away false
  end

  trait :existing_intake do
    engagement_date { Date.parse('2018-12-31') }
  end

  trait :new_intake do
    engagement_date { Date.parse('2019-01-01') }
  end

  trait :street_outreach_contact do
    street_outreach_contact 'Yes'
  end

  trait :homeless do
    housing_status 'Experiencing homelessness: couch surfing'
  end

  trait :at_risk do
    housing_status 'At risk of homelessness'
  end

  trait :homeless_at_start do
    youth_experiencing_homelessness_at_start 'Yes'
  end

  factory :case_management, class: 'GrdaWarehouse::Youth::YouthCaseManagement' do
    activity 'Prevention'
  end

  trait :existing_case_management do
    engaged_on { Date.parse('2018-12-31') }
  end

  trait :new_case_management do
    engaged_on { Date.parse('2019-01-01') }
  end
end
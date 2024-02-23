###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaReports::CsgEngage
  class HouseholdMember < Base
    attr_accessor :enrollment, :number

    def initialize(enrollment, number)
      @number = number
      @enrollment = enrollment
    end

    field(:temporary_family_number) { enrollment.household_id }
    field(:household_member_identifier) { enrollment.personal_id }
    field(:temporary_person_number_in_family) { number }
    field(:social_security_number) { client.ssn }
    field(:last_name) { client.last_name }
    field(:first_name) { client.first_name }
    field(:middle_initial) { client.middle_name&.first }
    field(:name_suffix) { client.name_suffix }
    field(:date_of_birth_month) { client.dob&.month }
    field(:date_of_birth_date) { client.dob&.day }
    field(:date_of_birth_year) { client.dob&.year }
    field(:gender) { 'TODO' }
    field(:disabling_condition, label: 'Disabling Conditon (Disabled)') do
      value = nil
      value = true if enrollment.disabling_condition == 1
      value = false if enrollment.disabling_condition == 0
      boolean_string(value, allow_unknown: true)
    end
    field(:military_status) { 'TODO' }
    field(:health_insurance_source) { 'TODO' }
    field(:race_ethnicity, label: 'Race/Ethnicity') { 'TODO' }
    field(:income_codes) { 'TODO' }
    field(:monthly_income) { client.income_benefits.sum(:total_monthly_income) }
    field(:snap, label: 'SNAP (Food Stamps)') { 'TODO' }
    field(:wic, label: 'WIC') { 'TODO' }
    field(:unknown_non_cash_benfit, label: 'Unknown/not reported Non-Cash Benefit') { 'TODO' }
    field(:no_non_cash_benefit, label: 'No Non-Cash Benefit') { 'TODO' }
    field(:language_spoken) { 'TODO' }
    field(:head_of_household) { boolean_string(enrollment.relationship_to_hoh == 1) }
    field(:income) do
      client.income_benefits.map do |income_benefit|
        MaReports::CsgEngage::Income.new(income_benefit)
      end
    end
    field(:services) do
      client.services.map do |service|
        MaReports::CsgEngage::Service.new(service)
      end
    end

    private

    def client
      enrollment.client
    end
  end
end

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

    field('Temporary Family Member') { enrollment.household_id }
    field('Household Member Identifier') { enrollment.personal_id }
    field('Temporary Person Number in Family') { number }

    subfield('Household Member') do
      field('Social Security Number') { client.ssn }
      field('Last Name') { client.last_name }
      field('First Name') { client.first_name }
      field('Middle Initial') { client.middle_name&.first }
      field('Name Suffix') { client.name_suffix }
      field('Date Of Birth Month') { client.dob&.month }
      field('Date Of Birth Date') { client.dob&.day }
      field('Date Of Birth Year') { client.dob&.year }
      field('Gender') { 'TODO' }
      field('Head Of Household') { boolean_string(enrollment.relationship_to_hoh == 1) }
    end

    subfield('CSBG Data') do
      field('Disabling Condition (Disabled)') do
        value = nil
        value = true if enrollment.disabling_condition == 1
        value = false if enrollment.disabling_condition == 0
        boolean_string(value, allow_unknown: true)
      end
      field('Military Status') { 'TODO' }
      field('Health Insurance Source') { 'TODO' }
      field('Race/Ethnicity') { 'TODO' }
      field('Income Codes') { 'TODO' }
      field('Monthly Income') { client.income_benefits.sum(:total_monthly_income) }
      field('SNAP (Food Stamps)') { 'TODO' }
      field('WIC') { 'TODO' }
      field('Unknown/not reported Non-Cash Benefit') { 'TODO' }
      field('No Non-Cash Benefit') { 'TODO' }
      field('Language Spoken') { 'TODO' }
    end

    field('Income') do
      client.income_benefits.map do |income_benefit|
        MaReports::CsgEngage::Income.new(income_benefit)
      end
    end
    field('Services') do
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

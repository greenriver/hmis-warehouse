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

    # field('Temporary Family Member') { enrollment.household_id }
    field('Household Member Identifier') { enrollment.personal_id }
    # field('Temporary Person Number in Family') { number }

    subfield('Household Member') do
      field('CanSendSurveys')
      field('DOB') { client.dob&.strftime('%m/%d/%Y') }
      field('EmailAddress')
      field('EthnicityCustom')
      field('First Name') { client.first_name }
      field('Gender', method: :gender)
      field('Head Of Household') { boolean_string(enrollment.relationship_to_hoh == 1) }
      field('Individual_EmergencyPhone')
      field('Individual_MobilePhone_CanText')
      field('Is in Household') { 'Y' }
      field('Last Name') { client.last_name }
      field('MI') { client.middle_name&.first }
      field('MobilePhone')
      field('Preferred Contact Method')
      field('Race 1/Ethnicity 1', method: :race_ethnicity)
      field('Race 2/Ethnicity 2')
      field('SocialSecurity') { client.ssn }
      field('Suffix') { client.name_suffix }
    end

    subfield('Household Member CSBG Data') do
      field('Caregiver')
      field('Disabling Condition') do
        value = nil
        value = true if enrollment.disabling_condition == 1
        value = false if enrollment.disabling_condition == 0
        boolean_string(value, allow_unknown: true)
      end
      field('Education Level')
      field('EITC')
      field('Health Insurance Source')
      field('In School, age 0-24')
      field('Insurance')
      field('InsuranceSecondary')
      field('Military Status')
      field('Non-Cash Benefits - ACA Subsidy')
      field('Non-Cash Benefits - Childcare Voucher')
      field('Non-Cash Benefits - LIHEAP')
      field('Non-Cash Benefits - None')
      field('Non-Cash Benefits - Other')
      field('Non-Cash Benefits - SNAP') { boolean_string(latest_income_benefit&.SNAP == 1) }
      field('Non-Cash Benefits - Unknown/not reported')
      field('Non-Cash Benefits - WIC') { boolean_string(latest_income_benefit&.WIC == 1) }
      field('Secondary Health Insurance Source')
      field('Veteran')
      field('Work Status')
    end

    field('Income') do
      next unless latest_income_benefit.present?

      [
        [:TANF, :TANFAmount, { description: 'AFDC/TANF', income_source: 'E' }],
        [:Alimony, :AlimonyAmount, { description: 'Alimony/Spousal Support', income_source: 'Q' }],
        [:ChildSupport, :ChildSupportAmount, { description: 'Child Support', income_source: 'P' }],
        [:Earned, :EarnedAmount, { description: 'Employment', income_source: 'A' }],
        [:PrivateDisability, :PrivateDisabilityAmount, { description: 'Employment Disability', income_source: 'S' }],
        # [:OtherIncomeSource, :OtherIncomeAmount, { description: 'Other', income_source: 'N' }],
        [:Pension, :PensionAmount, { description: 'Pension', income_source: 'I' }],
        [:SocSecRetirement, :SocSecRetirementAmount, { description: 'Social Security Retirement', income_source: 'C' }],
        [:SSDI, :SSDIAmount, { description: 'SSDI', income_source: 'U' }],
        [:SSI, :SSIAmount, { description: 'SSI/SSP', income_source: 'D' }],
        [:GA, :GAAmount, { description: 'State Cash Assistance', income_source: 'F' }],
        [:Unemployment, :UnemploymentAmount, { description: 'Unemployment', income_source: 'G' }],
        [:VADisabilityService, :VADisabilityServiceAmount, { description: 'Veteran Compensation Benefits', income_source: 'H' }],
        [:WorkersComp, :WorkersCompAmount, { description: "Worker's Compensation", income_source: 'J' }],
      ].map do |field, amount_field, attrs|
        next unless latest_income_benefit.send(field) == 1

        MaReports::CsgEngage::Income.new(
          amount: latest_income_benefit.send(amount_field),
          **attrs,
        )
      end.compact
    end

    field('Expense')

    # field('Services') do
    #   client.services.map do |service|
    #     MaReports::CsgEngage::Service.new(service)
    #   end
    # end

    def gender
      positive_fields = gender_fields.select { |_k, v| v == 1 }.keys
      if positive_fields == ['Man']
        'M'
      elsif positive_fields == ['Woman']
        'F'
      # Multi-gendered or any other specified gender
      elsif positive_fields.count > 0
        'O'
      # Unknown gender
      else
        'U'
      end
    end

    def race_ethnicity
      positive_fields = race_fields.select { |k, v| k != 'HispanicLatinaeo' && v == 1 }.keys

      if positive_fields == ['AmIndAKNative']
        ethnicity_code('A', 'B', 'R')
      elsif positive_fields == ['Asian']
        ethnicity_code('C', 'D', 'S')
      elsif positive_fields == ['BlackAfAmerican']
        ethnicity_code('E', 'F', 'T')
      elsif positive_fields == ['NativeHIPacific']
        ethnicity_code('G', 'H', 'U')
      elsif positive_fields == ['White']
        ethnicity_code('I', 'J', 'V')
      # Multi-race
      elsif positive_fields.count > 1
        ethnicity_code('K', 'L', 'Q')
      # Other race
      elsif positive_fields.count > 0
        ethnicity_code('M', 'N', 'X')
      # Unknown race
      else
        ethnicity_code('O', 'P', 'W')
      end
    end

    private

    def ethnicity_code(not_latino_value, latino_value, unknown_value)
      case client.HispanicLatinaeo
      when 1
        latino_value
      when 0
        not_latino_value
      else
        unknown_value
      end
    end

    def client
      @client ||= enrollment.client
    end

    def gender_fields
      client.attributes.slice(*HudUtility2024.gender_id_to_field_name.except(:GenderNone).values.uniq.map(&:to_s))
    end

    def race_fields
      client.attributes.slice(*HudUtility2024.race_id_to_field_name.except(:RaceNone).values.uniq.map(&:to_s))
    end

    def latest_income_benefit
      @latest_income_benefit ||= enrollment.income_benefits.order(:information_date).last
    end
  end
end

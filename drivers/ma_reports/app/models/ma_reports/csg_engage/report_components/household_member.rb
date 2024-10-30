###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaReports::CsgEngage::ReportComponents
  class HouseholdMember < Base
    attr_accessor :enrollment, :number

    INCOME_MAPPINGS = [
      [:TANF, :TANFAmount, { description: 'Temporary Assistance for Needy Families (TANF)', income_source: 'E' }],
      [:Alimony, :AlimonyAmount, { description: 'Alimony and other spousal support', income_source: 'Q' }],
      [:ChildSupport, :ChildSupportAmount, { description: 'Child support', income_source: 'P' }],
      [:Earned, :EarnedAmount, { description: 'All earned income', income_source: 'A' }],
      [:PrivateDisability, :PrivateDisabilityAmount, { description: 'Private disability insurance', income_source: 'S' }],
      [:OtherIncomeSource, :OtherIncomeAmount, { description: 'All other income', income_source: 'N' }],
      [:Pension, :PensionAmount, { description: 'Pension or retirement income from a former job', income_source: 'I' }],
      [:SocSecRetirement, :SocSecRetirementAmount, { description: 'Retirement Income from Social Security', income_source: 'C' }],
      [:SSDI, :SSDIAmount, { description: 'Social Security Disability Insurance (SSDI)', income_source: 'U' }],
      [:SSI, :SSIAmount, { description: 'Supplemental Security Income (SSI)', income_source: 'D' }],
      [:GA, :GAAmount, { description: 'State Cash Assistance', income_source: 'F' }],
      [:Unemployment, :UnemploymentAmount, { description: 'Unemployment Insurance', income_source: 'G' }],
      [:VADisabilityService, :VADisabilityServiceAmount, { description: 'VA Service-Connected Disability Compensation', income_source: 'H' }],
      [:VADisabilityNonService, :VADisabilityNonServiceAmount, { description: 'VA Non-Service-Connected Disability Pension', income_source: 'H' }],
      [:WorkersComp, :WorkersCompAmount, { description: "Worker's Compensation", income_source: 'J' }],
      [:GA, :GAAmount, { description: 'General Assistance (GA)', income_source: 'F' }],
    ].freeze

    def initialize(enrollment, number)
      @number = number
      @enrollment = enrollment
    end

    # field('Temporary Family Member') { enrollment.household_id }
    # field('Household Member Identifier') { enrollment.personal_id }
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
      field('Race 1/Ethnicity 1', method: :race_ethnicity_1)
      field('Race 2/Ethnicity 2', method: :race_ethnicity_2)
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
      field('Health Insurance Source') do
        next '4' unless latest_income_benefit&.InsuranceFromAnySource == 1

        next '1' if latest_income_benefit&.PrivatePay == 1
        next '3' if latest_income_benefit&.Medicaid == 1
        next '2' if latest_income_benefit&.Medicare == 1
        next '8' if latest_income_benefit&.SCHIP == 1
        next '7' if latest_income_benefit&.VAMedicalServices == 1
        next '10' if latest_income_benefit&.EmployerProvided == 1
        next '10' if latest_income_benefit&.COBRA == 1
        next '9' if latest_income_benefit&.StateHealthIns == 1

        'U'
      end
      field('In School, age 0-24')
      field('Insurance') { boolean_string(latest_income_benefit&.InsuranceFromAnySource == 1) }
      field('InsuranceSecondary')
      field('Military Status') { client.veteran_status == 1 ? '1' : nil }
      field('Non-Cash Benefits - ACA Subsidy')
      field('Non-Cash Benefits - Childcare Voucher')
      field('Non-Cash Benefits - LIHEAP')
      field('Non-Cash Benefits - None') { latest_income_benefit&.BenefitsFromAnySource == 0 }
      field('Non-Cash Benefits - Other')
      field('Non-Cash Benefits - SNAP') { latest_income_benefit&.SNAP == 1 }
      field('Non-Cash Benefits - Unknown/not reported') { ![1, 0].include?(latest_income_benefit&.BenefitsFromAnySource) }
      field('Non-Cash Benefits - WIC') { latest_income_benefit&.WIC == 1 }
      field('Secondary Health Insurance Source')
      field('Veteran') { boolean_string(client.VeteranStatus == 1) }
      field('Work Status')
    end

    field('Income') do
      next unless latest_income_benefit.present?

      INCOME_MAPPINGS.map do |field, amount_field, attrs|
        next unless latest_income_benefit.send(field) == 1

        MaReports::CsgEngage::ReportComponents::Income.new(
          amount: latest_income_benefit.send(amount_field).to_i * 12,
          **attrs,
        )
      end.compact
    end

    # field('Expense')

    field('Services') do
      latest_service = enrollment.services.max_by(&:DateProvided)

      if latest_service.present?
        [MaReports::CsgEngage::ReportComponents::Service.new(latest_service)]
      else
        [
          {
            'Service' => {
              'ServiceDateTimeBegin' => enrollment.EntryDate&.strftime('%m/%d/%Y'),
              'ServiceDateTimeEnd' => enrollment.exit&.ExitDate&.strftime('%m/%d/%Y'),
              'ServiceProvided' => 'Project Enrollment',
            },
          },
        ]
      end
    end

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

    def race_ethnicity_1
      race_fields = defined_race_fields
      if race_fields.count == 2
        map_race_ethnicity([race_fields.first])
      else
        map_race_ethnicity(race_fields)
      end
    end

    def race_ethnicity_2
      race_fields = defined_race_fields
      map_race_ethnicity([race_fields.second]) if race_fields.count == 2
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

    def defined_race_fields
      race_fields.select { |k, v| k != 'HispanicLatinaeo' && v == 1 }.keys.sort
    end

    def map_race_ethnicity(positive_fields)
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

    def client
      @client ||= enrollment.client
    end

    def gender_fields
      client.attributes.slice(*HudUtility2024.gender_id_to_field_name.values.reject { |v| v == :GenderNone }.uniq.map(&:to_s))
    end

    def race_fields
      client.attributes.slice(*HudUtility2024.race_id_to_field_name.values.reject { |v| v == :RaceNone }.uniq.map(&:to_s))
    end

    def latest_income_benefit
      @latest_income_benefit ||= enrollment.income_benefits.max_by(&:information_date)
    end
  end
end

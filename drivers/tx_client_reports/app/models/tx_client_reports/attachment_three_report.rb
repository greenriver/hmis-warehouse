###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module TxClientReports
  class AttachmentThreeReport
    include ::Filter::FilterScopes
    include ArelHelper

    def initialize(filter)
      @filter = filter
    end

    def attachment_three_headers
      [
        'Row Number',
        'Warehouse ID',
        'Project Name',
        'Date of First Service',
        # 'Report Start Date',
        # 'Entry Started after Report Start',
        'Fort Worth Resident?',
        'Service Location',
        'Name',
        'Street Address',
        'Age',
        'Male',
        'Female',
        'Hispanic/Latin(a)(o)(x)',
        'Non-Hispanic/Non-Latin(a)(o)(x)',
        'American Indian, Alaska Native, or Indigenous',
        'Asian or Asian American',
        'Black, African American, or African',
        'Native Hawaiian or Pacific Islander',
        'White',
        'American Indian, Alaska Native, or Indigenous and White',
        'Black, African American, or African and White',
        'American Indian, Alaska Native, or Indigenous and White and Black, African American, or African',
        'Other Multiple Race Combinations',
        'Disabled (Yes)',
        'Disabled (No)',
        'hhsize',
        'HoH Monthly Income',
        'FHOH (Yes)',
        'FHOH (No)',
      ]
    end

    def attachment_three_rows
      rows.map.with_index do |row, index|
        [
          index + 1,
          row[:client_id],
          row[:project_name],
          row[:service_date],
          # row[:report_start],
          # ('X' if row[:entry_after_start]),
          row[:fort_worth_resident],
          row[:service_location],
          row[:client_name],
          row[:street_address],
          row[:age],
          ('1' if row[:genders].include?(0)),
          ('1' if row[:genders].include?(1)),
          ('1' if row[:ethnicity] == 1),
          ('1' if row[:ethnicity] == 0), # rubocop:disable Style/NumericPredicate
          ('1' if row[:races] == ['AmIndAKNative']),
          ('1' if row[:races] == ['Asian']),
          ('1' if row[:races] == ['BlackAfAmerican']),
          ('1' if row[:races] == ['NativeHIPacific']),
          ('1' if row[:races] == ['White']),
          ('1' if row[:races].sort == ['White', 'AmIndAKNative'].sort),
          ('1' if row[:races].sort == ['White', 'BlackAfAmerican'].sort),
          ('1' if row[:races].sort == ['AmIndAKNative', 'BlackAfAmerican'].sort),
          ('1' unless row[:races].sort.in?(known_race_categories)),
          ('1' if row[:disabled]),
          ('1' unless row[:disabled]),
          row[:hh_size],
          row[:income],
          ('1' if row[:female_hoh]),
          ('1' unless row[:female_hoh]),
        ]
      end
    end

    def household_report_headers
      [
        'Row Number',
        'Warehouse ID',
        'Project Name',
        'Date of First Service',
        # 'Report Start Date',
        'Entry Started after Report Start',
        'Household Zip Code',
        'Household County',
        'Household Size',
        'HoH Monthly Income',
        'AMI %',
        'Gender of Applicant',
        'Race of Household',
        'Ethnicity of Household',
        'Veteran in Household?',
        'Older Adult (62+) in household?',
        'Children under 18 in household?',
        'Person with a disability in household?',
        'Did the HH stay in HSS funded hotel/motel?',
        'Short-term Payments for Hotels/Motels ($)',
        'Rent and Pet Rent Deposits ($)',
        'Utility Deposits ($)',
        'Landlord Incentives ($)',
      ]
    end

    def household_report_rows
      rows.map.with_index do |row, index|
        [
          index + 1,
          row[:client_id],
          row[:project_name],
          row[:service_date],
          (if row[:entry_after_start] then 'Yes' else 'No' end),
          '', # zipcode
          '', # county
          row[:hh_size],
          row[:income],
          '', # % AMI
          row[:genders].map { |k| ::HUD.gender(k) }.join(', '),
          row[:races].map { |f| ::HUD.race(f) }.join(', '),
          ::HUD.ethnicity(row[:ethnicity]),
          (if row[:any_veterans] then 'Yes' else 'No' end),
          (if row[:over_62_in_household] then 'Yes' else 'No' end),
          (if row[:child_in_household] then 'Yes' else 'No' end),
          (if row[:disability_in_household] then 'Yes' else 'No' end),
          '', # hotel/motel
          '', # short-term payments
          '', # rent
          '', # utility
          '', # landlord
        ]
      end
    end

    private def known_race_categories
      @known_race_categories ||= [
        ['AmIndAKNative'],
        ['Asian'],
        ['BlackAfAmerican'],
        ['NativeHIPacific'],
        ['White'],
        ['AmIndAKNative', 'White'].sort,
        ['BlackAfAmerican', 'White'].sort,
        ['BlackAfAmerican', 'AmIndAKNative'].sort,
      ].freeze
    end

    def rows
      return [] unless @filter.project_ids.any? || @filter.project_group_ids.any?

      enrollments = enrollment_scope.
        preload(
          service_history_enrollment_for_head_of_household: { enrollment: :income_benefits_at_entry },
          project: :project_cocs,
          household_enrollments: :client,
        ).
        where(client_id: client_ids).
        order(first_date_in_program: :desc). # index by uses the last value, so this selects the oldest enrollment
        index_by(&:client_id)

      client_scope.map do |client|
        enrollment = enrollments[client.id]
        project = enrollment.project
        hoh_income = enrollment.
          service_history_enrollment_for_head_of_household&.
          enrollment&.
          income_benefits_at_entry&.
          TotalMonthlyIncome
        household = if enrollment.household_id.present?
          enrollment.household_enrollments&.map(&:client)
        else
          [client]
        end
        {
          project_id: project.id,
          project_name: project.ProjectName,
          service_date: enrollment.first_date_in_program,
          report_start: @filter.start,
          entry_after_start: enrollment.first_date_in_program > @filter.start,
          fort_worth_resident: nil, # leave blank
          service_location: nil, # leave blank
          client_name: client.name,
          client_id: client.id,
          street_address: enrollment.project.project_cocs&.first&.Address1, # Shelter address
          age: enrollment.age, # Age at project entry to keep report stable
          genders: client.gender_multi,
          ethnicity: client.Ethnicity,
          races: client.race_fields,
          race_description: client.race_description,
          disabled: client_disabled?(client),
          hh_size: household.count,
          income: hoh_income, # HoH income
          female_hoh: enrollment.head_of_household? && client.Female == 1,
          any_veterans: household.map(&:VeteranStatus).any?(1),
          over_62_in_household: household.map(&:age).any? { |age| age.present? && age >= 62 },
          child_in_household: household.map(&:age).any? { |age| age.present? && age < 18 },
          disability_in_household: enrollment.household_enrollments.map(&:DisablingCondition).any?(1),
        }
      end.sort_by { |row| row[:service_date] }
    end

    private def client_disabled?(client)
      disabled_client_ids.include?(client.id)
    end

    private def disabled_client_ids
      @disabled_client_ids ||= GrdaWarehouse::Hud::Client.disabled_client_scope.
        where(id: client_ids).
        pluck(:id)
    end

    private def enrollment_scope
      scope = filter_for_user_access(GrdaWarehouse::ServiceHistoryEnrollment.entry)
      scope = filter_for_projects(scope)
      scope = filter_for_range(scope)

      scope
    end

    private def client_ids
      @client_ids ||= client_scope.pluck(:id)
    end

    private def client_scope
      client_source.
        distinct.
        joins(:service_history_enrollments).
        where(id: enrollment_scope.distinct.pluck(:client_id))
    end

    private def client_source
      GrdaWarehouse::Hud::Client.destination
    end
  end
end

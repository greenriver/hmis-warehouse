###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
# frozen_string_literal: true

require 'shared_contexts/hud_enrollment_builders'

RSpec.shared_context 'HUD pit context', shared_context: :metadata do
  include_context 'HUD enrollment builders'

  # RelationshipToHoH codes based on HUD HMIS specifications
  let(:rel_hoh) { 1 } # Self (Head of Household)
  let(:rel_spouse) { 3 } # Head of Household's spouse or partner
  let(:rel_child) { 2 } # Head of Household's child
  let(:rel_other_adult) { 4 } # Other relation member (adult)

  let(:pit_date) { '2024-01-28'.to_date }
  let(:user) { User.setup_system_user }
  let(:filter_params) do
    {
      on: pit_date,
      start: pit_date.beginning_of_year,
      end: pit_date.end_of_year,
      user_id: user.id,
      coc_codes: ['MA-500'],
      enforce_one_year_range: false,
      require_service_during_range: false,
      project_type_codes: HudUtility2024.homeless_project_type_codes,
    }
  end

  # FY2025 PIT ROW Definitions
  # This hash maps question numbers (sheet names) to a hash of descriptive cell names (symbols)
  # and their corresponding row number
  PIT_ROW_DEFINITIONS_FY2025 = {
    HudPit::Generators::Pit::Fy2025::ParentingYouth::QUESTION_NUMBER => {
      total_households: '2', # Total households for this question
      total_parents: '4',                    # Number of parenting youth (youth parents only) - matches user's key
      total_children: '5',                   # Number of children in parenting youth households - matches user's key
      parenting_youth_under_18: '6',         # Number of parenting youth (under age 18)
      children_with_parents_under_18: '7',   # Number of children in households with parenting youth (under age 18)
      parenting_youth_18_24: '8',            # Number of parenting youth (age 18-24)
      children_with_parents_18_to_24: '9',   # Number of children in households with parenting youth (age 18-24)
    },
    HudPit::Generators::Pit::Fy2025::Adults::QUESTION_NUMBER => {
      total_households: '2', # Total households composed of adults only
      total_persons: '3',    # Total persons in households composed of adults only
      persons_18_24: '4',    # Persons age 18-24 in adult-only households
      persons_25_34: '5',    # Persons age 25-34 in adult-only households
      persons_35_44: '6',    # Persons age 35-44 in adult-only households
      persons_45_54: '7',    # Persons age 45-54 in adult-only households
      persons_55_64: '8',    # Persons age 55-64 in adult-only households
      persons_65_plus: '9',  # Persons age 65+ in adult-only households
    },
    HudPit::Generators::Pit::Fy2025::Children::QUESTION_NUMBER => {
      total_households: '2', # Total households composed of children only
      total_persons: '3',    # Total persons in households composed of children only
    },
    HudPit::Generators::Pit::Fy2025::AdultAndChild::QUESTION_NUMBER => {
      total_households: '2', # Total households with at least one adult and one child
      total_persons: '3',    # Total persons in households with adults and children
      persons_under_18: '4', # Persons under age 18 in adult_and_child households
      persons_18_24: '5',    # Persons age 18-24 in adult_and_child households
      persons_25_34: '6',    # Persons age 18-24 in adult_and_child households
      # Race/Ethnicity Counts (Rows 11-25 for this question sheet)
      am_ind_ak_native_only_non_hisp: '11',
      am_ind_ak_native_only_hisp: '12',
      asian_only_non_hisp: '13',
      asian_only_hisp: '14',
      black_only_non_hisp: '15',
      black_only_hisp: '16',
      hispanic_latino_only: '17',
      middle_eastern_north_african_only_non_hisp: '18',
      middle_eastern_north_african_only_hisp: '19',
      native_hawaiian_pacific_islander_only_non_hisp: '20',
      native_hawaiian_pacific_islander_only_hisp: '21',
      white_only_non_hisp: '22',
      white_only_hisp: '23',
      multi_racial_hisp: '24',            # Multi-Racial AND Hispanic/Latina/e/o
      multi_racial_non_hisp: '25',        # Multi-Racial AND NOT Hispanic/Latina/e/o
      chronically_homeless_households: '26', # Chronically Homeless Households in adult_and_child
      chronically_homeless_persons: '27',    # Chronically Homeless Persons in adult_and_child
    },
    HudPit::Generators::Pit::Fy2025::AdditionalHomelessPopulations::QUESTION_NUMBER => {
      adults_with_mental_illness: '2',
      adults_with_substance_use: '3',
      adults_with_hiv: '4',
      adult_dv_survivors: '5',
    },
    HudPit::Generators::Pit::Fy2025::VeteranAdults::QUESTION_NUMBER => {
      total_persons: '3',
      total_veterans: '4',
    },
  }.freeze

  # currently we only test ES
  PROJECT_TYPE_COLUMNS = {
    es: 'B', # Emergency Shelter (ES, ES-EE)
    # th: 'C', # Transitional Housing
    # sh: 'D', # Safe Haven
  }.freeze

  def report_value(report, question:, row:, project_type_key: :es)
    question_map = PIT_ROW_DEFINITIONS_FY2025.fetch(question)
    column = PROJECT_TYPE_COLUMNS.fetch(project_type_key)
    row_number = question_map.fetch(row)
    cell = "#{column}#{row_number}"

    answer = report.answer(question: question, cell: cell)
    answer.value
  end

  def run_report(filter: filter_params, questions:)
    # Build ServiceHistoryEnrollments
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
    # Calculate chronic status
    GrdaWarehouse::ChEnrollment.maintain!

    klass = HudPit::Generators::Pit::Fy2025::Generator
    report = ::HudReports::ReportInstance.from_filter(
      ::Filters::HudFilterBase.new(filter),
      klass.title,
      build_for_questions: questions,
    )
    # Uncomment to get detail CSVs
    # klass.write_detail_path = 'tmp/pit_'
    generator = klass.new(report)
    generator.run!

    result = generator.report
    result.reload
    result
  end
end

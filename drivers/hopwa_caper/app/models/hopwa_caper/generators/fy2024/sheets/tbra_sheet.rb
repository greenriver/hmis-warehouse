###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2024::Sheets
  class TbraSheet < BaseProgramSheet
    QUESTION_NUMBER = 'Q2: TBRA'.freeze
    QUESTION_NUMBERS = ['Q2'].freeze
    CONTENTS = [
      { method: :households_served_sheet, label: 'TBRA Households Served and Expenditures' },
      { method: :other_rental_assistance_sheet, label: 'Other (Non-TBRA) Rental Assistance Households Served and Expenditures' },
      { method: :income_levels_sheet, label: 'Income Levels for Households Served by this Activity' },
      { method: :income_sources_sheet, label: 'Sources of Income for Households Served by this Activity' },
      { method: :medical_insurance, label: 'Medical Insurance for Households Served by this Activity' },
      { method: :health_outcomes_sheet, label: 'Health Outcomes for Households Served by this Activity' },
      { method: :longevity_sheet, label: 'Longevity for Households Served by this Activity' },
      { method: :housing_outcomes_sheet, label: 'Housing Outcomes for Households Served by this Activity' },
    ].freeze

    protected

    def relevant_enrollments
      service_scope = HopwaCaper::Service.where(date_provided: @report.start_date...@report.end_date).hopwa_financial_assistance
      @report.hopwa_caper_enrollments.
        tbra_funder.
        overlapping_range(start_date: @report.start_date, end_date: @report.end_date).
        joins(:services).
        merge(service_scope)
    end

    def relevant_services
      enrolment_scope = HopwaCaper::Enrollment.tbra_funder.overlapping_range(start_date: @report.start_date, end_date: @report.end_date)
      @report.hopwa_caper_services.hopwa_financial_assistance.
        where(date_provided: @report.start_date...@report.end_date).
        joins(:enrollment).merge(enrolment_scope)
    end

    def households_served_sheet(sheet)
      add_household_enrollments_row(sheet, label: 'How many households were served with HOPWA TBRA assistance?', enrollments: relevant_enrollments)

      sheet.append_row(label: 'What were the total HOPWA funds expended for TBRA rental assistance?') do |row|
        row.append_cell_members(
          members: relevant_services.as_report_members,
          value: relevant_services.sum(:fa_amount),
        )
      end
    end

    def other_rental_assistance_sheet(sheet)
      # unclear if this is actually something we can get out of HMIS
      # services = HopwaCaper::Service.where(date_provided: @report.start_date..end_date: @report.end_date).  where(record_type: 151, type_provided: 1)
      # scope = @report.hopwa_caper_enrollments
      #   .not_tbra_funded
      #   .overlapping_range(start_date: @report.start_date, end_date: @report.end_date)
      #   .joins(:services).merge(services)

      # sheet.append_row(label: 'How many total households were served with Other (non-TBRA) Rental Assistance?') do |row|
      #   cell_scope = relevant_enrollments.head_of_household
      #   row.append_cell_members(members: cell_scope.as_report_members)
      # end
    end

    def health_outcomes_sheet(sheet)
      sheet.append_row(label: 'How many HOPWA-eligible individuals served with TBRA this year have ever been prescribed Anti-Retroviral Therapy?') do |row|
        cell_scope = relevant_enrollments.where(ever_perscribed_anti_retroviral_therapy: true)
        row.append_cell_members(members: cell_scope.latest_by_personal_id.as_report_members)
      end

      sheet.append_row(label: 'How many HOPWA-eligible persons served with TBRA have shown an improved viral load or achieved viral suppression?') do |row|
        cell_scope = relevant_enrollments.where(viral_load_supression: true)
        row.append_cell_members(
          members: cell_scope.as_report_members,
          value: cell_scope.latest_by_personal_id.count(:hud_personal_id),
        )
      end
    end

    def longevity_sheet(sheet)
      filters = HopwaCaper::Generators::Fy2024::EnrollmentFilters::LongevityFilter.all
      filters.each do |filter|
        add_household_enrollments_row(
          sheet,
          label: "How many households have been served with TBRA #{filter.label}?",
          enrollments: filter.apply(relevant_enrollments),
        )
      end
    end
  end
end

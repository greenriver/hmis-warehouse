###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# https://files.hudexchange.info/resources/documents/HOPWA-Consolidated-APR-CAPER-User-Manual-Chapter-16.pdf
module HopwaCaper::Generators::Fy2024::Sheets
  class DemographicsAndPriorLivingSituationSheet < Base
    QUESTION_NUMBER = 'Q1: Demographics and Prior Living Situation'.freeze
    QUESTION_NUMBERS = ['Q1'].freeze

    CONTENTS = {
      'Q1A' => 'For each racial category, how many HOPWA-eligible Individuals identified as such?',
      'Q1B' => 'For each racial category, how many other household members (beneficiaries) identified as such?',
      'Q1C' => 'Complete Prior Living Situations for HOPWA-eligible Individuals served by TBRA, P-FBH, ST-TFBH, or PHP',
    }.freeze
    QUESTION_TABLE_NUMBERS = CONTENTS.keys

    def run_question!
      @report.start(QUESTION_NUMBER, 'Q1')

      question_sheet(question: 'Q1') do |sheet|
        demographics_sheet_a(sheet)
        demographics_sheet_b(sheet)
        sheet.append_row(label: nil) # blank row
        demographics_summary(sheet)
        prior_living_situation_sheet(sheet)
      end

      @report.complete(QUESTION_NUMBER)
    end

    protected

    def relevant_enrollments
      program_filter = HopwaCaper::Generators::Fy2024::EnrollmentFilters::ProjectFunderFilter.all_hopwa
      overlapping_enrollments(program_filter.apply(@report.hopwa_caper_enrollments))
    end

    def demographics_sheet_a(sheet)
      scope = relevant_enrollments.where(hopwa_eligible: true)
      demographics_breakdown_table(sheet, enrollment_scope: scope, header: 'Complete the age, gender, race, and ethnicity information for all individuals served with all types of HOPWA assistance.', title: 'A. For each racial category, how many HOPWA-eligible Individuals identified as such?')
    end

    def demographics_sheet_b(sheet)
      scope = relevant_enrollments.where(hopwa_eligible: false)
      demographics_breakdown_table(sheet, enrollment_scope: scope, title: 'B. For each racial category, how many other household members (beneficiaries) identified as such?')
    end

    def demographics_breakdown_table(sheet, enrollment_scope:, header: nil, title:)
      age_filters = HopwaCaper::Generators::Fy2024::EnrollmentFilters::AgeFilter.all
      gender_filters = HopwaCaper::Generators::Fy2024::EnrollmentFilters::GenderFilter.all
      ethnicity_filters = HopwaCaper::Generators::Fy2024::EnrollmentFilters::EthnicityFilter.all
      race_filters = HopwaCaper::Generators::Fy2024::EnrollmentFilters::RaceFilter.all

      if header
        sheet.add_header(col: 'A', label: header)
        gender_filters.each do
          age_filters.each do |_age_filter|
            sheet.add_header(label: '')
          end
        end
        ethnicity_filters.each do
          sheet.add_header(label: '')
        end
      end

      sheet.append_row(label: title) do |row|
        gender_filters.each do |gender_filter|
          age_filters.each do |_age_filter|
            row.append_cell_value(value: gender_filter.label)
          end
        end
        ethnicity_filters.each do |_ethnicity_filter|
          row.append_cell_value(value: 'Of the total number of individuals reported for each racial category, how many also identify as Hispanic or Latinx?')
        end
      end

      sheet.append_row(label: nil) do |row|
        row.append_cell_value(value: nil)
        gender_filters.each do |gender_filter|
          age_filters.each do |age_filter|
            row.append_cell_value(value: "#{gender_filter.label} #{age_filter.label}")
          end
        end
        ethnicity_filters.each do |ethnicity_filter|
          row.append_cell_value(value: ethnicity_filter.label)
        end
      end

      # add rows
      race_filters.each do |race_filter|
        sheet.append_row(label: race_filter.label) do |row|
          # add cells for race/gender/age
          gender_filters.each do |gender_filter|
            age_filters.each do |age_filter|
              filters = [race_filter, age_filter, gender_filter]
              cell_scope = filters.reduce(enrollment_scope) { |scope, filter| filter.apply(scope) }
              row.append_cell_members(members: cell_scope.latest_by_distinct_client_id.as_report_members)
            end
          end
          # add cells race/ethnicity
          ethnicity_filters.each do |ethnicity_filter|
            filters = [race_filter, ethnicity_filter]
            cell_scope = filters.reduce(enrollment_scope) { |scope, filter| filter.apply(scope) }
            row.append_cell_members(members: cell_scope.latest_by_distinct_client_id.as_report_members)
          end
        end
      end
    end

    def demographics_summary(sheet)
      relevant_enrollments.where(hopwa_eligible: true).tap do |scope|
        sheet.append_row(label: 'Total number of HOPWA-eligible individuals served with HOPWA assistance:') do |row|
          row.append_cell_members(members: scope.latest_by_distinct_client_id.as_report_members)
        end
      end
      relevant_enrollments.where(hopwa_eligible: false).tap do |scope|
        sheet.append_row(label: 'Total number of other household members (beneficiaries) served with HOPWA assistance:') do |row|
          row.append_cell_members(members: scope.latest_by_distinct_client_id.as_report_members)
        end

        sheet.append_row(label: 'How many other household members (beneficiaries) are HIV+?') do |row|
          cell_scope = scope.where(hiv_positive: true)
          row.append_cell_members(members: cell_scope.latest_by_distinct_client_id.as_report_members)
        end

        sheet.append_row(label: 'How many other household members (beneficiaries) are HIV negative or have an unknown HIV status? ') do |row|
          cell_scope = scope.where(hiv_positive: false)
          row.append_cell_members(members: cell_scope.latest_by_distinct_client_id.as_report_members)
        end
      end
    end

    def prior_living_situation_sheet(sheet)
      # NOTE: currently we do not support P-FBH or ST-TFBH
      # sheet.append_row(label: 'Complete Prior Living Situations for HOPWA-eligible Individuals served by TBRA, P-FBH, ST-TFBH, or PHP')
      sheet.append_row(label: 'Complete Prior Living Situations for HOPWA-eligible Individuals served by TBRA or PHP')
      program_filter = HopwaCaper::Generators::Fy2024::EnrollmentFilters::ProjectFunderFilter.tbra_or_php_hopwa
      scope = program_filter.apply(relevant_enrollments).where(hopwa_eligible: true)

      sheet.append_row(label: 'How many HOPWA-eligible individuals continued receiving HOPWA assistance from the previous year?') do |row|
        cell_scope = scope.where(entry_date: ...@report.start_date)
        row.append_cell_members(members: cell_scope.latest_by_distinct_client_id.as_report_members)
      end

      sheet.append_row(label: 'How many individuals newly receiving HOPWA assistance came from:')

      filters = HopwaCaper::Generators::Fy2024::EnrollmentFilters::PriorLivingSituationFilter.all
      filters.each do |filter|
        sheet.append_row(label: filter.label) do |row|
          # "new" enrollments are those that start within this reporing period
          cell_scope = filter.apply(scope.where(entry_date: @report.start_date..))
          row.append_cell_members(members: cell_scope.latest_by_distinct_client_id.as_report_members)
        end
      end

      newly_homeless_scope = scope.where(entry_date: @report.start_date..).where(prior_living_situation: [101, 116, 302])

      sheet.append_row(label: 'How many individuals newly receiving HOPWA assistance during this program year reported a prior living situation of homelessness [place not for human habitation, emergency shelter, transitional housing]:') do |row|
        row.append_cell_members(members: newly_homeless_scope.as_report_members)
      end

      sheet.append_row(label: 'Also meet the definition of experiencing chronic homelessness?') do |row|
        cell_scope = newly_homeless_scope.where(chronically_homeless: true)
        row.append_cell_members(members: cell_scope.latest_by_distinct_client_id.as_report_members)
      end

      sheet.append_row(label: 'Also were veterans?') do |row|
        cell_scope = newly_homeless_scope.where(veteran: true)
        row.append_cell_members(members: cell_scope.latest_by_distinct_client_id.as_report_members)
      end
    end
  end
end

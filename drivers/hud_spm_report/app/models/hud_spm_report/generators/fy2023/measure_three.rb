###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# HUD SPM Report Generator: Measure 2a and 2b: The Extent to which Persons Who Exit Homelessness
# to Permanent Housing Destinations Return to Homelessness within 6, 12,
# and 24 months.
module HudSpmReport::Generators::Fy2023
  class MeasureThree < MeasureBase
    include ArelHelper

    def self.question_number
      'Measure 3'.freeze
    end

    def self.table_descriptions
      {
        'Measure 3' => 'Number of Persons Experiencing Homelessness',
        '3.1' => 'Change in PIT counts of sheltered and unsheltered persons experiencing homelessness',
        '3.2' => 'Change in annual counts of persons experiencing sheltered homelessness in HMIS',
      }.freeze
    end

    def run_question!
      tables = [
        ['3.1', :run_3_1],
        ['3.2', :run_3_2],
      ]

      @report.start(self.class.question_number, tables.map(&:first))

      tables.each do |name, msg|
        send(msg, name)
      end

      @report.complete(self.class.question_number)
    end

    private def run_3_1(table_name)
      # This is a placeholder table that is intended to be populated from the last submitted PIT
      prepare_table(
        table_name,
        {
          2 => 'Universe: Total PIT Count of sheltered and unsheltered persons',
          3 => 'Emergency Shelter Total',
          4 => 'Safe Haven Total',
          5 => 'Transitional Housing Total',
          6 => 'Total Sheltered Count',
          7 => 'Unsheltered Count',
        },
        {
          'B' => 'Previous FY PIT Count',
          'C' => 'Current FY PIT Count',
          'D' => 'Difference',
        },
      )
    end

    private def run_3_2(table_name)
      prepare_table(
        table_name,
        {
          2 => 'Universe: Unduplicated Total sheltered persons',
          3 => 'Emergency Shelter Total',
          4 => 'Safe Haven Total',
          5 => 'Transitional Housing Total',
        },
        {
          'B' => 'Previous FY',
          'C' => 'Current FY',
          'D' => 'Difference',
        },
      )

      build_m3_2_cell(
        cell: 'C2',
        ee_project_type_codes: [:es_entry_exit, :sh, :th],
        nbn_project_type_codes: [:es_nbn],
        table_name: table_name,
      )
      build_m3_2_cell(
        cell: 'C3',
        ee_project_type_codes: [:es_entry_exit],
        nbn_project_type_codes: [:es_nbn],
        table_name: table_name,
      )
      build_m3_2_cell(
        cell: 'C4',
        ee_project_type_codes: [:sh],
        table_name: table_name,
      )
      build_m3_2_cell(
        cell: 'C5',
        ee_project_type_codes: [:th],
        table_name: table_name,
      )
    end

    def project_type_numbers(project_type_codes)
      project_type_codes.flat_map do |code|
        HudUtility2024.project_type_number_from_code(code)
      end
    end

    def build_m3_2_cell(cell:, ee_project_type_codes:, table_name:, nbn_project_type_codes: nil)
      answer = @report.answer(question: table_name, cell: cell)

      ee_enrollments = enrollment_set.open_during_range(filter.range).
        where(project_type: project_type_numbers(ee_project_type_codes))

      nbn_enrollments = []
      if nbn_project_type_codes.present?
        nbn_enrollments = enrollment_set.
          with_active_method_2_in_range(filter.range).
          where(project_type: project_type_numbers(nbn_project_type_codes)).
          where.not(client_id: ee_enrollments.select(:client_id))
      end

      # construct per-cell universe
      universe = @report.universe(:"m3_2_#{cell.downcase}")
      # add enrollments to universe
      [
        ee_enrollments,
        nbn_enrollments,
      ].each do |spm_enrollments|
        next if spm_enrollments.blank?

        uniq_members = HudSpmReport::Fy2023::SpmEnrollment.one_for_column(
          :entry_date,
          source_arel_table: spm_e_t,
          group_on: :client_id,
          scope: spm_enrollments,
        )
        members = uniq_members.preload(:client).map do |enrollment|
          [enrollment.client, enrollment]
        end
        universe.add_universe_members(members.to_h)
      end

      # add universe to cell
      answer.add_members(universe.members)
      answer.update(summary: universe.members.count)
      answer
    end

    def filter
      ::Filters::HudFilterBase.new(user_id: @report.user.id).update(@report.options)
    end
  end
end

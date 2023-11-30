###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# HUD SPM Report Generator: Measure 2a and 2b: The Extent to which Persons Who Exit Homelessness
# to Permanent Housing Destinations Return to Homelessness within 6, 12,
# and 24 months.
module HudSpmReport::Generators::Fy2024
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

      members = create_universe(:m3_2)

      annual_counts.each do |cell_name, type_numbers|
        included = members.where(spm_e_t[:project_type].in(type_numbers))
        answer = @report.answer(question: table_name, cell: cell_name)

        answer.add_members(included)
        answer.update(summary: included.count)
      end
    end

    def annual_counts
      {
        'C2' => [:es, :sh, :th].map { |code| HudUtility2024.project_type_number_from_code(code) }.flatten,
        'C3' => HudUtility2024.project_type_number_from_code(:es),
        'C4' => HudUtility2024.project_type_number_from_code(:sh),
        'C5' => HudUtility2024.project_type_number_from_code(:th),
      }
    end

    private def create_universe(universe_name)
      filter = ::Filters::HudFilterBase.new(user_id: User.system_user.id).update(@report.options)
      @universe = @report.universe(universe_name)
      open_enrollments = enrollment_set.open_during_range(filter.range)
      open_ee_enrollments = open_enrollments.where.not(project_type: HudUtility2024.project_type_number_from_code(:es_nbn))

      ee_enrollments = HudSpmReport::Fy2024::SpmEnrollment.one_for_column(:entry_date, source_arel_table: spm_e_t, group_on: :client_id, scope: open_ee_enrollments)
      members = ee_enrollments.map do |enrollment|
        [enrollment.client, enrollment]
      end.to_h
      @universe.add_universe_members(members)

      open_nbn_enrollments = open_enrollments.
        with_bed_night_in_range(filter.range).
        where(project_type: HudUtility2024.project_type_number_from_code(:es_nbn)).
        where.not(client_id: ee_enrollments.select(:client_id))
      nbn_enrollments = HudSpmReport::Fy2024::SpmEnrollment.one_for_column(:entry_date, source_arel_table: spm_e_t, group_on: :client_id, scope: open_nbn_enrollments)

      members = nbn_enrollments.map do |enrollment|
        [enrollment.client, enrollment]
      end.to_h
      @universe.add_universe_members(members)

      @universe.members
    end
  end
end

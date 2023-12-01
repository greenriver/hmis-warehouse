###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# HUD SPM Report Generator: Measure 2a and 2b: The Extent to which Persons Who Exit Homelessness
# to Permanent Housing Destinations Return to Homelessness within 6, 12,
# and 24 months.
module HudSpmReport::Generators::Fy2024
  class MeasureFour < MeasureBase
    def self.question_number
      'Measure 4'.freeze
    end

    def self.table_descriptions
      {
        'Measure 4' => 'Employment and Income Growth for Homeless Persons in CoC Program-funded Projects',
        '4.1' => 'Change in earned income for adult system stayers during the reporting period',
        '4.2' => 'Change in non-employment cash income for adult system stayers during the reporting period',
        '4.3' => 'Change in total income for adult system stayers during the reporting period',
        '4.4' => 'Change in earned income for adult system leavers',
        '4.5' => 'Change in non-employment cash income for adult system leavers',
        '4.6' => 'Change in total income for adult system leavers',
      }.freeze
    end

    def run_question!
      tables = [
        ['4.1', :run_4_1],
        ['4.2', :run_4_2],
        ['4.3', :run_4_3],
        ['4.4', :run_4_4],
        ['4.5', :run_4_5],
        ['4.6', :run_4_6],
      ]

      @report.start(self.class.question_number, tables.map(&:first))

      tables.each do |name, msg|
        send(msg, name)
      end

      @report.complete(self.class.question_number)
    end

    COLUMNS = {
      'B' => 'Previous FY',
      'C' => 'Current FY',
      'D' => 'Difference',
    }.freeze

    private def run_4_1(table_name)
      prepare_table(
        table_name,
        {
          2 => 'Universe: Number of adults (system stayers)',
          3 => 'Number of adults with increased earned income',
          4 => 'Percentage of adults who increased earned income',
        },
        COLUMNS,
      )

      answer = @report.answer(question: table_name, cell: 'C2')
      answer.add_members(stayers)
      answer.update(summary: stayers.count)

      answer = @report.answer(question: table_name, cell: 'C3')
      included = stayers.where(
        spm_e_t[:current_earned_income].gt(spm_e_t[:previous_earned_income]).
          and(spm_e_t[:previous_income_benefits_id].not_eq(nil)),
      )
      answer.add_members(included)
      answer.update(summary: included.count)

      answer = @report.answer(question: table_name, cell: 'C4')
      answer.update(summary: percent(included.count, stayers.count))
    end

    private def run_4_2(table_name)
      prepare_table(
        table_name,
        {
          2 => 'Universe: Number of adults (system stayers)',
          3 => 'Number of adults with increased non-employment cash income',
          4 => 'Percentage of adults who increased non-employment cash income',
        },
        COLUMNS,
      )

      answer = @report.answer(question: table_name, cell: 'C2')
      answer.add_members(stayers)
      answer.update(summary: stayers.count)

      answer = @report.answer(question: table_name, cell: 'C3')
      included = stayers.where(
        spm_e_t[:current_non_employment_income].gt(spm_e_t[:previous_non_employment_income]).
        and(spm_e_t[:previous_income_benefits_id].not_eq(nil)),
      )
      answer.add_members(included)
      answer.update(summary: included.count)

      answer = @report.answer(question: table_name, cell: 'C4')
      answer.update(summary: percent(included.count, stayers.count))
    end

    private def run_4_3(table_name)
      prepare_table(
        table_name,
        {
          2 => 'Universe: Number of adults (system stayers)',
          3 => 'Number of adults with increased total income',
          4 => 'Percentage of adults who increased total income',
        },
        COLUMNS,
      )

      answer = @report.answer(question: table_name, cell: 'C2')
      answer.add_members(stayers)
      answer.update(summary: stayers.count)

      answer = @report.answer(question: table_name, cell: 'C3')
      included = stayers.where(
        spm_e_t[:current_total_income].gt(spm_e_t[:previous_total_income]).
        and(spm_e_t[:previous_income_benefits_id].not_eq(nil)),
      )
      answer.add_members(included)
      answer.update(summary: included.count)

      answer = @report.answer(question: table_name, cell: 'C4')
      answer.update(summary: percent(included.count, stayers.count))
    end

    private def run_4_4(table_name)
      prepare_table(
        table_name,
        {
          2 => 'Universe: Number of adults who exited (system leavers)',
          3 => 'Number of adults who exited with increased earned income',
          4 => 'Percentage of adults who increased earned income',
        },
        COLUMNS,
      )

      answer = @report.answer(question: table_name, cell: 'C2')
      answer.add_members(leavers)
      answer.update(summary: leavers.count)

      answer = @report.answer(question: table_name, cell: 'C3')
      included = leavers.where(
        spm_e_t[:current_earned_income].gt(spm_e_t[:previous_earned_income]).
        and(spm_e_t[:previous_income_benefits_id].not_eq(nil)),
      )
      answer.add_members(included)
      answer.update(summary: included.count)

      answer = @report.answer(question: table_name, cell: 'C4')
      answer.update(summary: percent(included.count, leavers.count))
    end

    private def run_4_5(table_name)
      prepare_table(
        table_name,
        {
          2 => 'Universe: Number of adults who exited (system leavers)',
          3 => 'Number of adults who exited with increased non-employment cash income',
          4 => 'Percentage of adults who increased non-employment cash income',
        },
        COLUMNS,
      )

      answer = @report.answer(question: table_name, cell: 'C2')
      answer.add_members(leavers)
      answer.update(summary: leavers.count)

      answer = @report.answer(question: table_name, cell: 'C3')
      included = leavers.where(
        spm_e_t[:current_non_employment_income].gt(spm_e_t[:previous_non_employment_income]).
        and(spm_e_t[:previous_income_benefits_id].not_eq(nil)),
      )
      answer.add_members(included)
      answer.update(summary: included.count)

      answer = @report.answer(question: table_name, cell: 'C4')
      answer.update(summary: percent(included.count, leavers.count))
    end

    private def run_4_6(table_name)
      prepare_table(
        table_name,
        {
          2 => 'Universe: Number of adults who exited (system leavers)',
          3 => 'Number of adults who exited with increased total income',
          4 => 'Percentage of adults who increased total income',
        },
        COLUMNS,
      )

      answer = @report.answer(question: table_name, cell: 'C2')
      answer.add_members(leavers)
      answer.update(summary: leavers.count)

      answer = @report.answer(question: table_name, cell: 'C3')
      included = leavers.where(
        spm_e_t[:current_total_income].gt(spm_e_t[:previous_total_income]).
        and(spm_e_t[:previous_income_benefits_id].not_eq(nil)),
      )
      answer.add_members(included)
      answer.update(summary: included.count)

      answer = @report.answer(question: table_name, cell: 'C4')
      answer.update(summary: percent(included.count, leavers.count))
    end

    private def candidate_stayers(filter)
      enrollment_set.open_during_range(filter.range).
        where(spm_e_t[:age].gteq(18)).
        where(spm_e_t[:eligible_funding].eq(true)).
        where(spm_e_t[:days_enrolled].gteq(365)).
        where(spm_e_t[:exit_date].eq(nil).or(spm_e_t[:exit_date].gt(filter.end)))
    end

    private def stayers
      @stayers = @report.universe(:m4_stayers)
      return @stayers.members if @stayers_computed

      @stayers_computed = true

      filter = ::Filters::HudFilterBase.new(user_id: User.system_user.id).update(@report.options)
      staying_enrollments = candidate_stayers(filter)
      client_enrollments = HudSpmReport::Fy2024::SpmEnrollment.one_for_column(:entry_date, source_arel_table: spm_e_t, group_on: :client_id, scope: staying_enrollments)

      members = client_enrollments.map do |enrollment|
        [enrollment.client, enrollment]
      end.to_h
      @stayers.add_universe_members(members)

      @stayers.members
    end

    private def leavers
      @leavers = @report.universe(:m4_leavers)
      return @leavers.members if @leavers_computed

      @leavers_computed = true

      filter = ::Filters::HudFilterBase.new(user_id: User.system_user.id).update(@report.options)
      stayer_ids = candidate_stayers(filter).pluck(:client_id)

      leaving_enrollments = enrollment_set.open_during_range(filter.range).
        where(spm_e_t[:age].gteq(18)).
        where(spm_e_t[:eligible_funding].eq(true)).
        where(spm_e_t[:exit_date].not_eq(nil).and(spm_e_t[:exit_date].lteq(filter.end))).
        where.not(client_id: stayer_ids)
      client_enrollments = HudSpmReport::Fy2024::SpmEnrollment.one_for_column(:entry_date, source_arel_table: spm_e_t, group_on: :client_id, scope: leaving_enrollments)

      members = client_enrollments.map do |enrollment|
        [enrollment.client, enrollment]
      end.to_h
      @leavers.add_universe_members(members)

      @leavers.members
    end
  end
end

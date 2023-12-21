###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# HUD SPM Report Generator: Measure 2a and 2b: The Extent to which Persons Who Exit Homelessness
# to Permanent Housing Destinations Return to Homelessness within 6, 12,
# and 24 months.
module HudSpmReport::Generators::Fy2023
  class MeasureFive < MeasureBase
    def self.question_number
      'Measure 5'.freeze
    end

    def self.table_descriptions
      {
        'Measure 5' => 'Number of Persons who Become Homeless for the First Time',
        '5.1' => 'Change in the number of persons entering ES, SH, and TH projects with no prior enrollments in HMIS',
        '5.2' => 'Change in the number of persons entering ES, SH, TH, and PH projects with no prior enrollments in HMIS',
      }.freeze
    end

    def run_question!
      tables = [
        ['5.1', :run_5_1],
        ['5.2', :run_5_2],
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

    private def run_5_1(table_name)
      prepare_table(
        table_name,
        {
          2 => 'Universe: Person with entries into ES-EE, ES-NbN, SH, or TH during the reporting period.',
          3 => 'Of persons above, count those who were in ES-EE, ES-NbN, SH, TH, or any PH within 24 months prior to their start during the reporting year.',
          4 => 'Of persons above, count those who did not have entries in ES-EE, ES-NbN, SH, TH or PH in the previous 24 months. (i.e. number of persons experiencing homelessness for the first time)',
        },
        COLUMNS,
      )

      report_members = create_universe(:m5_1, [:es, :sh, :th].map { |code| HudUtility2024.project_type_number_from_code(code) }.flatten)
      answer = @report.answer(question: table_name, cell: 'C2')
      answer.add_members(report_members)
      answer.update(summary: report_members.count)

      prior_members = create_priors_universe(:m5_1p, report_members)
      answer = @report.answer(question: table_name, cell: 'C3')
      answer.add_members(prior_members)
      answer.update(summary: prior_members.count)

      answer = @report.answer(question: table_name, cell: 'C4')
      answer.update(summary: report_members.count - prior_members.count)
    end

    private def run_5_2(table_name)
      prepare_table(
        table_name,
        {
          2 => 'Universe: Person with entries into ES-EE, ES-NbN, SH, TH or PH during the reporting period.',
          3 => 'Of persons above, count those who were in ES-EE, ES-NbN, SH, TH, or any PH within 24 months prior to their start during the reporting year.',
          4 => 'Of persons above, count those who did not have entries in ES-EE, ES-NbN, SH, TH or PH in the previous 24 months. (i.e. number of persons experiencing homelessness for the first time)',
        },
        COLUMNS,
      )

      report_members = create_universe(:m5_2, [:es, :sh, :th, :ph].flat_map { |code| HudUtility2024.project_type_number_from_code(code) })
      answer = @report.answer(question: table_name, cell: 'C2')
      answer.add_members(report_members)
      answer.update(summary: report_members.count)

      prior_members = create_priors_universe(:m5_2p, report_members)
      answer = @report.answer(question: table_name, cell: 'C3')
      answer.add_members(prior_members)
      answer.update(summary: prior_members.count)

      answer = @report.answer(question: table_name, cell: 'C4')
      answer.update(summary: report_members.count - prior_members.count)
    end

    def create_universe(universe_name, project_types)
      filter = ::Filters::HudFilterBase.new(user_id: @report.user.id).update(@report.options)
      universe = @report.universe(universe_name)
      enrollments = enrollment_set.where(entry_date: filter.range, project_type: project_types)
      earliest_enrollments = HudSpmReport::Fy2023::SpmEnrollment.one_for_column(:entry_date, source_arel_table: spm_e_t, group_on: :client_id, direction: :asc, scope: enrollments)

      members = earliest_enrollments.map do |enrollment|
        [enrollment.client, enrollment]
      end.to_h
      universe.add_universe_members(members)

      universe.members
    end

    def create_priors_universe(universe_name, report_members)
      universe = @report.universe(universe_name)

      if report_members.count.positive?
        report_enrollments = HudSpmReport::Fy2023::SpmEnrollment.where(id: report_members.select(:universe_membership_id))
        filter = ::Filters::HudFilterBase.new(user_id: @report.user.id).update(@report.options)
        adjusted_range = filter.range.begin - 730.days .. filter.range.end
        project_types = [:es, :sh, :th, :ph].flat_map { |code| HudUtility2024.project_type_number_from_code(code) }
        candidate_enrollments = enrollment_set.open_during_range(adjusted_range).where(project_type: project_types)

        universe_enrollments = []
        report_enrollments.find_in_batches do |batch|
          batch_candidates = candidate_enrollments.
            where(spm_e_t[:client_id].in(batch.map(&:client_id))).
            order(spm_e_t[:exit_date].desc).order(:id).
            group_by(&:client_id)

          batch.each do |enrollment|
            found = batch_candidates[enrollment.client_id]&.detect do |candidate|
              candidate.entry_date < enrollment.entry_date &&
                (candidate.exit_date.nil? || candidate.exit_date >= enrollment.entry_date - 730.days)
            end
            universe_enrollments << found if found
          end
        end

        members = universe_enrollments.map do |enrollment|
          [enrollment.client, enrollment]
        end.to_h
        universe.add_universe_members(members)
      end

      universe.members
    end
  end
end

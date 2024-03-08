###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# HUD SPM Report Generator: Length of Time Persons Remain Homeless
module HudSpmReport::Generators::Fy2023
  class MeasureOne < MeasureBase
    def self.question_number
      'Measure 1'.freeze
    end

    def self.client_class
      HudSpmReport::Fy2023::Episode.
        joins(:enrollments).preload(:enrollments)
    end

    def self.table_descriptions
      {
        'Measure 1' => 'Length of Time Persons Experience Homelessness',
      }.freeze
    end

    def run_question!
      tables = [
        ['1a', :run_1a],
        ['1b', :run_1b],
      ]

      @report.start(self.class.question_number, tables.map(&:first))

      tables.each do |name, msg|
        send(msg, name)
      end

      @report.complete(self.class.question_number)
    end

    COLUMNS = {
      'A' => 'Previous FY Universe (Persons)', # leave blank
      'B' => 'Current FY Universe (Persons)',
      'C' => 'Previous FY Average LOT Experiencing Homelessness', # leave blank
      'D' => 'Current FY Average LOT Experiencing Homelessness',
      'E' => 'Difference', # blank
      'F' => 'Previous FY Median LOT Experiencing Homelessness', # leave blank
      'G' => 'Current FY Median LOT Experiencing Homelessness',
      'H' => 'Difference', # leave blank
    }.freeze

    private def run_1a(table_name)
      prepare_table(
        table_name,
        {
          1 => 'Persons in ES-EE, ES-NbN, and SH',
          2 => 'Persons in ES-EE, ES-NbN, SH, and TH',
        },
        COLUMNS,
        external_column_header: true,
        external_row_label: true,
      )

      create_universe(
        :m1a1,
        included_project_types: HudUtility2024.project_type_number_from_code(:es) + HudUtility2024.project_type_number_from_code(:sh),
        excluded_project_types: HudUtility2024.project_type_number_from_code(:th) + HudUtility2024.project_type_number_from_code(:ph),
      )

      cell_universe = @report.universe(:m1a1).members
      persons, mean, median = compute_row(cell_universe)
      answer = @report.answer(question: table_name, cell: :B1)
      answer.add_members(cell_universe)
      answer.update(summary: persons)
      # puts 'M1A B1'
      # puts cell_universe.map(&:universe_membership).map(&:client).map(&:personal_id)
      # write_detail(answer)
      answer = @report.answer(question: table_name, cell: :D1)
      answer.add_members(cell_universe)
      answer.update(summary: mean)
      # write_detail(answer)
      answer = @report.answer(question: table_name, cell: :G1)
      answer.add_members(cell_universe)
      answer.update(summary: median)
      # write_detail(answer)

      create_universe(
        :m1a2,
        included_project_types: HudUtility2024.project_type_number_from_code(:es) +
          HudUtility2024.project_type_number_from_code(:sh) +
          HudUtility2024.project_type_number_from_code(:th),
        excluded_project_types: HudUtility2024.project_type_number_from_code(:ph),
      )

      cell_universe = @report.universe(:m1a2).members
      persons, mean, median = compute_row(cell_universe)
      answer = @report.answer(question: table_name, cell: :B2)
      answer.add_members(cell_universe)
      answer.update(summary: persons)
      answer = @report.answer(question: table_name, cell: :D2)
      answer.add_members(cell_universe)
      answer.update(summary: mean)
      answer = @report.answer(question: table_name, cell: :G2)
      answer.add_members(cell_universe)
      answer.update(summary: median)
    end

    private def run_1b(table_name)
      prepare_table(
        table_name,
        {
          1 => 'Persons in ES-EE, ES-NbN, SH, and PH',
          2 => 'Persons in ES-EE, ES-NbN, SH, TH, and PH',
        },
        COLUMNS,
        external_column_header: true,
        external_row_label: true,
      )

      create_universe(
        :m1b1,
        included_project_types: HudUtility2024.project_type_number_from_code(:es) +
          HudUtility2024.project_type_number_from_code(:sh),
        excluded_project_types: HudUtility2024.project_type_number_from_code(:th) +
          HudUtility2024.project_type_number_from_code(:ph),
        include_self_reported_and_ph: true,
      )

      cell_universe = @report.universe(:m1b1).members
      persons, mean, median = compute_row(cell_universe)
      answer = @report.answer(question: table_name, cell: :B1)
      answer.add_members(cell_universe)
      answer.update(summary: persons)
      # puts 'M1B B1'
      # puts cell_universe.map(&:universe_membership).map(&:client).map(&:personal_id)
      # write_detail(answer)
      answer = @report.answer(question: table_name, cell: :D1)
      answer.add_members(cell_universe)
      answer.update(summary: mean)
      answer = @report.answer(question: table_name, cell: :G1)
      answer.add_members(cell_universe)
      answer.update(summary: median)

      create_universe(
        :m1b2,
        included_project_types: HudUtility2024.project_type_number_from_code(:es) +
          HudUtility2024.project_type_number_from_code(:sh) +
          HudUtility2024.project_type_number_from_code(:th),
        excluded_project_types: HudUtility2024.project_type_number_from_code(:ph),
        include_self_reported_and_ph: true,
      )

      cell_universe = @report.universe(:m1b2).members
      persons, mean, median = compute_row(cell_universe)
      answer = @report.answer(question: table_name, cell: :B2)
      answer.add_members(cell_universe)
      answer.update(summary: persons)
      # puts 'M1B B2'
      # puts cell_universe.map(&:universe_membership).map(&:client).map(&:personal_id)
      answer = @report.answer(question: table_name, cell: :D2)
      answer.add_members(cell_universe)
      answer.update(summary: mean)
      answer = @report.answer(question: table_name, cell: :G2)
      answer.add_members(cell_universe)
      answer.update(summary: median)
    end

    private def create_universe(universe_name, included_project_types:, excluded_project_types:, include_self_reported_and_ph: false)
      @universe = @report.universe(universe_name)
      # Universe
      # Measure 1a/Metric 1: Emergency Shelter – Entry Exit (Project Type 0), Emergency Shelter – Night-by-Night (Project Type 1), and Safe Haven (Project Type 8) clients who are active in report date range.
      # Measure 1a/Metric 2: Emergency Shelter –Entry Exit (Project Type 0), Emergency Shelter – Night-by-Night (Project Type 1), Safe Haven (Project Type 8), and Transitional Housing (Project Type 2) clients who are active in report date range.
      # Measure 1b/Metric 1: Emergency Shelter – Entry Exit (Project Type 0), Emergency Shelter – Night-by-Night (Project Type 1), Safe Haven (Project Type 8), and Permanent Housing (Project Types 3, 9, 10, 13) clients who are active in report date range. For PH projects, only stays meeting the Identifying Clients Experiencing Literal Homelessness at Project Entry criteria are included in time experiencing homelessness.
      # Measure 1b/Metric 2: Emergency Shelter – Entry Exit (Project Type 0), Emergency Shelter – Night-by-Night (Project Type 1), Safe Haven (Project Type 8), Transitional Housing (Project Type 2), and Permanent Housing (Project Types 3, 9, 10, 13) clients who are active in report date range.  For PH projects, only stays meeting the Identifying Clients Experiencing Literal Homelessness at Project Entry criteria are included in time experiencing homelessness.
      candidate_client_ids = enrollment_set.
        with_active_method_5_in_range(filter.range).
        where(project_type: included_project_types).
        pluck(:client_id)
      if include_self_reported_and_ph
        # For PH projects, only stays meeting the Identifying Clients Experiencing Literal Homelessness at Project Entry criteria are included in time experiencing homelessness
        literally_homeless_in_ph = enrollment_set.literally_homeless_at_entry_in_range(filter.range).where(project_type: HudUtility2024.project_type_number_from_code(:ph))
        candidate_client_ids += literally_homeless_in_ph.pluck(:client_id)
      end
      enrollments = enrollment_set.where(client_id: candidate_client_ids.uniq)
      batch_calculator = HudSpmReport::Fy2023::EpisodeBatch.new(enrollments, included_project_types, excluded_project_types, include_self_reported_and_ph, @report)

      client_ids = enrollments.pluck(:client_id).uniq
      client_ids.each_slice(2_000) do |slice|
        episodes = batch_calculator.calculate_batch(slice)
        next unless episodes.present?

        members = episodes.map do |episode|
          [episode.client, episode]
        end.to_h
        @universe.add_universe_members(members)
      end
      @universe.members
    end

    private def compute_row(universe)
      a_t = HudSpmReport::Fy2023::Episode.arel_table
      persons = universe.count
      return [0, 0, 0] unless persons.positive?

      days_homeless = universe.pluck(a_t[:days_homeless])
      average = mean(days_homeless.sum, persons)
      median = median(days_homeless)

      [persons, average, median]
    end

    private def mean(num, denom)
      format('%1.2f', (num / denom.to_f).round(2))
    end

    private def median(values)
      selected = if values.count.even?
        (values.count / 2) + 1
      else
        values.count / 2
      end
      values.sort[selected - 1] # Adjust for 0-based array
    end
  end
end

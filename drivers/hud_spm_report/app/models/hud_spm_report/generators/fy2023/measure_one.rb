###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# HUD SPM Report Generator: Length of Time Persons Remain Homeless
module HudSpmReport::Generators::Fy2023
  class MeasureOne < MeasureBase
    def self.question_number
      'Measure 1'.freeze
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
      )

      create_universe(
        :m1a1,
        included_project_types: HudUtility2024.project_type_number_from_code(:es) + HudUtility2024.project_type_number_from_code(:sh),
        excluded_project_types: HudUtility2024.project_type_number_from_code(:th) + HudUtility2024.project_type_number_from_code(:ph),
        include_self_reported: false,
      )

      cell_universe = @report.universe(:m1a1).members
      persons, mean, median = compute_row(cell_universe)
      answer = @report.answer(question: table_name, cell: :B1)
      answer.add_members(cell_universe)
      answer.update(summary: persons)
      answer = @report.answer(question: table_name, cell: :D1)
      answer.add_members(cell_universe)
      answer.update(summary: mean)
      answer = @report.answer(question: table_name, cell: :G1)
      answer.add_members(cell_universe)
      answer.update(summary: median)

      create_universe(
        :m1a2,
        included_project_types: HudUtility2024.project_type_number_from_code(:es) +
          HudUtility2024.project_type_number_from_code(:sh) +
          HudUtility2024.project_type_number_from_code(:th),
        excluded_project_types: HudUtility2024.project_type_number_from_code(:ph),
        include_self_reported: false,
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
      )

      create_universe(
        :m1b1,
        included_project_types: HudUtility2024.project_type_number_from_code(:es) +
          HudUtility2024.project_type_number_from_code(:sh) +
          HudUtility2024.project_type_number_from_code(:ph),
        excluded_project_types: HudUtility2024.project_type_number_from_code(:th),
        include_self_reported: true,
      )

      cell_universe = @report.universe(:m1b1).members
      persons, mean, median = compute_row(cell_universe)
      answer = @report.answer(question: table_name, cell: :B1)
      answer.add_members(cell_universe)
      answer.update(summary: persons)
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
          HudUtility2024.project_type_number_from_code(:ph) +
          HudUtility2024.project_type_number_from_code(:th),
        excluded_project_types: [],
        include_self_reported: true,
      )

      cell_universe = @report.universe(:m1b2).members
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

    private def create_universe(universe_name, included_project_types:, excluded_project_types:, include_self_reported:)
      @universe = @report.universe(universe_name)
      candidate_client_ids = enrollment_set.
        with_active_method_5_in_range(filter.range).
        where(project_type: included_project_types).
        pluck(:client_id)
      if include_self_reported
        literally_homeless_in_ph = enrollment_set.literally_homeless_at_entry_in_range(filter.range).where(project_type: HudUtility2024.project_type_number_from_code(:ph))
        candidate_client_ids += literally_homeless_in_ph.where(spm_e_t[:entry_date].between(filter.range)).
          or(literally_homeless_in_ph.where(spm_e_t[:move_in_date].between(filter.range))).
          or(literally_homeless_in_ph.where(spm_e_t[:move_in_date].eq(nil).and(spm_e_t[:exit_date].between(filter.range)))).
          pluck(:client_id)
      end
      enrollments = enrollment_set.where(client_id: candidate_client_ids.uniq)

      client_ids = enrollments.pluck(:client_id).uniq
      client_ids.each_slice(500) do |slice|
        enrollments_for_slice = enrollments.where(client_id: slice).preload(:client, enrollment: :services).group_by(&:client_id)
        episodes = []
        bed_nights_per_episode = []
        enrollment_links_per_episode = []
        slice.each do |client_id|
          episode, bed_nights, enrollment_links = HudSpmReport::Fy2023::Episode.new(client_id: client_id, report: @report).
            compute_episode(
              enrollments_for_slice[client_id],
              included_project_types: included_project_types,
              excluded_project_types: excluded_project_types,
              include_self_reported: include_self_reported,
            )
          next if episode.nil?

          episodes << episode
          bed_nights_per_episode << bed_nights
          enrollment_links_per_episode << enrollment_links
        end
        next unless episodes.present?

        HudSpmReport::Fy2023::Episode.save_episodes!(episodes, bed_nights_per_episode, enrollment_links_per_episode)
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

###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# HUD SPM Report Generator: Length of Time Persons Remain Homeless
module HudSpmReport::Generators::Fy2021
  class MeasureOne < Base
    def self.question_number
      'Measure 1'.freeze
    end

    def self.table_descriptions
      {
        'Measure 1' => 'Length of Time Persons Remain Homeless',
      }.freeze
    end

    COLS = {
      'B' => 'Previous FY Universe (Persons)', # optional
      'C' => 'Current FY Universe (Persons)',
      'D' => 'Previous FY Average LOT Homeless', # optional
      'E' => 'Current FY Average LOT Homeless',
      'F' => 'Difference', # optional
      'G' => 'Previous FY Median LOT Homeless', # optional
      'H' => 'Current FY Median LOT Homeless',
      'I' => 'Difference', # optional
    }.freeze

    def run_question!
      tables = [
        ['1a', :run_1a, nil],
        ['1b', :run_1b, nil],
      ]

      @report.start(self.class.question_number, tables.map(&:first))

      tables.each do |name, msg, _title|
        send(msg, name)
      end

      @report.complete(self.class.question_number)
    end

    private def run_1a(table_name)
      prepare_table table_name, {
        2 => 'Persons in ES and SH',
        3 => 'Persons in ES, SH, and TH',
      }, COLS

      universe_members = universe.members.where(t[:m1a_es_sh_days].gt(0))
      handle_clause_based_cells table_name, [
        ['C2', universe_members, universe_members.count],
        ['E2', universe_members, universe_members.average(:m1a_es_sh_days).to_f.round(2)],
        ['H2', universe_members, median(universe_members, :m1a_es_sh_days).to_f],
      ]

      universe_members = universe.members.where(t[:m1a_es_sh_th_days].gt(0))
      handle_clause_based_cells table_name, [
        ['C3', universe_members, universe_members.count],
        ['E3', universe_members, universe_members.average(:m1a_es_sh_th_days).to_f.round(2)],
        ['H3', universe_members, median(universe_members, :m1a_es_sh_th_days).to_f],
      ]
    end

    private def run_1b(table_name)
      prepare_table table_name, {
        2 => 'Persons in ES, SH, and PH',
        3 => 'Persons in ES, SH, TH, and PH',
      }, COLS

      universe_members = universe.members.where(t[:m1b_es_sh_ph_days].gt(0))
      handle_clause_based_cells table_name, [
        ['C2', universe_members, universe_members.count],
        ['E2', universe_members, universe_members.average(:m1b_es_sh_ph_days).to_f.round(2)],
        ['H2', universe_members, median(universe_members, :m1b_es_sh_ph_days).to_f.round(2)],
      ]
      universe_members = universe.members.where(t[:m1b_es_sh_th_ph_days].gt(0))
      handle_clause_based_cells table_name, [
        ['C3', universe_members, universe_members.count],
        ['E3', universe_members, universe_members.average(:m1b_es_sh_th_ph_days).to_f.round(2)],
        ['H3', universe_members, median(universe_members, :m1b_es_sh_th_ph_days).to_f.round(2)],
      ]
    end
  end
end

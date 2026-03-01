###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative './shared_context'

RSpec.describe 'HDX Copy Logic', type: :model do
  include_context '2026 SPM test setup'

  let(:sequence) { (1..).to_enum }

  before do
    @report = setup_report([], ['Measure 1', 'Measure 2', 'Measure 3', 'Measure 4', 'Measure 5', 'Measure 6', 'Measure 7', 'HDX Upload'])
  end

  context 'measure 1' do
    before { run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne) }

    it 'correctly copies values from measure 1a to HDX' do
      verify_hdx_mapping({
                           'ESSHUniverse_1A' => ['1a', 'B2'],
                           'ESSHAvgTime_1A' => ['1a', 'D2'],
                           'ESSHMedianTime_1A' => ['1a', 'G2'],
                           'ESSHTHUniverse_1A' => ['1a', 'B3'],
                           'ESSHTHAvgTime_1A' => ['1a', 'D3'],
                           'ESSHTHMedianTime_1A' => ['1a', 'G3'],
                         })
    end

    it 'correctly copies values from measure 1b to HDX' do
      verify_hdx_mapping({
                           'ESSHUniverse_1B' => ['1b', 'B2'],
                           'ESSHAvgTime_1B' => ['1b', 'D2'],
                           'ESSHMedianTime_1B' => ['1b', 'G2'],
                           'ESSHTHUniverse_1B' => ['1b', 'B3'],
                           'ESSHTHAvgTime_1B' => ['1b', 'D3'],
                           'ESSHTHMedianTime_1B' => ['1b', 'G3'],
                         })
    end
  end

  it 'correctly copies values from measure 2 to HDX' do
    run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureTwo)

    table = '2a and 2b'
    verify_hdx_mapping({
                         'SOExitPH_2' => [table, 'B2'], 'SOReturn0to180_2' => [table, 'C2'], 'SOReturn181to365_2' => [table, 'E2'], 'SOReturn366to730_2' => [table, 'G2'],
                         'ESExitPH_2' => [table, 'B3'], 'ESReturn0to180_2' => [table, 'C3'], 'ESReturn181to365_2' => [table, 'E3'], 'ESReturn366to730_2' => [table, 'G3'],
                         'THExitPH_2' => [table, 'B4'], 'THReturn0to180_2' => [table, 'C4'], 'THReturn181to365_2' => [table, 'E4'], 'THReturn366to730_2' => [table, 'G4'],
                         'SHExitPH_2' => [table, 'B5'], 'SHReturn0to180_2' => [table, 'C5'], 'SHReturn181to365_2' => [table, 'E5'], 'SHReturn366to730_2' => [table, 'G5'],
                         'PHExitPH_2' => [table, 'B6'], 'PHReturn0to180_2' => [table, 'C6'], 'PHReturn181to365_2' => [table, 'E6'], 'PHReturn366to730_2' => [table, 'G6']
                       })
  end

  it 'correctly copies values from measure 3 to HDX' do
    run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureThree)

    table = '3.2'
    verify_hdx_mapping({
                         'TotalAnnual_3' => [table, 'C2'],
                         'ESAnnual_3' => [table, 'C3'],
                         'SHAnnual_3' => [table, 'C4'],
                         'THAnnual_3' => [table, 'C5'],
                       })
  end

  it 'correctly copies values from measure 4 to HDX' do
    run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureFour)

    verify_hdx_mapping({
                         'AdultStayers_4' => ['4.1', 'C2'],
                         'IncreaseEarned4_1' => ['4.1', 'C3'],
                         'IncreaseOther4_2' => ['4.2', 'C3'],
                         'IncreaseTotal4_3' => ['4.3', 'C3'],
                         'AdultLeavers_4' => ['4.4', 'C2'],
                         'IncreaseEarned4_4' => ['4.4', 'C3'],
                         'IncreaseOther4_5' => ['4.5', 'C3'],
                         'IncreaseTotal4_6' => ['4.6', 'C3'],
                       })
  end

  it 'correctly copies values from measure 5 to HDX' do
    run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureFive)

    verify_hdx_mapping({
                         'EnterESSHTH5_1' => ['5.1', 'C2'],
                         'ESSHTHWithPriorSvc5_1' => ['5.1', 'C3'],
                         'EnterESSHTHPH5_2' => ['5.2', 'C2'],
                         'ESSHTHPHWithPriorSvc5_2' => ['5.2', 'C3'],
                       })
  end

  # measure 6 is not implemented
  xit 'correctly copies values from measure 6 to HDX' do
    run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureSix)

    table_main = '6a.1 and 6b.1'
    table_c1 = '6c.1'
    table_c2 = '6c.2'

    verify_hdx_mapping({
                         'THExitPH_6' => [table_main, 'B4'],
                         'THReturn0to180_6' => [table_main, 'C4'],
                         'THReturn181to365_6' => [table_main, 'E4'],
                         'THReturn366to730_6' => [table_main, 'G4'],
                         'SHExitPH_6' => [table_main, 'B5'],
                         'SHReturn0to180_6' => [table_main, 'C5'],
                         'SHReturn181to365_6' => [table_main, 'E5'],
                         'SHReturn366to730_6' => [table_main, 'G5'],
                         'PHExitPH_6' => [table_main, 'B6'],
                         'PHReturn0to180_6' => [table_main, 'C6'],
                         'PHReturn181to365_6' => [table_main, 'E6'],
                         'PHReturn366to730_6' => [table_main, 'G6'],
                         'SHTHRRHCat3Leavers_6' => [table_c1, 'C2'],
                         'SHTHRRHCat3ExitPH_6' => [table_c1, 'C3'],
                         'PSHCat3Clients_6' => [table_c2, 'C2'],
                         'PSHCat3StayOrExitPH_6' => [table_c2, 'C3'],
                       })
  end

  it 'correctly copies values from measure 7 to HDX' do
    run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureSeven)

    table_7a1 = '7a.1'
    table_7b1 = '7b.1'
    table_7b2 = '7b.2'

    verify_hdx_mapping({
                         'SOExit_7' => [table_7a1, 'C2'],
                         'SOExitTempInst_7' => [table_7a1, 'C3'],
                         'SOExitPH_7' => [table_7a1, 'C4'],
                         'ESSHTHRRHExit_7' => [table_7b1, 'C2'],
                         'ESSHTHRRHToPH_7' => [table_7b1, 'C3'],
                         'PHClients_7' => [table_7b2, 'C2'],
                         'PHClientsStayOrExitPH_7' => [table_7b2, 'C3'],
                       })
  end

  context 'data quality' do
    before do
      # Create an isolated DQ report to stub into the HDX generator.
      # The HDX upload normally generates these internally during its run, but intercepting
      # it allows us to verify the cell references independently without running the full suite.
      filter = default_filter.dup
      questions = ['Question 1', 'Question 4']
      @dq_report = HudReports::ReportInstance.from_filter(
        filter,
        HudApr::Generators::Dq::Fy2026::Generator.title,
        build_for_questions: questions,
      )
      @dq_report.question_names = questions
      @dq_report.save!

      generator = HudApr::Generators::Dq::Fy2026::Generator
      generator.new(@dq_report).run!(email: false, manual: false)

      allow_any_instance_of(HudSpmReport::Generators::Fy2026::HdxUpload).to receive(:generate_dq).and_return(@dq_report)
    end

    it 'correctly copies values from ES-SH DQ' do
      verify_hdx_mapping({
                           'ESSH_UndupHMIS_DQ' => ['Q1', 'B2'],
                           'ESSH_LeaversHMIS_DQ' => ['Q1', 'B6'],
                           'ESSH_DkRMHMIS_DQ' => ['Q4', 'E2'],
                         }, report: @dq_report)
    end

    it 'correctly copies values from TH DQ' do
      verify_hdx_mapping({
                           'TH_UndupHMIS_DQ' => ['Q1', 'B2'],
                           'TH_LeaversHMIS_DQ' => ['Q1', 'B6'],
                           'TH_DkRMHMIS_DQ' => ['Q4', 'E2'],
                         }, report: @dq_report)
    end

    it 'correctly copies values from PSH/OPH DQ' do
      verify_hdx_mapping({
                           'PSHOPH_UndupHMIS_DQ' => ['Q1', 'B2'],
                           'PSHOPH_LeaversHMIS_DQ' => ['Q1', 'B6'],
                           'PSHOPH_DkRMHMIS_DQ' => ['Q4', 'E2'],
                         }, report: @dq_report)
    end

    it 'correctly copies values from RRH DQ' do
      verify_hdx_mapping({
                           'RRH_UndupHMIS_DQ' => ['Q1', 'B2'],
                           'RRH_LeaversHMIS_DQ' => ['Q1', 'B6'],
                           'RRH_DkRMHMIS_DQ' => ['Q4', 'E2'],
                         }, report: @dq_report)
    end

    it 'correctly copies values from Street Outreach DQ' do
      verify_hdx_mapping({
                           'StOutreach_UndupHMIS_DQ' => ['Q1', 'B2'],
                           'StOutreach_LeaversHMIS_DQ' => ['Q1', 'B6'],
                           'StOutreach_DkRMHMIS_DQ' => ['Q4', 'E2'],
                         }, report: @dq_report)
    end
  end

  private

  def verify_hdx_mapping(mapping, report: @report)
    expected_values = {}
    answer_map = report.report_cells.where(universe: false).index_by { |c| [c.question, c.cell_name] }

    mapping.each do |hdx_var, (source_table, source_cell)|
      # Inject unique values from sequence for comparison
      val = sequence.next.to_f
      answer = answer_map[[source_table, source_cell]]
      expect(answer).to be_present, "Source cell #{source_table}:#{source_cell} not found"
      answer.update!(summary: val)
      expected_values[hdx_var] = val
    end

    # Run the copy
    run_measure(@report, HudSpmReport::Generators::Fy2026::HdxUpload)

    # Verify all mappings
    expected_values.each do |hdx_var, expected_val|
      expect(hdx_answer(hdx_var).summary).to eq(expected_val)
    end
  end

  def hdx_answer(name, report: @report)
    config = HudSpmReport::Generators::Fy2026::HdxUpload::COLUMNS.find do |h|
      h[:variable_name] == name
    end
    raise "hdx col \"#{name}\" not found" unless config

    report.answer(question: 'csv', cell: "#{config.column_letter}2")
  end
end

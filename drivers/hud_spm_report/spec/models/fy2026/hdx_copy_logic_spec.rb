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
    @report = setup_report([], ['Measure 1', 'Measure 2', 'HDX Upload'])
  end

  it 'correctly copies values from measure 1a to HDX' do
    run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)

    verify_hdx_mapping({
      'ESSHUniverse_1A'      => ['1a', 'B2'],
      'ESSHAvgTime_1A'       => ['1a', 'D2'],
      'ESSHMedianTime_1A'    => ['1a', 'G2'],
      'ESSHTHUniverse_1A'    => ['1a', 'B3'],
      'ESSHTHAvgTime_1A'     => ['1a', 'D3'],
      'ESSHTHMedianTime_1A'  => ['1a', 'G3']
    })
  end

  it 'correctly copies values from measure 1b to HDX' do
    run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)

    verify_hdx_mapping({
      'ESSHUniverse_1B'      => ['1b', 'B2'],
      'ESSHAvgTime_1B'       => ['1b', 'D2'],
      'ESSHMedianTime_1B'    => ['1b', 'G2'],
      'ESSHTHUniverse_1B'    => ['1b', 'B3'],
      'ESSHTHAvgTime_1B'     => ['1b', 'D3'],
      'ESSHTHMedianTime_1B'  => ['1b', 'G3']
    })
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

  private

  def verify_hdx_mapping(mapping)
    # 1. Inject unique values from sequence
    expected_values = {}
    mapping.each do |hdx_var, (source_table, source_cell)|
      val = sequence.next.to_f
      @report.answer(question: source_table, cell: source_cell).update!(summary: val)
      expected_values[hdx_var] = val
    end

    # 2. Run the copy
    run_measure(@report, HudSpmReport::Generators::Fy2026::HdxUpload)

    # 3. Verify all mappings
    expected_values.each do |hdx_var, expected_val|
      expect(hdx_answer(hdx_var).summary).to eq(expected_val)
    end
  end
end

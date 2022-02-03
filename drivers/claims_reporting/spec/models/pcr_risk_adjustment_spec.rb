###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

if ClaimsReporting::Calculators::PcrRiskAdjustment.available?
  RSpec.describe 'ClaimsReporting::Calculators::PcrRiskAdjustment', type: :model do
    it 'matches the example for Step 4 page 62 in 2021 Quality Rating System Measure Technical Spec' do
      calc = ClaimsReporting::Calculators::PcrRiskAdjustment.new

      input = ['CC-85', 'CC-17', 'CC-19']
      output = calc.cc_to_hcc input, include_combos: false
      assert_equal ['HCC-85', 'HCC-17'], output, "Desired output for input #{input}"
    end

    it 'matches the example for Step 5 page 63 in 2021 Quality Rating System Measure Technical Spec' do
      calc = ClaimsReporting::Calculators::PcrRiskAdjustment.new

      input = ['CC-17', 'CC-85']
      output = calc.cc_to_hcc input, include_combos: true
      assert_equal ['HCC-17', 'HCC-85', 'HCC-901'], output, "Desired output for input #{input}"
    end

    it 'can process an ihs with a complex combo of inputs' do
      calc = ClaimsReporting::Calculators::PcrRiskAdjustment.new

      input = {
        age: 45,
        gender: 'Male',
        observation_stay: true,
        had_surgery: true,
        discharge_dx_code: 'G40011',
        comorb_dx_codes: ['G8320', 'E0852', 'A0104'],
      }

      result = calc.process_ihs(**input)
      expect(result).to be_kind_of(Hash)

      output = {
        age_gender_weight: -2.6552,
        surg_weight: -0.1251,
        discharge_cc_codes: ['CC-79'],
        discharge_weights: [-0.0581],
        hcc_codes: ['HCC-104', 'HCC-18', 'HCC-106', 'HCC-39'],
        hcc_weights: [nil, 0.0748, 0.0385, 0.1223],
        sum_of_weights: -2.6365,
        expected_readmit_rate: 0.0668259658430162,
        variance: 0.062360256132164234,
      }
      # echo input
      input.keys.each do |key|
        assert_equal input[key], result[key], "Echo input for #{key}"
      end

      # produce expected output
      output.keys.each do |key|
        assert_equal output[key], result[key], "Desired output for #{key}"
      end
    end
  end
end

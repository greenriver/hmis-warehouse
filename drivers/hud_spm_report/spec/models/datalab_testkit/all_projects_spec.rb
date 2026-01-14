###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../../datalab_testkit/spec/models/datalab_testkit_context'
require_relative 'spm_context'

RSpec.describe 'Datalab Testkit SPM All-Projects', type: :model do
  include_context 'datalab testkit context'
  include_context 'datalab spm context'
  let(:results_dir) { 'spm' }
  # Only run the tests if the source files are available
  if File.exist?('drivers/datalab_testkit/spec/fixtures/inputs/merged/source/Export.csv')
    before(:all) do
      puts "Starting SPM Data Lab TestKit #{Time.current}"
      setup
      puts "Setup Done for SPM Data Lab TestKit #{Time.current}"
      # run(default_spm_filter, HudSpmReport::Generators::Fy2023::Generator.questions.keys.grep(/Measure 2/))
      run(default_spm_filter, HudSpmReport::Generators::Fy2026::Generator.questions.keys)
      puts "Finished SPM Run Data Lab TestKit #{Time.current}"
    end

    # PersonalID: 665435 showing 30 Homeless days in TK data but we have 17 calculated due to overlapping PH enrollment
    # Pending https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recbKFyAs8hUTlNFU
    it 'Measure 1a' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        external_row_label: true,
        question: '1a',
        skip: [
          'B2', # expected '4808.0000' (4808), got '4417.0000' (4417)
          'D2', # expected '73.9500' (73.95), got '53.2000' (53.20)
          'G2', # expected '37.0000' (37), got '31.0000' (31)
          'B3', # expected '0.0000' (), got '4825.0000' (4825)
          'D3', # expected '0.0000' (), got '73.7400' (73.74)
          'G3', # expected '0.0000' (), got '37.0000' (37)
        ],
      )
    end

    # Pending https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recCo8VEaNZ2BhQIr
    # Pending https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/rec59oPiPxyysL4nL
    # Pending https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recGMWKxKqBJgv221
    it 'Measure 1b' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        external_row_label: true,
        question: '1b',
      )
    end

    # Pending https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/rec6i2GNIRlWPOF1K
    it 'Measure 2' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: '2a and 2b',
        skip: [
          'B2', # expected '173.0000' (173), got '171.0000' (171)
          'C2', # expected '23.0000' (23), got '22.0000' (22)
          'D2', # expected '13.2900' (13.29), got '12.8700' (12.8700)
          'E2', # expected '15.0000' (15), got '14.0000' (14)
          'F2', # expected '8.6700' (8.67), got '8.1900' (8.1900)
          'G2', # expected '19.0000' (19), got '18.0000' (18)
          'H2', # expected '10.9800' (10.98), got '10.5300' (10.5300)
          'I2', # expected '57.0000' (57), got '54.0000' (54)
          'J2', # expected '32.9500' (32.95), got '31.5800' (31.5800)
          'B3', # expected '2078.0000' (2078), got '2079.0000' (2079)
          'C3', # expected '335.0000' (335), got '333.0000' (333)
          'D3', # expected '16.1200' (16.12), got '16.0200' (16.0200)
          'E3', # expected '163.0000' (163), got '162.0000' (162)
          'F3', # expected '7.8400' (7.84), got '7.7900' (7.7900)
          'G3', # expected '167.0000' (167), got '165.0000' (165)
          'H3', # expected '8.0400' (8.04), got '7.9400' (7.9400)
          'I3', # expected '665.0000' (665), got '660.0000' (660)
          'J3', # expected '32.0000' (32), got '31.7500' (31.7500)
          'B6', # expected '1168.0000' (1168), got '1174.0000' (1174)
          'C6', # expected '77.0000' (77), got '76.0000' (76)
          'D6', # expected '6.5900' (6.59), got '6.4700' (6.4700)
          'E6', # expected '89.0000' (89), got '88.0000' (88)
          'F6', # expected '7.6200' (7.62), got '7.5000' (7.5000)
          'G6', # expected '94.0000' (94), got '95.0000' (95)
          'H6', # expected '8.0500' (8.05), got '8.0900' (8.0900)
          'I6', # expected '260.0000' (260), got '259.0000' (259)
          'J6', # expected '22.2600' (22.26), got '22.0600' (22.0600)
          'B7', # expected '3687.0000' (3687), got '3692.0000' (3692)
          'C7', # expected '457.0000' (457), got '453.0000' (453)
          'D7', # expected '12.3900' (12.39), got '12.2700' (12.2700)
          'E7', # expected '276.0000' (276), got '273.0000' (273)
          'F7', # expected '7.4900' (7.49), got '7.3900' (7.3900)
          'G7', # expected '292.0000' (292), got '290.0000' (290)
          'H7', # expected '7.9200' (7.92), got '7.8500' (7.8500)
          'I7', # expected '1025.0000' (1025), got '1016.0000' (1016)
          'J7', # expected '27.8000' (27.8), got '27.5200' (27.5200)
        ],
      )
    end

    it 'Measure 3.2' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: '3.2',
        skip: [
          'C2', # expected '4951.0000' (4951), got '4923.0000' (4923)
          'C3', # expected '4534.0000' (4534), got '4504.0000' (4504)
          'C5', # expected '558.0000' (558), got '557.0000' (557)
        ],
      )
    end

    it 'Measure 4.1' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: '4.1',
      )
    end

    it 'Measure 4.2' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: '4.2',
      )
    end

    it 'Measure 4.3' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: '4.3',
      )
    end

    it 'Measure 4.4' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: '4.4',
        skip: [
          'C2', # expected '135.0000' (135), got '131.0000' (131)
          'C4', # expected '8.1500' (8.15), got '8.4000' (8.4000)
        ],
      )
    end

    it 'Measure 4.5' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: '4.5',
        skip: [
          'C2', # expected '135.0000' (135), got '131.0000' (131)
          'C4', # expected '8.1500' (8.15), got '8.4000' (8.4000)
        ],
      )
    end

    it 'Measure 4.6' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: '4.6',
        skip: [
          'C2', # expected '135.0000' (135), got '131.0000' (131)
          'C4', # expected '8.1500' (8.15), got '8.4000' (8.4000)
        ],
      )
    end

    it 'Measure 5.1' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: '5.1',
        skip: [
          'C2', # expected '4334.0000' (4334), got '4350.0000' (4350)
          'C4', # expected '3255.0000' (3255), got '3271.0000' (3271)
        ],
      )
    end

    it 'Measure 5.2' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: '5.2',
        skip: [
          'C2', # expected '5867.0000' (5867), got '5888.0000' (5888)
          'C4', # expected '4451.0000' (4451), got '4472.0000' (4472)
        ],
      )
    end

    it 'Measure 7a.1' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: '7a.1',
        skip: [
          'C2', # expected '568.0000' (568), got '569.0000' (569)
          'C4', # expected '306.0000' (306), got '307.0000' (307)
          'C5', # expected '70.9500' (70.95), got '71.0000' (71.0000)
        ],
      )
    end

    it 'Measure 7b.1' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: '7b.1',
        skip: [
          'C2', # expected '5071.0000' (5071), got '5084.0000' (5084)
          'C3', # expected '2510.0000' (2510), got '2520.0000' (2520)
          'C4', # expected '49.5000' (49.5), got '49.5700' (49.5700)
        ],
      )
    end

    it 'Measure 7b.2' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: '7b.2',
      )
    end
  else
    it 'Data Lab Testkit based tests are skipped, files are missing' do
    end
  end
end

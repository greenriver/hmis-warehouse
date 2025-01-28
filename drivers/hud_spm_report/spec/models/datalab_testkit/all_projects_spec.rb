###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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
      run(default_spm_filter, HudSpmReport::Generators::Fy2024::Generator.questions.keys)
      puts "Finished SPM Run Data Lab TestKit #{Time.current}"
    end

    # PersonalID: 665435 showing 30 Homeless days in TK data but we have 17 calculated due to overlapping PH enrollment
    # Pending https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recbKFyAs8hUTlNFU
    it 'Measure 1a' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        external_column_header: true,
        external_row_label: true,
        question: '1a',
        skip: [
          'D2', # expected '63.2000' (63.2), got '63.1900' (63.19)
        ],
      )
    end

    # Pending https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recCo8VEaNZ2BhQIr
    # Pending https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/rec59oPiPxyysL4nL
    # Pending https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recGMWKxKqBJgv221
    it 'Measure 1b' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        external_column_header: true,
        external_row_label: true,
        question: '1b',
        skip: [
          'B1', # expected '5685.0000' (5685), got '5736.0000' (5736)
          'D1', # expected '259.7900' (259.79), got '322.6900' (322.69)
          'G1', # expected '71.0000' (71), got '88.0000' (88)
          'B2', # expected '6178.0000' (6178), got '6221.0000' (6221)
          'D2', # expected '265.7600' (265.76), got '324.4700' (324.47)
          'G2', # expected '80.0000' (80), got '97.0000' (97)
        ],
      )
    end

    # Pending https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/rec6i2GNIRlWPOF1K
    it 'Measure 2' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: '2a and 2b',
        skip: [
          'E3', # expected '145.0000' (145), got '140.0000' (140)
          'F3', # expected '8.3600' (8.36), got '8.0700' (8.0700)
          'I3', # expected '464.0000' (464), got '459.0000' (459)
          'J3', # expected '26.7600' (26.76), got '26.4700' (26.4700)
          'G4', # expected '23.0000' (23), got '22.0000' (22)
          'H4', # expected '9.9600' (9.96), got '9.5200' (9.5200)
          'I4', # expected '45.0000' (45), got '44.0000' (44)
          'J4', # expected '19.4800' (19.48), got '19.0500' (19.0500)
          'E7', # expected '199.0000' (199), got '194.0000' (194)
          'F7', # expected '6.1500' (6.15), got '6.0000' (6.0000)
          'G7', # expected '250.0000' (250), got '249.0000' (249)
          'H7', # expected '7.7300' (7.73), got '7.7000' (7.7000)
          'I7', # expected '715.0000' (715), got '709.0000' (709)
          'J7', # expected '22.1000' (22.1), got '21.9200' (21.9200)
        ],
      )
    end

    it 'Measure 3.2' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: '3.2',
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

    # Test Kit data showing 512 client but TK results show 506. Our numbers appear to match the TK table data.
    it 'Measure 4.4' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: '4.4',
        skip: [
          'C2', # expected '506.0000' (506), got '512.0000' (512)
          'C3', # expected '78.0000' (78), got '79.0000' (79)
          'C4', # expected '15.4200' (15.42), got '15.4300' (15.4300)
        ],
      )
    end

    # Test Kit data showing 512 client but TK results show 506. Our numbers appear to match the TK table data.
    it 'Measure 4.5' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: '4.5',
        skip: [
          'C2', # expected '506.0000' (506), got '512.0000' (512)
          'C4', # expected '14.4300' (14.43), got '14.2600' (14.2600)
        ],
      )
    end

    # Test Kit data showing 512 client but TK results show 506. Our numbers appear to match the TK table data.
    it 'Measure 4.6' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: '4.6',
        skip: [
          'C2', # expected '506.0000' (506), got '512.0000' (512)
          'C3', # expected '133.0000' (133), got '134.0000' (134)
          'C4', # expected '26.2800' (26.28), got '26.1700' (26.1700)
        ],
      )
    end

    it 'Measure 5.1' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: '5.1',
      )
    end

    it 'Measure 5.2' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: '5.2',
        skip: [
          'C2', # expected '6411.0000' (6411), got '6421.0000' (6421)
          'C4', # expected '5125.0000' (5125), got '5135.0000' (5135)
        ],
      )
    end

    it 'Measure 7a.1' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: '7a.1',
      )
    end

    it 'Measure 7b.1' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: '7b.1',
        skip: [
          'C2', # expected '5323.0000' (5323), got '5330.0000' (5330)
          'C3', # expected '2634.0000' (2634), got '2641.0000' (2641)
          'C4', # expected '49.4800' (49.48), got '49.5500' (49.5500)
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

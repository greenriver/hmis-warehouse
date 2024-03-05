###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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
      # run(default_spm_filter, HudSpmReport::Generators::Fy2023::Generator.questions.keys.grep(/Measure 1/))
      run(default_spm_filter, HudSpmReport::Generators::Fy2023::Generator.questions.keys)
      puts "Finished SPM Run Data Lab TestKit #{Time.current}"
    end

    # Pending https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recbKFyAs8hUTlNFU
    it 'Measure 1a' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        external_column_header: true,
        external_row_label: true,
        question: '1a',
        skip: [
          'D1',
          'G1',
          'D2',
          'G2',
        ],
      )
    end

    # Almost matches (off by a few)
    it 'Measure 1b' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        external_column_header: true,
        external_row_label: true,
        question: '1b',
        # skip: [
        #   'B1',
        #   'D1',
        #   'G1',
        #   'B2',
        #   'D2',
        #   'G2',
        # ],
      )
    end

    # Almost matches (off by a few)
    it 'Measure 2' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: '2a and 2b',
      )
    end

    # Almost matches (off by a few)
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
        # skip: [
        #   'C2',
        #   'C4',
        # ],
      )
    end

    it 'Measure 4.2' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: '4.2',
        # skip: [
        #   'C2',
        #   'C4',
        # ],
      )
    end

    it 'Measure 4.3' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: '4.3',
        skip: [
          'C2',
          'C4',
        ],
      )
    end

    # Almost matches (off by a few)
    it 'Measure 4.4' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: '4.4',
        skip: [
          'C2',
          'C3',
          'C4',
        ],
      )
    end

    # Almost matches (off by a few)
    it 'Measure 4.5' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: '4.5',
        skip: [
          'C2',
          'C4',
        ],
      )
    end

    # Almost matches (off by a few)
    it 'Measure 4.6' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: '4.6',
        skip: [
          'C2',
          'C3',
          'C4',
        ],
      )
    end

    # Almost matches (off by a few)
    it 'Measure 5.1' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: '5.1',
        skip: [
          'C2',
          'C3',
          'C4',
        ],
      )
    end

    # Almost matches (off by a few)
    it 'Measure 5.2' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: '5.2',
        skip: [
          'C2',
          'C3',
          'C4',
        ],
      )
    end

    it 'Measure 7a.1' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: '7a.1',
        skip: [
          'C2',
          'C3',
          'C4',
        ],
      )
    end

    # Almost matches (off by a few)
    it 'Measure 7b.1' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: '7b.1',
        skip: [
          'C2',
          'C3',
          'C4',
        ],
      )
    end

    # Almost matches (off by a few)
    it 'Measure 7b.2' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: '7b.2',
        skip: [
          'C2',
          'C3',
          'C4',
        ],
      )
    end
  else
    it 'Data Lab Testkit based tests are skipped, files are missing' do
    end
  end
end

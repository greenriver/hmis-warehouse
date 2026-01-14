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

    it 'Measure 4.4' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: '4.4',
      )
    end

    it 'Measure 4.5' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: '4.5',
      )
    end

    it 'Measure 4.6' do
      compare_results(
        file_path: result_file_prefix + results_dir,
        question: '4.6',
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

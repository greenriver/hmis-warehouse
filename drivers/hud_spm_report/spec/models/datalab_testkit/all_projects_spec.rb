###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../../../../datalab_testkit/spec/models/datalab_testkit_context'
require_relative 'spm_context'

RSpec.describe 'Datalab Testkit SPM All-Projects', type: :model do
  include_context 'datalab testkit context'
  include_context 'datalab spm context'

  # NOTE: disabling all SPM tests for now, they are not compatible with the current test kit source data.

  # Only run the tests if the source files are available
  if File.exist?('drivers/datalab_testkit/spec/fixtures/inputs/merged/source/Export.csv')
    before(:all) do
      puts "Starting SPM Data Lab TestKit #{Time.current}"
      setup
      puts "Setup Done for SPM Data Lab TestKit #{Time.current}"
      run(default_spm_filter, HudSpmReport::Generators::Fy2023::Generator.questions.keys)
      puts "Finished SPM Run Data Lab TestKit #{Time.current}"
    end

    it 'Measure 1a' do
      compare_results(
        file_path: result_file_prefix + 'spm',
        question: '1a',
        detail_columns: [
          :last_name,
          :first_name,
          :data_lab_public_id,
          :m1a_es_sh_days,
          :m1a_es_sh_th_days,
        ],
      )
    end

    it 'Measure 1b' do
      compare_results(
        file_path: result_file_prefix + 'spm',
        question: '1b',
        detail_columns: [
          :last_name,
          :first_name,
          :data_lab_public_id,
          :m1b_es_sh_ph_days,
          :m1b_es_sh_th_ph_days,
        ],
      )
    end

  #   # Pending AAQ: [SPM] All Projects - Data lab test kit Measures 2 and 5 - historic data missing - submitted 10/4/2022
  #   xit 'Measure 2' do
  #     compare_results(
  #       file_path: result_file_prefix + 'spm',
  #       question: '2',
  #     )
  #   end

  #   it 'Measure 3.2' do
  #     compare_results(
  #       file_path: result_file_prefix + 'spm',
  #       question: '3.2',
  #       # Pending AAQ: [SPM] All Projects - Data lab test kit Measure 3 - missing client - submitted 10/4/2022
  #       skip: [
  #         'C2',
  #         'C5',
  #       ],
  #     )
  #   end

  #   it 'Measure 4.1' do
  #     compare_results(
  #       file_path: result_file_prefix + 'spm',
  #       question: '4.1',
  #     )
  #   end

  #   it 'Measure 4.2' do
  #     compare_results(
  #       file_path: result_file_prefix + 'spm',
  #       question: '4.2',
  #     )
  #   end
  #   it 'Measure 4.3' do
  #     compare_results(
  #       file_path: result_file_prefix + 'spm',
  #       question: '4.3',
  #     )
  #   end
  #   it 'Measure 4.4' do
  #     compare_results(
  #       file_path: result_file_prefix + 'spm',
  #       question: '4.4',
  #     )
  #   end
  #   it 'Measure 4.5' do
  #     compare_results(
  #       file_path: result_file_prefix + 'spm',
  #       question: '4.5',
  #     )
  #   end
  #   it 'Measure 4.6' do
  #     compare_results(
  #       file_path: result_file_prefix + 'spm',
  #       question: '4.6',
  #     )
  #   end

  #   it 'Measure 5.1' do
  #     compare_results(
  #       file_path: result_file_prefix + 'spm',
  #       question: '5.1',
  #       # Pending AAQ: [SPM] All Projects - Data lab test kit Measures 2 and 5 - historic data missing - submitted 10/4/2022
  #       skip: [
  #         'C3',
  #         'C4',
  #       ],
  #     )
  #   end

  #   it 'Measure 5.2' do
  #     compare_results(
  #       file_path: result_file_prefix + 'spm',
  #       question: '5.2',
  #       # Pending AAQ: [SPM] All Projects - Data lab test kit Measures 2 and 5 - historic data missing - submitted 10/4/2022
  #       skip: [
  #         'C3',
  #         'C4',
  #       ],
  #     )
  #   end

  #   it 'Measure 7a.1' do
  #     compare_results(
  #       file_path: result_file_prefix + 'spm',
  #       question: '7a.1',
  #       # Not included in test file since it's an internal calculation
  #       skip: [
  #         'C5',
  #       ],
  #     )
  #   end

  #   it 'Measure 7b.1' do
  #     compare_results(
  #       file_path: result_file_prefix + 'spm',
  #       question: '7b.1',
  #       # Not included in test file since it's an internal calculation
  #       skip: [
  #         'C4',
  #       ],
  #     )
  #   end

  #   it 'Measure 7b.2' do
  #     compare_results(
  #       file_path: result_file_prefix + 'spm',
  #       question: '7b.2',
  #       # Not included in test file since it's an internal calculation
  #       skip: [
  #         'C4',
  #       ],
  #     )
  #   end
  else
    xit 'Data Lab Testkit based tests are skipped, files are missing' do
    end
  end
end

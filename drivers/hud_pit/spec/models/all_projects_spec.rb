###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../datalab_testkit/spec/models/datalab_testkit_context'
require_relative 'pit_context'

require_relative 'questions/additional_homeless_population'
require_relative 'questions/adult_and_child'
require_relative 'questions/adults'
require_relative 'questions/children'
require_relative 'questions/unaccompanied_youth'
require_relative 'questions/parenting_youth'
require_relative 'questions/veteran_adult_and_child'
require_relative 'questions/veteran_adults'
require_relative 'questions/projects'

RSpec.describe 'PIT All-Projects with DataLab TestKit data:', type: :model do
  include_context 'datalab testkit context'
  include_context 'datalab pit context'
  # Only run the tests if the source files are available
  if File.exist?('drivers/datalab_testkit/spec/fixtures/inputs/merged/source/Export.csv')
    before(:all) do
      puts "Starting PIT Tests #{Time.current}"
      setup
      puts "Setup Done for PIT Tests #{Time.current}"
      run(default_pit_filter, HudPit::Generators::Pit::Fy2025::Generator.questions.keys)
      puts "Finished SPM Run Data Lab TestKit #{Time.current}"
    end

    include_context 'additional homeless population'
    include_context 'adult and child'
    include_context 'adults'
    include_context 'children'
    include_context 'unaccompanied youth'
    include_context 'parenting youth'
    include_context 'veteran adult and child'
    include_context 'veteran adults'
    include_context 'projects'

  else
    it 'Data Lab Testkit based tests are skipped, files are missing' do
      expect(true).to be false
    end
  end

  after(:all) do
    cleanup
  end
end

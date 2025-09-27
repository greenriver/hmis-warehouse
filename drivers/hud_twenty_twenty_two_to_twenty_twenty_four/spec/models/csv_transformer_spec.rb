###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudTwentyTwentyTwoToTwentyTwentyFour::CsvTransformer, type: :model do
  FIXTURES = 'drivers/hud_twenty_twenty_two_to_twenty_twenty_four/spec/fixtures' unless const_defined?(:FIXTURES)
  FIXTURES_IN = File.join(FIXTURES, 'in') unless const_defined?(:FIXTURES_IN)
  FIXTURES_OUT = File.join(FIXTURES, 'out') unless const_defined?(:FIXTURES_OUT)
  TEST_DIR = "tmp/test_#{described_class.name.underscore}".freeze unless const_defined?(:TEST_DIR)
  SOURCE_DIR = File.join(TEST_DIR, 'in/merged/source') unless const_defined?(:SOURCE_DIR)
  DEST_DIR = File.join(TEST_DIR, 'out') unless const_defined?(:DEST_DIR)

  before(:each) do
    create_test_dir
  end

  it 'generates an output' do
    skip('Ignoring test, no input files') unless File.exist?(File.join(SOURCE_DIR, 'Export.csv'))

    HudTwentyTwentyTwoToTwentyTwentyFour::CsvTransformer.up(SOURCE_DIR, DEST_DIR)

    expect(compare_test_results).to eq([])
  end

  def create_test_dir
    # Clean up any old test data
    FileUtils.rm_rf(TEST_DIR)

    # Create/populate the test directories
    FileUtils.mkdir_p(File.join(TEST_DIR, 'in'))
    FileUtils.mkdir_p(DEST_DIR)
    FileUtils.cp_r(FIXTURES_IN, TEST_DIR)
  end

  def compare_test_results
    results = []
    expected_files = Dir.glob(File.join(FIXTURES_OUT, '*.csv'))
    expected_files.each do |filename|
      basename = File.basename(filename)
      dest_file = File.join(DEST_DIR, basename)
      results << basename unless File.exist?(dest_file) && FileUtils.identical?(filename, dest_file)
    end
    results
  end
end

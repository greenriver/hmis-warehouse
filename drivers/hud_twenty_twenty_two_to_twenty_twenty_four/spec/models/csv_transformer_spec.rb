###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudTwentyTwentyTwoToTwentyTwentyFour::CsvTransformer, type: :model do
  FIXTURES_2022_2024 = 'drivers/hud_twenty_twenty_two_to_twenty_twenty_four/spec/fixtures'
  FIXTURES_IN_2022_2024 = File.join(FIXTURES_2022_2024, 'in')
  FIXTURES_OUT_2022_2024 = File.join(FIXTURES_2022_2024, 'out')
  TEST_DIR_2022_2024 = "tmp/test_#{described_class.name.underscore}".freeze
  SOURCE_DIR_2022_2024 = File.join(TEST_DIR_2022_2024, 'in/merged/source')
  DEST_DIR_2022_2024 = File.join(TEST_DIR_2022_2024, 'out')

  before(:each) do
    create_test_dir
  end

  it 'generates an output' do
    skip('Ignoring test, no input files') unless File.exist?(File.join(SOURCE_DIR_2022_2024, 'Export.csv'))

    HudTwentyTwentyTwoToTwentyTwentyFour::CsvTransformer.up(SOURCE_DIR_2022_2024, DEST_DIR_2022_2024)

    expect(compare_test_results).to eq([])
  end

  def create_test_dir
    # Clean up any old test data
    FileUtils.rm_rf(TEST_DIR_2022_2024)

    # Create/populate the test directories
    FileUtils.mkdir_p(File.join(TEST_DIR_2022_2024, 'in'))
    FileUtils.mkdir_p(DEST_DIR_2022_2024)
    FileUtils.cp_r(FIXTURES_IN_2022_2024, TEST_DIR_2022_2024)
  end

  # compare contents fo DEST_DIR to FIXTURES_OUT
  def compare_test_results
    results = []
    expected_files = Dir.glob(File.join(FIXTURES_OUT_2022_2024, '*.csv'))
    expected_files.each do |filename|
      basename = File.basename(filename)
      dest_file = File.join(DEST_DIR_2022_2024, basename)
      results << basename unless File.exist?(dest_file) && FileUtils.identical?(filename, dest_file)
    end
    results
  end
end

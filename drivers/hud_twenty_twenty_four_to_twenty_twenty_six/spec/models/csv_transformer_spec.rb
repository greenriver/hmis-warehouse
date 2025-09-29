###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudTwentyTwentyFourToTwentyTwentySix::CsvTransformer, type: :model do
  FIXTURES = 'drivers/hud_twenty_twenty_four_to_twenty_twenty_six/spec/fixtures'
  FIXTURES_IN = File.join(FIXTURES, 'in').freeze
  FIXTURES_OUT = File.join(FIXTURES, 'out').freeze
  TEST_DIR = 'tmp/test'
  SOURCE_DIR = File.join(TEST_DIR, 'in/merged/source').freeze
  DEST_DIR = File.join(TEST_DIR, 'out').freeze

  before(:each) do
    create_test_dir
  end

  it 'generates an output' do
    skip('Ignoring test, no input files') unless File.exist?(File.join(SOURCE_DIR, 'Export.csv'))

    HudTwentyTwentyFourToTwentyTwentySix::CsvTransformer.up(SOURCE_DIR, DEST_DIR)

    expect(compare_test_results).to eq([])
  end

  it 'creates CustomGender.csv with gender data from Client.csv' do
    skip('Ignoring test, no input files') unless File.exist?(File.join(SOURCE_DIR, 'Export.csv'))

    HudTwentyTwentyFourToTwentyTwentySix::CsvTransformer.up(SOURCE_DIR, DEST_DIR)

    custom_gender_file = File.join(DEST_DIR, 'CustomGender.csv')
    expect(File.exist?(custom_gender_file)).to be true

    # Verify the file has content (header + data rows)
    csv_content = CSV.read(custom_gender_file, headers: true)
    expect(csv_content.length).to be > 0

    # Verify required columns exist
    headers = csv_content.headers
    expect(headers).to include(*HmisCsvTwentyTwentySix::Loader::Custom::CustomGender.hud_csv_headers)

    # Verify at least some records have gender data
    records_with_gender = csv_content.select do |row|
      [row['Woman'], row['Man'], row['NonBinary'], row['CulturallySpecific'], row['Transgender']].any? { |val| val.to_i == 1 }
    end
    expect(records_with_gender.length).to be > 0
  end

  it 'creates CustomEnrollmentFY26Deprecations.csv from Enrollment.csv' do
    skip('Ignoring test, no input files') unless File.exist?(File.join(SOURCE_DIR, 'Export.csv'))

    HudTwentyTwentyFourToTwentyTwentySix::CsvTransformer.up(SOURCE_DIR, DEST_DIR)

    custom_enrollment_fy26_deprecations = File.join(DEST_DIR, 'CustomEnrollmentFY26Deprecations.csv')
    expect(File.exist?(custom_enrollment_fy26_deprecations)).to be true

    # Verify the file has the correct headers
    csv_content = CSV.read(custom_enrollment_fy26_deprecations, headers: true)
    headers = csv_content.headers
    expect(headers).to include(*HmisCsvTwentyTwentySix::Loader::Custom::CustomEnrollmentFy26Deprecation.hud_csv_headers)
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

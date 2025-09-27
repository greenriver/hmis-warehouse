###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudTwentyTwentyFourToTwentyTwentySix::CsvTransformer, type: :model do
  FIXTURES_2024_2026 = 'drivers/hud_twenty_twenty_four_to_twenty_twenty_six/spec/fixtures'
  FIXTURES_IN_2024_2026 = File.join(FIXTURES_2024_2026, 'in').freeze
  FIXTURES_OUT_2024_2026 = File.join(FIXTURES_2024_2026, 'out').freeze
  TEST_DIR_2024_2026 = "tmp/test_#{described_class.name.underscore}".freeze
  SOURCE_DIR_2024_2026 = File.join(TEST_DIR_2024_2026, 'in/merged/source').freeze
  DEST_DIR_2024_2026 = File.join(TEST_DIR_2024_2026, 'out').freeze

  before(:each) do
    create_test_dir
  end

  it 'generates an output' do
    skip('Ignoring test, no input files') unless File.exist?(File.join(SOURCE_DIR_2024_2026, 'Export.csv'))

    HudTwentyTwentyFourToTwentyTwentySix::CsvTransformer.up(SOURCE_DIR_2024_2026, DEST_DIR_2024_2026)

    expect(compare_test_results).to eq([])
  end

  it 'creates CustomGender.csv with gender data from Client.csv' do
    skip('Ignoring test, no input files') unless File.exist?(File.join(SOURCE_DIR_2024_2026, 'Export.csv'))

    HudTwentyTwentyFourToTwentyTwentySix::CsvTransformer.up(SOURCE_DIR_2024_2026, DEST_DIR_2024_2026)

    custom_gender_file = File.join(DEST_DIR_2024_2026, 'CustomGender.csv')
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

  it 'creates CustomSexualOrientation.csv from Enrollment.csv' do
    skip('Ignoring test, no input files') unless File.exist?(File.join(SOURCE_DIR_2024_2026, 'Export.csv'))

    HudTwentyTwentyFourToTwentyTwentySix::CsvTransformer.up(SOURCE_DIR_2024_2026, DEST_DIR_2024_2026)

    custom_sexual_orientation_file = File.join(DEST_DIR_2024_2026, 'CustomSexualOrientation.csv')
    expect(File.exist?(custom_sexual_orientation_file)).to be true

    # Verify the file has the correct headers
    csv_content = CSV.read(custom_sexual_orientation_file, headers: true)
    headers = csv_content.headers
    expect(headers).to include(*HmisCsvTwentyTwentySix::Loader::Custom::CustomSexualOrientation.hud_csv_headers)
  end

  def create_test_dir
    # Clean up any old test data
    FileUtils.rm_rf(TEST_DIR_2024_2026)

    # Create/populate the test directories
    FileUtils.mkdir_p(File.join(TEST_DIR_2024_2026, 'in'))
    FileUtils.mkdir_p(DEST_DIR_2024_2026)
    FileUtils.cp_r(FIXTURES_IN_2024_2026, TEST_DIR_2024_2026)
  end

  # compare contents fo DEST_DIR to FIXTURES_OUT
  def compare_test_results
    results = []
    expected_files = Dir.glob(File.join(FIXTURES_OUT_2024_2026, '*.csv'))
    expected_files.each do |filename|
      basename = File.basename(filename)
      dest_file = File.join(DEST_DIR_2024_2026, basename)
      results << basename unless File.exist?(dest_file) && FileUtils.identical?(filename, dest_file)
    end
    results
  end
end

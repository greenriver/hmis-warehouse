require 'rails_helper'

RSpec.describe HudTwentyTwentyTwoToTwentyTwentyFour::CsvTransformer, type: :model do
  FIXTURES = 'drivers/hud_twenty_twenty_two_to_twenty_twenty_four/spec/fixtures'.freeze
  FIXTURES_IN = File.join(FIXTURES, 'in').freeze
  FIXTURES_OUT = File.join(FIXTURES, 'out').freeze
  TEST_DIR = 'tmp/test'.freeze
  SOURCE_DIR = File.join(TEST_DIR, 'in/merged/source').freeze
  DEST_DIR = File.join(TEST_DIR, 'out').freeze

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
    Dir.glob(File.join(FIXTURES_OUT, '*.csv')).each do |filename|
      basename = File.basename(filename)
      results << basename unless FileUtils.identical?(filename, File.join(DEST_DIR, basename))
    end
    results
  end
end

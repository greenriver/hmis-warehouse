require 'rails_helper'

RSpec.describe HudTwentyTwentyTwoToTwentyTwentyFour::CsvTransformer, type: :model do
  FIXTURES = 'drivers/hud_twenty_twenty_two_to_twenty_twenty_four/spec/fixtures/in'.freeze
  TEST_DIR = 'tmp/test'.freeze
  SOURCE_DIR = 'tmp/test/in/merged/source'.freeze
  DEST_DIR = 'tmp/test/out'.freeze

  before(:each) do
    create_test_dir
  end

  it 'generates an output' do
    skip('Ignoring test, no input files') unless File.exist?(File.join(SOURCE_DIR, 'Export.csv'))

    ENV['TZ'] = 'US/Eastern' # Force the TZ to make the calls to Time.current in the transformer work
    travel_to Time.local(2023, 8, 24, 1, 2, 3) do
      HudTwentyTwentyTwoToTwentyTwentyFour::CsvTransformer.up(SOURCE_DIR, DEST_DIR)
    end

    expect(compare_test_results).to eq([])
  end

  def create_test_dir
    # Clean up any old test data
    FileUtils.rm_rf(TEST_DIR)

    # Create/populate the test directories
    FileUtils.mkdir_p(File.join(TEST_DIR, 'in'))
    FileUtils.mkdir_p(DEST_DIR)
    FileUtils.cp_r(FIXTURES, TEST_DIR)
  end

  def compare_test_results
    results = []
    Dir.glob(File.join(FIXTURES, 'out/*.csv')).each do |filename|
      basename = File.basename(filename)
      results << basename unless FileUtils.identical?(filename, File.join(DEST_DIR, basename))
    end
    results
  end
end

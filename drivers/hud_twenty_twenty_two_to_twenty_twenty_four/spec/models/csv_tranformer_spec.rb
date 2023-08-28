require 'rails_helper'

RSpec.describe HudTwentyTwentyTwoToTwentyTwentyFour::CsvTransformer, type: :model do
  FIXTURES = 'drivers/hud_twenty_twenty_two_to_twenty_twenty_four/spec/fixtures'.freeze
  TEST_DIR = 'tmp/test'.freeze
  SOURCE_DIR = 'tmp/test/in'.freeze
  DEST_DIR = 'tmp/test/out'.freeze

  before(:each) do
    create_test_dir
  end

  it 'generates an output' do
    ENV['TZ'] = 'US/Eastern' # Force the TZ to make the calls to Time.current in the transformer work
    travel_to Time.local(2023, 8, 24, 1, 2, 3) do
      HudTwentyTwentyTwoToTwentyTwentyFour::CsvTransformer.up(SOURCE_DIR, DEST_DIR)
    end

    expect(compare_test_results).to eq([])
  end

  def create_test_dir
    FileUtils.mkdir_p(TEST_DIR)

    # Clean up any old tests
    FileUtils.rm_rf(SOURCE_DIR)
    FileUtils.rm_rf(DEST_DIR)

    # Create/populate the test directories
    FileUtils.cp_r(File.join(FIXTURES, 'in'), SOURCE_DIR)
    FileUtils.mkdir_p(DEST_DIR)
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

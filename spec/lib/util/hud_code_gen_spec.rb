# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudCodeGen do
  describe '.generate_hud_lists' do
    let(:test_year) { 'test' }
    let(:temp_dir) { Dir.mktmpdir }
    let(:output_file) { File.join(temp_dir, "hud_lists_#{test_year}.rb") }

    # Create minimal test data
    let(:test_data) do
      [
        {
          'name' => 'ExportPeriodType',
          'code' => '1.1',
          'values' => [
            { 'key' => 1, 'description' => 'Updated' },
            { 'key' => 3, 'description' => 'Reporting period' },
          ],
        },
        {
          'name' => 'NoYesMissing',
          'code' => '1.7',
          'values' => [
            { 'key' => 0, 'description' => 'No' },
            { 'key' => 1, 'description' => 'Yes' },
            { 'key' => 99, 'description' => 'Data not collected' },
          ],
        },
      ]
    end

    let(:deprecated_test_data) do
      [
        {
          'name' => 'NoYesMissing',
          'code' => '1.7',
          'values' => [
            { 'key' => 2, 'description' => 'Deprecated Option' },
          ],
        },
        {
          'name' => 'NewDeprecatedList',
          'code' => '99.9',
          'values' => [
            { 'key' => 10, 'description' => 'New Deprecated Value' },
          ],
        },
      ]
    end

    before do
      # Mock file operations to use test data and temp directory
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with("lib/data/#{test_year}_hud_lists.json").and_return(test_data.to_json)

      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with("lib/data/#{test_year}_hud_deprecations.json").and_return(true)
      allow(File).to receive(:read).with("lib/data/#{test_year}_hud_deprecations.json").and_return(deprecated_test_data.to_json)

      # Allow the actual file write to happen in temp directory
      original_open = File.method(:open)
      allow(File).to receive(:open).and_call_original
      allow(File).to receive(:open) do |path, mode, &block|
        if path.include?("hud_lists_#{test_year}.rb")
          original_open.call(output_file, mode, &block)
        else
          original_open.call(path, mode, &block)
        end
      end
    end

    after do
      FileUtils.rm_rf(temp_dir)
    end

    it 'generates a Ruby module file with correct structure' do
      # This is a smoke test using mocked data
      result = described_class.generate_hud_lists(test_year)

      expect(result).to include("hud_lists_#{test_year}.rb")
      expect(File.exist?(output_file)).to be true

      # Read the generated file and verify basic structure
      content = File.read(output_file)
      expect(content).to include("module Concerns::HudLists#{test_year}")
      expect(content).to include('extend ActiveSupport::Concern')
      expect(content).to include('class_methods do')
      expect(content).to include('# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY')

      # Should contain the specific HUD list methods and their lookup functions based on test data
      expect(content).to include('def period_types')
      expect(content).to include('def export_period_type(id, reverse = false, raise_on_missing: false)')
      expect(content).to include('def yes_no_missing_options')
      expect(content).to include('def no_yes_missing(id, reverse = false, raise_on_missing: false)')
    end

    it 'generates methods for known HUD lists' do
      described_class.generate_hud_lists(test_year)
      content = File.read(output_file)

      # Check for expected methods based on our test data
      expect(content).to include('def period_types') # Should be period_types due to override
      expect(content).to include('def export_period_type(')
      expect(content).to include('def yes_no_missing_options') # Should be yes_no_missing_options due to override
      expect(content).to include('def no_yes_missing(')

      # Check for actual values from test data
      expect(content).to include('1 => "Updated"')
      expect(content).to include('0 => "No"')
      expect(content).to include('99 => "Data not collected"')
    end

    it 'merges deprecated lists correctly' do
      described_class.generate_hud_lists(test_year)
      content = File.read(output_file)

      # Verify deprecated value for an existing list is merged
      expect(content).to include('2 => "Deprecated Option"')
      # Verify a completely new deprecated list is added
      expect(content).to include('def new_deprecated_lists')
      expect(content).to include('10 => "New Deprecated Value"')
    end

    it 'raises an error for nil year' do
      expect { described_class.generate_hud_lists(nil) }.to raise_error(ArgumentError, 'Year is required')
    end

    context 'when merging deprecations' do
      it 'does not create duplicate methods for merged lists' do
        described_class.generate_hud_lists(test_year)
        generated_content = File.read(output_file)

        # This test ensures that merging them does not result in duplicate method definitions.
        expect(generated_content.scan(/def yes_no_missing_options/).length).to eq(1)
      end
    end
  end
end

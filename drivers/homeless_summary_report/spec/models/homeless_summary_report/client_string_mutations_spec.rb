# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HomelessSummaryReport::Client, type: :model do
  describe '.adjust_attribute_name method with gsub! operations' do
    it 'uses gsub! to shorten long attribute names' do
      # Test the gsub! operation from line 51: name.gsub!(raw.to_s, abbrev.to_s)

      # Test attribute name that needs shortening
      long_name = 'spm_without_children_and_fifty_five_plus_hispanic_latinaeo'

      # Call the actual class method that contains the gsub! operation
      result = HomelessSummaryReport::Client.adjust_attribute_name(long_name)

      # Should shorten the name using gsub! operations
      expect(result).to be_a(Symbol)
      expect(result.to_s.length).to be <= 63
    end

    it 'handles attribute names that do not need shortening' do
      short_name = 'short_name'

      result = HomelessSummaryReport::Client.adjust_attribute_name(short_name)

      expect(result).to eq(:short_name)
    end

    it 'applies multiple gsub! replacements for very long names' do
      # Test name that requires multiple gsub! operations
      very_long_name = 'spm_adults_with_children_where_parenting_adult_18_to_24_returned_to_homelessness_from_permanent_destination'

      result = HomelessSummaryReport::Client.adjust_attribute_name(very_long_name)

      # Should apply multiple gsub! operations to shorten the name
      expect(result).to be_a(Symbol)
      expect(result.to_s.length).to be <= 63
    end

    it 'raises error when name cannot be shortened enough' do
      # Create a name that cannot be shortened by the gsub! operations
      impossible_name = 'x' * 70 # 70 character string with no replaceable parts

      expect { HomelessSummaryReport::Client.adjust_attribute_name(impossible_name) }.to raise_error(/Couldn't truncate attribute name/)
    end
  end

  describe 'method calls that exercise string mutations' do
    it 'exercises adjust_attribute_name with various inputs' do
      # Test different scenarios that exercise the gsub! operations
      names_to_test = [
        'without_children_and_fifty_five_plus',
        'adults_with_children_where_parenting_adult_18_to_24',
        'returned_to_homelessness_from_permanent_destination',
        'normal_short_name',
      ]

      names_to_test.each do |name|
        result = HomelessSummaryReport::Client.adjust_attribute_name(name)
        expect(result).to be_a(Symbol)
      end
    end

    it 'can create new instance with default values' do
      # Test that the class can be instantiated (ensures other methods work)
      client = HomelessSummaryReport::Client.new_with_default_values

      expect(client).to be_a(HomelessSummaryReport::Client)
    end
  end
end

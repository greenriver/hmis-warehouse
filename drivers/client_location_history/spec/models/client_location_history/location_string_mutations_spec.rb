# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClientLocationHistory::Location, type: :model do
  describe '.highlight method with << operations' do
    it 'calls method that contains << operations for label modification' do
      # Test the << operation from line 82: most_recent[:label] << '<strong>Most-recent contact</strong>'.html_safe

      # Create test markers with dates
      older_marker = {
        lat_lon: [40.7128, -74.0060],
        label: ['Seen on: 2024-01-01', 'by Staff A'],
        date: Date.parse('2024-01-01'),
        highlight: false,
      }

      recent_marker = {
        lat_lon: [40.7589, -73.9851],
        label: ['Seen on: 2024-01-15', 'by Staff B'],
        date: Date.parse('2024-01-15'),
        highlight: false,
      }

      markers = [older_marker, recent_marker]

      # Call the actual method that contains the << operation
      result = described_class.highlight(markers)

      # The method should return the markers with the most recent one modified
      expect(result).to eq(markers)

      # The most recent marker should have highlight set to true
      expect(recent_marker[:highlight]).to be(true)

      # The << operation should have added the strong text to the most recent marker's label
      expect(recent_marker[:label]).to include('<strong>Most-recent contact</strong>')

      # The older marker should remain unchanged
      expect(older_marker[:highlight]).to be(false)
      expect(older_marker[:label]).not_to include('<strong>Most-recent contact</strong>')
    end

    it 'exercises << operation with single marker' do
      # Test << operation with only one marker

      single_marker = {
        lat_lon: [40.7128, -74.0060],
        label: ['Single location'],
        date: Date.current,
        highlight: false,
      }

      markers = [single_marker]

      result = described_class.highlight(markers)

      # The single marker should become the "most recent" and get the << operation
      expect(single_marker[:highlight]).to be(true)
      expect(single_marker[:label]).to include('<strong>Most-recent contact</strong>')
      expect(result.length).to eq(1)
    end

    it 'exercises << operation with markers having same date' do
      # Test << operation when multiple markers have the same date (max_by behavior)

      marker1 = {
        lat_lon: [40.7128, -74.0060],
        label: ['Location 1'],
        date: Date.current,
        highlight: false,
      }

      marker2 = {
        lat_lon: [40.7589, -73.9851],
        label: ['Location 2'],
        date: Date.current,
        highlight: false,
      }

      markers = [marker1, marker2]

      result = described_class.highlight(markers)

      # max_by should pick one of them for the << operation
      highlighted_markers = result.select { |m| m[:highlight] }
      expect(highlighted_markers.length).to eq(1)

      highlighted_marker = highlighted_markers.first
      expect(highlighted_marker[:label]).to include('<strong>Most-recent contact</strong>')
    end

    it 'handles empty markers array without << operation' do
      # Test that empty array returns early, avoiding the << operation

      result = described_class.highlight([])

      # Should return empty array without attempting << operation
      expect(result).to eq([])
    end

    it 'exercises << operation with complex label arrays' do
      # Test << operation with various label formats

      complex_marker = {
        lat_lon: [40.7128, -74.0060],
        label: ['Client Name', 'Seen on: 2024-01-15 10:30 AM', 'by Case Manager', 'Additional notes'],
        date: Date.parse('2024-01-15'),
        highlight: false,
      }

      markers = [complex_marker]

      described_class.highlight(markers)

      # The << operation should add to the existing label array
      expect(complex_marker[:label]).to include('Client Name')
      expect(complex_marker[:label]).to include('Seen on: 2024-01-15 10:30 AM')
      expect(complex_marker[:label]).to include('by Case Manager')
      expect(complex_marker[:label]).to include('Additional notes')
      expect(complex_marker[:label]).to include('<strong>Most-recent contact</strong>')

      # Should have 5 items in the label array after << operation
      expect(complex_marker[:label].length).to eq(5)
    end
  end

  describe 'method calls that exercise string mutations' do
    it 'exercises bounds method without string mutations' do
      # Test supporting method that doesn't contain string mutations
      locations = double('locations')
      allow(locations).to receive(:maximum).with(:lat).and_return(40.8)
      allow(locations).to receive(:minimum).with(:lat).and_return(40.7)
      allow(locations).to receive(:maximum).with(:lon).and_return(-73.9)
      allow(locations).to receive(:minimum).with(:lon).and_return(-74.1)

      result = described_class.bounds(locations)

      expect(result).to eq([[40.7, -74.1], [40.8, -73.9]])
    end

    it 'creates new instance without error' do
      location = described_class.new

      expect(location).to be_a(described_class)
    end

    it 'exercises as_marker method that provides data to highlight method' do
      location = described_class.new(lat: 40.7128, lon: -74.0060, located_on: Date.current)
      allow(location).to receive(:label).and_return(['Test label'])

      result = location.as_marker

      # Should return hash structure compatible with highlight method
      expect(result).to have_key(:lat_lon)
      expect(result).to have_key(:label)
      expect(result).to have_key(:date)
      expect(result).to have_key(:highlight)
      expect(result[:highlight]).to be(false)
    end
  end
end

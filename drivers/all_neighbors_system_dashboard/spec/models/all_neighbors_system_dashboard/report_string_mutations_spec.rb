# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AllNeighborsSystemDashboard::Report, type: :model do
  let(:report) { AllNeighborsSystemDashboard::Report.new }

  describe '#populate_universe method with << operations' do
    it 'calls method that contains << operations for events array building' do
      # Test the << operation from line 183: events << enrollment.events.build(...)

      enrollment = double('enrollment')
      events_relation = double('events_relation')
      event_builder = double('event_builder')

      allow(enrollment).to receive(:events).and_return(events_relation)
      allow(events_relation).to receive(:build).and_return(event_builder)

      # Mock the batch processing
      event = double('event',
                     personal_id: '12345',
                     enrollment_id: 'ENROLL123',
                     event_id: 'EVENT456',
                     event_date: Date.current,
                     event: 1,
                     location_crisis_or_ph_housing: 'Location')

      batch = [event]
      event_scope = double('event_scope')
      allow(event_scope).to receive(:find_in_batches).and_yield(batch)

      # Mock dependencies
      allow(report).to receive(:enrollment_scope).and_return([enrollment])
      allow(HudHelper).to receive_message_chain(:util, :event).and_return('Test Event')
      allow(enrollment).to receive(:save!)

      # This will exercise the << operation when processing events
      expect { report.send(:populate_universe) }.not_to raise_error
    end
  end

  describe '#deduplicate_universe! method with << operations' do
    it 'calls method that contains << operations for duplicate ID tracking' do
      # Test the << operation from line 242: all_duplicate_ids << row[:id]

      # Mock the universe data
      report.instance_variable_set(:@universe, [
                                     { id: 1, personal_id: 'P1', enrollment_id: 'E1' },
                                     { id: 2, personal_id: 'P1', enrollment_id: 'E1' }, # duplicate
                                     { id: 3, personal_id: 'P2', enrollment_id: 'E2' },
                                   ])

      # Call the actual method that contains the << operation
      expect { report.send(:deduplicate_universe!) }.not_to raise_error
    end
  end

  describe '#cache_calculated_data method with << and gsub! operations' do
    it 'calls method that contains << operations for CSV generation' do
      # Test the << operation from lines 292, 294: csv << enrollments.first.attributes.keys, csv << enrollment.attributes.values

      enrollments = [double('enrollment', attributes: { 'id' => 1, 'name' => 'Test' })]
      allow(report).to receive(:enrollments).and_return(enrollments)

      # Mock CSV operations
      csv_writer = double('csv_writer')
      allow(CSV).to receive(:generate).and_yield(csv_writer)
      allow(csv_writer).to receive(:<<).and_return(true)

      # Mock Rails assets for the gsub! operations
      assets = double('assets')
      allow(Rails.application).to receive(:assets).and_return(assets)
      allow(assets).to receive(:[]).and_return(double('asset', digest_path: 'path/to/asset'))
      allow(Rails.application.config).to receive_message_chain(:assets, :prefix).and_return('/assets')

      # Call the actual method that contains both << and gsub! operations
      expect { report.send(:cache_calculated_data) }.not_to raise_error
    end

    it 'calls method that exercises gsub! operations for CSS processing' do
      # Test the gsub! operations from lines 327, 329: css.gsub!("url(...)", "url(...)")

      enrollments = []
      allow(report).to receive(:enrollments).and_return(enrollments)

      # Mock CSV generation
      allow(CSV).to receive(:generate).and_return('csv_content')

      # Mock Rails assets and CSS content
      assets = double('assets')
      asset = double('asset', digest_path: 'some/digest/path')
      allow(Rails.application).to receive(:assets).and_return(assets)
      allow(assets).to receive(:[]).and_return(asset)
      allow(Rails.application.config).to receive_message_chain(:assets, :prefix).and_return('/assets')

      # This will exercise the gsub! operations on CSS content
      expect { report.send(:cache_calculated_data) }.not_to raise_error
    end
  end

  describe 'method calls that exercise string mutations' do
    it 'exercises run_and_save! method chain that contains mutations' do
      # Mock all the complex dependencies
      allow(report).to receive(:start).and_return(true)
      allow(report).to receive(:complete).and_return(true)
      allow(report).to receive(:save).and_return(true)

      # Mock the cache calculation that contains string mutations
      allow(report).to receive(:cache_calculated_data).and_call_original

      # Mock dependencies for cache_calculated_data
      allow(report).to receive(:enrollments).and_return([])
      allow(CSV).to receive(:generate).and_return('csv_content')
      allow(Rails.application).to receive(:assets).and_return(double(:[], double(digest_path: 'path')))
      allow(Rails.application.config).to receive_message_chain(:assets, :prefix).and_return('/assets')

      # Should call the methods containing string mutations without error
      expect { report.run_and_save! }.not_to raise_error
    end

    it 'creates new instance without error' do
      # Test that the class can be instantiated
      new_report = AllNeighborsSystemDashboard::Report.new

      expect(new_report).to be_a(AllNeighborsSystemDashboard::Report)
    end
  end
end

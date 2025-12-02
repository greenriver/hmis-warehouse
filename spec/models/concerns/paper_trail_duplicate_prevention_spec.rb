# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe 'Paper Trail Duplicate Prevention', type: :model do
  # Create a temporary table and model for testing
  before(:all) do
    # Use the warehouse database connection
    GrdaWarehouseBase.connection.execute(<<~SQL)
      CREATE TABLE IF NOT EXISTS test_paper_trail_models (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255),
        description TEXT,
        created_at TIMESTAMP,
        updated_at TIMESTAMP
      )
    SQL

    # Define a test model class
    class TestPaperTrailModel < GrdaWarehouseBase
      self.table_name = 'test_paper_trail_models'
      has_paper_trail
    end
  end

  after(:all) do
    # Clean up: remove the test table and class
    GrdaWarehouseBase.connection.execute('DROP TABLE IF EXISTS test_paper_trail_models CASCADE')
    Object.send(:remove_const, :TestPaperTrailModel) if defined?(TestPaperTrailModel)
  end

  describe 'single version creation' do
    around(:example) do |ex|
      PaperTrailHelper.with_paper_trail do
        PaperTrail.request.enabled = true
        ex.run
      ensure
        PaperTrail.request.enabled = false
      end
    end

    it 'creates only 1 version on create' do
      expect do
        TestPaperTrailModel.create!(name: 'Test', description: 'Test Description')
      end.to change(GrdaWarehouse::Version, :count).by(1)
    end

    it 'creates only 1 version on update' do
      record = TestPaperTrailModel.create!(name: 'Test', description: 'Original')

      expect do
        record.update!(description: 'Updated')
      end.to change(GrdaWarehouse::Version, :count).by(1)
    end

    it 'creates only 1 version on destroy' do
      record = TestPaperTrailModel.create!(name: 'Test', description: 'To Delete')

      expect do
        record.destroy
      end.to change(GrdaWarehouse::Version, :count).by(1)
    end

    it 'stores version with correct model type' do
      record = TestPaperTrailModel.create!(name: 'Test', description: 'Check Version')

      version = GrdaWarehouse::Version.where(
        item_type: 'TestPaperTrailModel',
        item_id: record.id,
      ).last

      expect(version).to be_present
      expect(version.item_type).to eq('TestPaperTrailModel')
      expect(version.event).to eq('create')
    end
  end

  describe 'safeguard against duplicate has_paper_trail calls' do
    it 'raises an error in non-production environments when has_paper_trail is called twice' do
      expect do
        Class.new(GrdaWarehouseBase) do
          self.table_name = 'test_paper_trail_models'
          has_paper_trail
          has_paper_trail # This should raise an error
        end
      end.to raise_error(StandardError, /PaperTrail already enabled/)
    end

    it 'includes helpful backtrace information in the error message' do
      Class.new(GrdaWarehouseBase) do
        self.table_name = 'test_paper_trail_models'
        has_paper_trail
        has_paper_trail
      end
    rescue StandardError => e
      expect(e.message).to include('PaperTrail already enabled')
      expect(e.message).to include('Called from:')
    end

    it 'raises when a subclass mixes in has_paper_trail after the parent already enabled it' do
      parent_class = Class.new(GrdaWarehouseBase) do
        self.table_name = 'test_paper_trail_models'
        has_paper_trail
      end

      mixin = Module.new do
        def self.included(base)
          base.has_paper_trail
        end
      end

      expect do
        Class.new(parent_class) do
          include mixin
        end
      end.to raise_error(StandardError, /PaperTrail already enabled/)
    end
  end
  it 'logs to Sentry in production instead of raising' do
    # Stub Rails.env to return production
    allow(Rails.env).to receive(:production?).and_return(true)

    # Expect Sentry to receive the warning message
    expect(Sentry).to receive(:capture_message).with(
      /PaperTrail already enabled/,
      hash_including(level: :warning),
    )

    # Should not raise an error in production
    expect do
      Class.new(GrdaWarehouseBase) do
        self.table_name = 'test_paper_trail_models'
        has_paper_trail
        has_paper_trail
      end
    end.not_to raise_error
  end
end

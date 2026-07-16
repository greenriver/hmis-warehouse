###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GrdaWarehouseBase PaperTrail configuration', type: :model do
  # GrdaWarehouseBase forces every warehouse model to record versions into
  # GrdaWarehouse::Version. Unlike HealthBase it does not enable paper_trail in
  # its own body, so each concrete model declares it once (the super path). A
  # second declaration (e.g. an abstract base plus a subclass) is merged in
  # place -- like HealthBase -- rather than raising.
  before(:all) do
    GrdaWarehouseBase.connection.execute(<<~SQL)
      CREATE TABLE IF NOT EXISTS test_paper_trail_models (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255),
        description TEXT,
        created_at TIMESTAMP,
        updated_at TIMESTAMP
      )
    SQL

    class TestPaperTrailModel < GrdaWarehouseBase
      self.table_name = 'test_paper_trail_models'
      has_paper_trail
    end

    class TestPaperTrailParent < GrdaWarehouseBase
      self.table_name = 'test_paper_trail_models'
      has_paper_trail
    end

    class TestPaperTrailChild < TestPaperTrailParent
      has_paper_trail ignore: [:description, :updated_at]
    end
  end

  after(:all) do
    GrdaWarehouseBase.connection.execute('DROP TABLE IF EXISTS test_paper_trail_models CASCADE')
    [:TestPaperTrailChild, :TestPaperTrailParent, :TestPaperTrailModel].each do |const|
      Object.send(:remove_const, const) if Object.const_defined?(const)
    end
  end

  around(:example) do |ex|
    PaperTrailHelper.with_paper_trail do
      PaperTrail.request.enabled = true
      ex.run
    ensure
      PaperTrail.request.enabled = false
    end
  end

  describe 'a model that declares has_paper_trail once (super path)' do
    it 'records exactly one version on create, and nothing in the default (primary) versions table' do
      expect do
        TestPaperTrailModel.create!(name: 'Test', description: 'Test Description')
      end.to change(GrdaWarehouse::Version, :count).by(1).and change(PaperTrail::Version, :count).by(0)
    end

    it 'records exactly one version on update' do
      record = TestPaperTrailModel.create!(name: 'Test', description: 'Original')

      expect do
        record.update!(description: 'Updated')
      end.to change(GrdaWarehouse::Version, :count).by(1)
    end

    it 'records exactly one version on destroy' do
      record = TestPaperTrailModel.create!(name: 'Test', description: 'To Delete')

      expect do
        record.destroy
      end.to change(GrdaWarehouse::Version, :count).by(1)
    end

    it 'stores versions via GrdaWarehouse::Version' do
      record = TestPaperTrailModel.create!(name: 'Test', description: 'Check Version')
      version = GrdaWarehouse::Version.where(item_type: 'TestPaperTrailModel', item_id: record.id).last

      expect(version).to be_present
      expect(version.event).to eq('create')
      expect(TestPaperTrailModel.version_class_name).to eq('GrdaWarehouse::Version')
      # The original bug wrote the duplicate version into the primary database's
      # default versions table; confirm nothing landed there.
      expect(PaperTrail::Version.where(item_type: 'TestPaperTrailModel', item_id: record.id)).to be_empty
    end
  end

  describe 'a subclass that re-declares has_paper_trail (merge path)' do
    it 'does not raise and keeps GrdaWarehouse::Version' do
      # before(:all) already re-declared has_paper_trail without raising
      expect(TestPaperTrailChild.version_class_name).to eq('GrdaWarehouse::Version')
    end

    it 'records exactly one version on create, and nothing in the default (primary) versions table' do
      expect do
        TestPaperTrailChild.create!(name: 'Test', description: 'x')
      end.to change(GrdaWarehouse::Version, :count).by(1).and change(PaperTrail::Version, :count).by(0)
    end

    it 'honors the ignore option merged from the subclass' do
      record = TestPaperTrailChild.create!(name: 'Test', description: 'x')

      expect do
        record.update!(description: 'y')
      end.not_to change(GrdaWarehouse::Version, :count)

      expect do
        record.update!(name: 'Renamed')
      end.to change(GrdaWarehouse::Version, :count).by(1)
    end

    it 'preserves the inherited lock_version skip default' do
      expect(TestPaperTrailChild.paper_trail_options[:skip]).to include('lock_version')
    end
  end
end

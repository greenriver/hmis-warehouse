###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'HealthBase PaperTrail configuration', type: :model do
  # HealthBase enables paper_trail in its class body, so every subclass is
  # already versioned. These temp models exercise both a subclass that
  # re-declares has_paper_trail (merge path) and one that only inherits.
  before(:all) do
    HealthBase.connection.execute(<<~SQL)
      CREATE TABLE IF NOT EXISTS test_health_paper_trail_models (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255),
        secret_col VARCHAR(255)
      )
    SQL

    class TestHealthPaperTrailModel < HealthBase
      self.table_name = 'test_health_paper_trail_models'
      has_paper_trail ignore: [:secret_col]
    end

    class TestHealthInheritedModel < HealthBase
      self.table_name = 'test_health_paper_trail_models'
    end
  end

  after(:all) do
    HealthBase.connection.execute('DROP TABLE IF EXISTS test_health_paper_trail_models CASCADE')
    Object.send(:remove_const, :TestHealthPaperTrailModel) if defined?(TestHealthPaperTrailModel)
    Object.send(:remove_const, :TestHealthInheritedModel) if defined?(TestHealthInheritedModel)
  end

  around(:example) do |ex|
    PaperTrailHelper.with_paper_trail do
      PaperTrail.request.enabled = true
      ex.run
    ensure
      PaperTrail.request.enabled = false
    end
  end

  describe 'a subclass that re-declares has_paper_trail (merge path)' do
    it 'records exactly one version on create, and nothing in the default (primary) versions table' do
      expect do
        TestHealthPaperTrailModel.create!(name: 'A')
      end.to change(Health::HealthVersion, :count).by(1).and change(PaperTrail::Version, :count).by(0)
    end

    it 'records exactly one version on update' do
      record = TestHealthPaperTrailModel.create!(name: 'A')

      expect do
        record.update!(name: 'B')
      end.to change(Health::HealthVersion, :count).by(1)
    end

    it 'records exactly one version on destroy' do
      record = TestHealthPaperTrailModel.create!(name: 'A')

      expect do
        record.destroy
      end.to change(Health::HealthVersion, :count).by(1)
    end

    it 'stores versions via Health::HealthVersion, not the default PaperTrail::Version' do
      record = TestHealthPaperTrailModel.create!(name: 'A')

      expect(record.versions.first).to be_a(Health::HealthVersion)
      expect(TestHealthPaperTrailModel.version_class_name).to eq('Health::HealthVersion')
      # The original bug wrote the duplicate version into the primary database's
      # default versions table; confirm nothing landed there.
      expect(PaperTrail::Version.where(item_type: 'TestHealthPaperTrailModel', item_id: record.id)).to be_empty
    end

    it 'honors the ignore option merged from the subclass' do
      record = TestHealthPaperTrailModel.create!(name: 'A', secret_col: 'x')

      expect do
        record.update!(secret_col: 'y')
      end.not_to change(Health::HealthVersion, :count)

      expect do
        record.update!(name: 'B')
      end.to change(Health::HealthVersion, :count).by(1)
    end
  end

  describe 'a subclass that inherits versioning without re-declaring' do
    it 'still records exactly one version into Health::HealthVersion' do
      expect do
        TestHealthInheritedModel.create!(name: 'A')
      end.to change(Health::HealthVersion, :count).by(1).and change(PaperTrail::Version, :count).by(0)

      expect(TestHealthInheritedModel.version_class_name).to eq('Health::HealthVersion')
    end
  end

  describe 'real HealthBase subclasses that re-declare has_paper_trail' do
    it 'keeps ClaimsReporting::CpPaymentUpload on Health::HealthVersion with content ignored' do
      expect(ClaimsReporting::CpPaymentUpload.version_class_name).to eq('Health::HealthVersion')
      expect(ClaimsReporting::CpPaymentUpload.paper_trail_options[:ignore]).to include('content')
    end

    it 'keeps Health::Tracing::Contact on Health::HealthVersion' do
      expect(Health::Tracing::Contact.version_class_name).to eq('Health::HealthVersion')
    end
  end
end

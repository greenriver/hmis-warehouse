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

    # Merge-semantics fixtures. HealthBase self-declares has_paper_trail, so both
    # of these hit the merge branch. The contract is per-key overwrite: the child
    # replaces the parent's value for a key it re-declares. (meta is not exercised
    # here -- no Health model uses it and HealthBase has no paper_trail_meta_value;
    # the meta merge is covered against GrdaWarehouseBase.)
    class TestHealthMergeParent < HealthBase
      self.table_name = 'test_health_paper_trail_models'
      has_paper_trail ignore: [:name]
    end

    class TestHealthMergeChild < TestHealthMergeParent
      has_paper_trail ignore: [:secret_col]
    end

    # :if/:unless are read at event time (PaperTrail::RecordTrail#save_version?),
    # so the merge must carry them through. unless -> true means "never version".
    class TestHealthConditionalModel < HealthBase
      self.table_name = 'test_health_paper_trail_models'
      has_paper_trail unless: ->(_record) { true }
    end
  end

  after(:all) do
    HealthBase.connection.execute('DROP TABLE IF EXISTS test_health_paper_trail_models CASCADE')
    [:TestHealthPaperTrailModel, :TestHealthInheritedModel, :TestHealthMergeChild, :TestHealthMergeParent, :TestHealthConditionalModel].each do |const|
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

  describe 'merge overwrite semantics (child config replaces parent per key)' do
    it 'replaces the parent ignore list rather than unioning it' do
      # Parent ignored :name; child re-declares ignore: [:secret_col]. After the
      # merge the child ignores secret_col (not name).
      record = TestHealthMergeChild.create!(name: 'A', secret_col: 'B')

      # child's own ignore still applies -> a secret_col-only change records nothing
      expect do
        record.update!(secret_col: 'D')
      end.not_to change(Health::HealthVersion, :count)

      # parent's :name ignore was dropped (overwritten, not unioned) -> name is
      # tracked again; if the lists had been unioned this would record nothing.
      expect do
        record.update!(name: 'C')
      end.to change(Health::HealthVersion, :count).by(1)
    end

    it 'leaves the parent ignore list untouched when the child re-declares' do
      # Defining TestHealthMergeChild must not mutate TestHealthMergeParent's
      # config (the merge dups before mutating). The parent must still ignore
      # name and track secret_col.
      record = TestHealthMergeParent.create!(name: 'A', secret_col: 'B')

      expect do
        record.update!(name: 'C')
      end.not_to change(Health::HealthVersion, :count)

      expect do
        record.update!(secret_col: 'D')
      end.to change(Health::HealthVersion, :count).by(1)
    end

    it 'does not apply a default lock_version skip (unlike GrdaWarehouseBase)' do
      # HealthBase intentionally omits the lock_version skip default that
      # GrdaWarehouseBase supplies; health tables need not carry lock_version.
      skip = Array(TestHealthInheritedModel.paper_trail_options[:skip]).map(&:to_s)

      expect(skip).not_to include('lock_version')
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

  describe 'event-time conditions and the setup-only guard' do
    it 'carries an :unless condition through the merge (records nothing when it returns true)' do
      expect do
        TestHealthConditionalModel.create!(name: 'A')
      end.not_to change(Health::HealthVersion, :count)
    end

    it 'raises when a subclass re-declares a setup-only option (e.g. versions)' do
      # Options consumed at setup time (versions/class_name/on/version) cannot take
      # effect on the merge path -- accepting them silently would hide a no-op
      # override, so we raise instead.
      expect do
        Class.new(HealthBase) do
          self.table_name = 'test_health_paper_trail_models'
          has_paper_trail versions: { class_name: 'PaperTrail::Version' }
        end
      end.to raise_error(ArgumentError, /versions/)
    end
  end
end

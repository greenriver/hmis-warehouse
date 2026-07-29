###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'YAML-serialized column safety' do
  # Gem::Requirement is a documented YAML deserialization gadget: unsafe_load instantiates
  # it (running Gem::Version's parsing as a side effect) instead of just parsing data.
  let(:malicious_yaml) { "--- !ruby/object:Gem::Requirement\nrequirements: []\n" }

  describe 'global Rails configuration' do
    it 'does not permit unsafe YAML loading' do
      expect(ActiveRecord.use_yaml_unsafe_load).to be_falsey
    end

    it 'permits exactly the audited set of classes' do
      expect(ActiveRecord.yaml_column_permitted_classes).to match_array(
        [Symbol, Date, Time, DateTime, ActiveSupport::TimeWithZone, ActiveSupport::TimeZone, ActiveModel::Type::Binary::Data, BigDecimal],
      )
    end
  end

  describe 'a serialize-declared column' do
    let(:import_log) { GrdaWarehouse::ImportLog.create!(data_source: create(:grda_warehouse_data_source)) }

    it 'raises instead of instantiating a disallowed class written directly to the column' do
      # GrdaWarehouse::ImportLog lives on the warehouse-db connection, not ActiveRecord::Base's
      # default (app-db) connection — use the model's own connection for the raw UPDATE.
      GrdaWarehouse::ImportLog.connection.execute(
        "UPDATE import_logs SET import_errors = #{GrdaWarehouse::ImportLog.connection.quote(malicious_yaml)} WHERE id = #{import_log.id}",
      )

      expect { import_log.reload.import_errors }.to raise_error(Psych::DisallowedClass)
    end

    it 'still round-trips a legitimate value' do
      import_log.update!(import_errors: [{ 'message' => 'boom' }])

      expect(import_log.reload.import_errors).to eq([{ 'message' => 'boom' }])
    end
  end

  describe 'a PaperTrail-tracked access-control model' do
    # PaperTrail is globally disabled in tests for performance (spec/rails_helper.rb).
    around(:example) { |ex| PaperTrailHelper.with_paper_trail { ex.run } }

    let(:user_group) { create(:user_group, name: 'original-name') }

    it 'raises instead of instantiating a disallowed class written directly into a version row' do
      user_group.update!(name: 'renamed')
      version = user_group.versions.last

      version.class.connection.execute(
        "UPDATE #{version.class.table_name} SET object_changes = #{version.class.connection.quote(malicious_yaml)} WHERE id = #{version.id}",
      )

      # object_changes is a plain, undecorated String attribute on PaperTrail::Version — it's
      # not serialize-declared, so the bare attribute reader never deserializes it.
      # PaperTrail.serializer.load is the actual layer config.active_record.yaml_column_permitted_classes
      # applies to (paper_trail-17.0.0/lib/paper_trail/serializers/yaml.rb). Deliberately not
      # testing this through #changeset: PaperTrail::VersionConcern#object_changes_deserialized
      # wraps that same call in its own `rescue StandardError`, and its `HashWithIndifferentAccess.new(...)`
      # step silently collapses this payload to {} whether or not the object underneath was
      # ever actually instantiated (confirmed live under both old and new config) — a `changeset`-based
      # assertion here would pass regardless of this fix, so it wouldn't prove anything.
      expect { PaperTrail.serializer.load(version.reload.object_changes) }.to raise_error(Psych::DisallowedClass)
    end

    it 'still reifies a legitimate change through the existing audit-history display path' do
      user_group.update!(name: 'renamed')
      version = user_group.versions.last

      expect(version.reload.changeset['name']).to eq(['original-name', 'renamed'])
    end
  end
end

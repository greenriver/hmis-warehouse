# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require 'rake'

describe 'paper_trail:deduplicate_versions' do
  let(:rake) { Rake::Application.new }
  let(:task_name) { 'paper_trail:deduplicate_versions' }
  let(:task_path) { 'lib/tasks/deduplicate_paper_trail_versions' }

  before do
    Rake.application = rake
    Rake::Task.define_task(:environment)
    Rake.load_rakefile(Rails.root.join("#{task_path}.rake"))
  end

  after do
    rake[task_name].reenable
  end

  context 'when there are duplicate versions' do
    let!(:referral) { create(:hmis_external_api_ac_hmis_referral, referral_notes: 'initial notes') }
    let(:item_type) { 'HmisExternalApis::AcHmis::Referral' }
    let(:object_changes) { { referral_notes: ['updated notes', 'final notes'] }.to_yaml }
    let(:version_scope) { GrdaWarehouse::Version.where(item_type: item_type, item_id: referral.id) }

    # Helper to create duplicate versions with the same timestamp
    def create_duplicate_versions(attributes = {})
      timestamp = Time.current
      base_attrs = { item_type: item_type, item_id: referral.id, event: 'update', object_changes: object_changes, created_at: timestamp }
      2.times { GrdaWarehouse::Version.create!(base_attrs.merge(attributes)) }
    end

    before do
      referral.update!(referral_notes: 'updated notes')
      version_scope.delete_all
      GrdaWarehouse::Version.create!(
        item_id: referral.id,
        item_type: item_type,
        event: 'update',
        object_changes: { referral_notes: ['initial notes', 'updated notes'] }.to_yaml,
      )
    end

    context 'with a dry run' do
      it 'identifies and reports duplicates without deleting them' do
        create_duplicate_versions

        expect { Rake::Task[task_name].invoke }.to output(/Total duplicate versions that would be removed: 1/).to_stdout
        expect(version_scope.count).to eq(3)
      end
    end

    context 'with a live run' do
      it 'deletes the duplicate versions' do
        create_duplicate_versions

        expect { Rake::Task[task_name].invoke('false') }.to output(/Total duplicate versions removed: 1/).to_stdout
        expect(version_scope.count).to eq(2)
      end

      it 'keeps the version with metadata' do
        timestamp = Time.current
        base_attrs = { item_type: item_type, item_id: referral.id, event: 'update', object_changes: object_changes, created_at: timestamp }
        version_without_metadata = GrdaWarehouse::Version.create!(base_attrs)
        version_with_metadata = GrdaWarehouse::Version.create!(base_attrs.merge(enrollment_id: 123))

        Rake::Task[task_name].invoke('false')

        remaining_ids = version_scope.pluck(:id)
        expect(remaining_ids).to include(version_with_metadata.id)
        expect(remaining_ids).not_to include(version_without_metadata.id)
      end
    end
  end

  context 'when there are no duplicate versions' do
    it 'reports that no duplicates were found' do
      expect { Rake::Task[task_name].invoke }.to output(/No duplicates found/).to_stdout
    end
  end

  context 'when there are similar but non-duplicate versions' do
    let!(:referral) { create(:hmis_external_api_ac_hmis_referral, referral_notes: 'initial notes') }
    let(:item_type) { 'HmisExternalApis::AcHmis::Referral' }
    let(:version_scope) { GrdaWarehouse::Version.where(item_type: item_type, item_id: referral.id) }

    before do
      version_scope.delete_all
      timestamp = Time.current

      # Create versions that are similar but differ in key grouping criteria
      GrdaWarehouse::Version.create!(
        item_type: item_type,
        item_id: referral.id,
        event: 'update',
        object_changes: { referral_notes: ['v1', 'v2'] }.to_yaml,
        created_at: timestamp,
      )
      # Different timestamp
      GrdaWarehouse::Version.create!(
        item_type: item_type,
        item_id: referral.id,
        event: 'update',
        object_changes: { referral_notes: ['v1', 'v2'] }.to_yaml,
        created_at: timestamp + 1.second,
      )
      # Different object_changes
      GrdaWarehouse::Version.create!(
        item_type: item_type,
        item_id: referral.id,
        event: 'update',
        object_changes: { referral_notes: ['v2', 'v3'] }.to_yaml,
        created_at: timestamp,
      )
      # Different event
      GrdaWarehouse::Version.create!(
        item_type: item_type,
        item_id: referral.id,
        event: 'create',
        object_changes: { referral_notes: ['v1', 'v2'] }.to_yaml,
        created_at: timestamp,
      )
      # Different whodunnit
      GrdaWarehouse::Version.create!(
        item_type: item_type,
        item_id: referral.id,
        event: 'update',
        object_changes: { referral_notes: ['v1', 'v2'] }.to_yaml,
        whodunnit: '123',
        created_at: timestamp,
      )
    end

    it 'does not delete any versions' do
      initial_count = version_scope.count

      Rake::Task[task_name].invoke('false')

      expect(version_scope.count).to eq(initial_count)
    end

    it 'reports no duplicates found' do
      expect { Rake::Task[task_name].invoke }.to output(/No duplicates found/).to_stdout
    end
  end
end

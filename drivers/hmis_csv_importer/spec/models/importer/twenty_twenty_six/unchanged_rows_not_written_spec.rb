###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Fixture layout (see deletion_spec.rb): 557331, 557890 and 559123 are in scope; 622377 is out of scope.
# The subset omits 559123. subset_new_export is the subset with a different ExportID.
RSpec.describe 'HUD CSV re-import writes only changed rows', type: :model do
  fixture_root = 'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six'
  full = "#{fixture_root}/enrollment_test_files"
  subset = "#{fixture_root}/enrollment_test_files_subset"
  subset_new_export = "#{fixture_root}/enrollment_test_files_subset_new_export"
  xmins = ->(scope) { scope.pluck(:id, Arel.sql('xmin::text')).to_h }
  enrollments = -> { GrdaWarehouse::Hud::Enrollment.with_deleted }
  warehouse_classes = HmisCsvImporter::Importer::Importer.soft_deletable_sources('2026')
  all_rows = ->(klass) { klass.paranoid? ? klass.with_deleted : klass.all }

  def run_import(path)
    import_hmis_csv_fixture(path, version: 'AutoMigrate', run_jobs: false, stop_version: '2026')
  end

  before(:all) do
    HmisCsvImporter::Utility.clear!
    GrdaWarehouse::Utility.clear!
    run_import(full)
    @data_source_id = GrdaWarehouse::Hud::Enrollment.first.data_source_id
    clients = -> { GrdaWarehouse::Hud::Client.with_deleted.where(data_source_id: @data_source_id) }
    @first_export_id = GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: '557331').ExportID
    run_import(subset) # soft-deletes 559123
    @deleted_at = GrdaWarehouse::Hud::Enrollment.only_deleted.find_by(EnrollmentID: '559123').DateDeleted
    @before = {
      enrollment: xmins.call(enrollments.call),
      client: xmins.call(clients.call),
    }
    rows_for = lambda do |klass|
      klass == GrdaWarehouse::Hud::Client ? all_rows.call(klass).where(data_source_id: @data_source_id) : all_rows.call(klass)
    end
    @before_by_class = warehouse_classes.index_with { |klass| xmins.call(rows_for.call(klass)) }
    travel 1.day
    @loader = run_import(subset_new_export)
    @after = {
      enrollment: xmins.call(enrollments.call),
      client: xmins.call(clients.call),
    }
    @after_by_class = warehouse_classes.index_with { |klass| xmins.call(rows_for.call(klass)) }
  end

  after(:all) do
    travel_back
    HmisCsvImporter::Utility.clear!
    GrdaWarehouse::Utility.clear!
  end

  it 'imports the new export' do
    expect(GrdaWarehouse::Hud::Export.where(ExportID: 'new-export-id').count).to eq(1)
  end

  it 'does not write in-scope enrollments that did not change' do
    in_scope = GrdaWarehouse::Hud::Enrollment.where(EnrollmentID: ['557331', '557890']).pluck(:id)
    expect(in_scope.size).to eq(2)
    expect(@after[:enrollment].slice(*in_scope)).to eq(@before[:enrollment].slice(*in_scope))
  end

  it 'does not write the enrollment that was already soft-deleted' do
    id = GrdaWarehouse::Hud::Enrollment.only_deleted.find_by(EnrollmentID: '559123').id
    expect(@after[:enrollment][id]).to eq(@before[:enrollment][id])
  end

  it 'keeps the original DateDeleted on the already-deleted enrollment' do
    expect(GrdaWarehouse::Hud::Enrollment.only_deleted.find_by(EnrollmentID: '559123').DateDeleted).to eq(@deleted_at)
  end

  it 'keeps the ExportID of the import that last changed an unchanged row' do
    expect(GrdaWarehouse::Hud::Enrollment.find_by(EnrollmentID: '557331').ExportID).to eq(@first_export_id)
  end

  it 'does not write clients that did not change' do
    expect(@before[:client]).not_to be_empty
    expect(@after[:client]).to eq(@before[:client])
  end

  # The fixture's children of these tables reference EnrollmentIDs that are not in Enrollment.csv, so
  # their rows are outside the involved scope. add_new_data treats them as new on every import and
  # upserts them again, the same as before the pending set. Tracked separately.
  rewritten_out_of_scope = ['CurrentLivingSituation', 'Assessment', 'AssessmentQuestions', 'AssessmentResults', 'Event']

  warehouse_classes.each do |klass|
    next if klass.table_name.in?(rewritten_out_of_scope)

    it "does not write existing #{klass.table_name} rows" do
      before = @before_by_class.fetch(klass)
      expect(@after_by_class.fetch(klass).slice(*before.keys)).to eq(before)
    end
  end

  it 'covers the tables the fixture populates' do
    populated = @before_by_class.reject { |_klass, rows| rows.empty? }.keys.map(&:table_name)
    expect(populated).to include('Enrollment', 'Client', 'Exit')
  end

  it 'still counts the unchanged enrollments' do
    summary = @loader.importer_log.summary['Enrollment.csv']
    expect(summary.slice('unchanged', 'removed')).to eq('unchanged' => 2, 'removed' => 0)
    expect(summary['updated'].to_i).to eq(0)
  end
end

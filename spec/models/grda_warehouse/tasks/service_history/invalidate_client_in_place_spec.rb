###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../../shared_contexts/hud_enrollment_builders'

RSpec.describe GrdaWarehouse::Tasks::ServiceHistory::InvalidateClientInPlace, type: :model do
  include_context 'HUD enrollment builders'

  let(:es_entry_exit) { HudHelper.util.project_type_number_from_code(:es_entry_exit).first }
  let!(:project) { create_project(project_type: es_entry_exit) }
  let!(:client) { create_client_with_warehouse_link }
  let(:destination_client) { client.destination_client }
  let!(:valid_enrollment) do
    create_enrollment(
      client: client,
      project: project,
      entry_date: 60.days.ago.to_date,
      exit_date: 30.days.ago.to_date,
    )
  end

  def rebuild_all_service_history
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
  end

  def service_history_for(enrollment, client_id: destination_client.id)
    GrdaWarehouse::ServiceHistoryEnrollment.where(
      client_id: client_id,
      data_source_id: enrollment.data_source_id,
      enrollment_group_id: enrollment.EnrollmentID,
      project_id: enrollment.ProjectID,
    )
  end

  def record_types_for(enrollment, client_id: destination_client.id)
    service_history_for(enrollment, client_id: client_id).order(:record_type).pluck(:record_type)
  end

  def service_days_for(enrollment)
    GrdaWarehouse::ServiceHistoryService.where(
      service_history_enrollment_id: service_history_for(enrollment).select(:id),
    )
  end

  def invalidate_in_place
    destination_client.invalidate_service_history
    described_class.new(destination_client.reload).run!
  end

  def rebuild_client
    GrdaWarehouse::Tasks::ServiceHistory::Add.new.run!
    work_off_all_ready_jobs
  end

  before do
    rebuild_all_service_history
  end

  context 'when every row belongs to a current enrollment' do
    it 'keeps the rows and clears processed_as on the source enrollments' do
      service_day_count = service_days_for(valid_enrollment).count
      expect(service_day_count).to be_positive

      invalidate_in_place

      expect(record_types_for(valid_enrollment)).to eq(['entry', 'exit'])
      expect(service_days_for(valid_enrollment).count).to eq(service_day_count)
      expect(valid_enrollment.reload.processed_as).to be_nil
    end
  end

  context 'when a source enrollment has been deleted' do
    let!(:removed_enrollment) do
      create_enrollment(client: client, project: project, entry_date: 20.days.ago.to_date)
    end

    before do
      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find(removed_enrollment.id).rebuild_service_history!
      removed_enrollment.destroy!
    end

    it "deletes the enrollment's rows and day rows and keeps the others" do
      expect(service_days_for(removed_enrollment)).to exist

      invalidate_in_place

      expect(service_history_for(removed_enrollment)).not_to exist
      expect(service_days_for(removed_enrollment)).not_to exist
      expect(record_types_for(valid_enrollment)).to eq(['entry', 'exit'])
    end

    it "doesn't touch another client's rows with the same enrollment key" do
      other_client_row = service_history_for(removed_enrollment).entry.first.dup
      other_client_row.update!(client_id: create_client_with_warehouse_link.destination_client.id)

      invalidate_in_place

      expect(GrdaWarehouse::ServiceHistoryEnrollment.where(id: other_client_row.id)).to exist
    end
  end

  context "when a source enrollment's project has been deleted" do
    let!(:other_project) { create_project(project_type: es_entry_exit) }
    let!(:orphaned_enrollment) do
      create_enrollment(client: client, project: other_project, entry_date: 20.days.ago.to_date)
    end

    before do
      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find(orphaned_enrollment.id).rebuild_service_history!
      other_project.destroy!
    end

    it "deletes the enrollment's rows" do
      expect(service_history_for(orphaned_enrollment)).to exist

      invalidate_in_place

      expect(service_history_for(orphaned_enrollment)).not_to exist
      expect(record_types_for(valid_enrollment)).to eq(['entry', 'exit'])
    end
  end

  context 'when a source client has moved to another destination (split, unmerge)' do
    let!(:moved_source_client) { create(:hud_client, data_source: data_source) }
    let!(:moved_warehouse_client) do
      create(:warehouse_client, destination_id: destination_client.id, source_id: moved_source_client.id)
    end
    let!(:moved_enrollment) do
      create_enrollment(
        client: moved_source_client,
        project: project,
        entry_date: 50.days.ago.to_date,
        exit_date: 40.days.ago.to_date,
      )
    end
    let(:new_destination_client) { create_client_with_warehouse_link.destination_client }

    before do
      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find(moved_enrollment.id).rebuild_service_history!
      GrdaWarehouse::WarehouseClientsProcessed.update_cached_counts(
        client_ids: GrdaWarehouse::Hud::Client.destination.pluck(:id),
      )
      moved_warehouse_client.update!(destination_id: new_destination_client.id)
    end

    it "deletes the moved enrollment's rows from the original destination and keeps the others" do
      expect(record_types_for(moved_enrollment)).to eq(['entry', 'exit'])

      invalidate_in_place

      expect(service_history_for(moved_enrollment)).not_to exist
      expect(record_types_for(valid_enrollment)).to eq(['entry', 'exit'])
    end

    it 'rebuilds the moved enrollment under the new destination once the queued rebuild has run' do
      destination_client.invalidate_service_history
      new_destination_client.invalidate_service_history
      rebuild_client

      expect(service_history_for(moved_enrollment)).not_to exist
      expect(record_types_for(moved_enrollment, client_id: new_destination_client.id)).to eq(['entry', 'exit'])
      expect(record_types_for(valid_enrollment)).to eq(['entry', 'exit'])
    end
  end

  context 'when the client has no service history' do
    before do
      GrdaWarehouse::ServiceHistoryEnrollment.where(client_id: destination_client.id).delete_all
    end

    it 'clears processed_as without error' do
      expect { invalidate_in_place }.not_to raise_error

      expect(valid_enrollment.reload.processed_as).to be_nil
    end
  end

  context 'when an enrollment has duplicate entry rows' do
    before do
      service_history_for(valid_enrollment).entry.first.dup.save!
    end

    it 'converges to one entry row once the queued rebuild has run' do
      expect(record_types_for(valid_enrollment)).to eq(['entry', 'entry', 'exit'])

      GrdaWarehouse::WarehouseClientsProcessed.update_cached_counts(client_ids: [destination_client.id])
      destination_client.invalidate_service_history
      rebuild_client

      expect(record_types_for(valid_enrollment)).to eq(['entry', 'exit'])
    end
  end

  context 'with a legacy service row on service_history_enrollments' do
    before do
      service_history_for(valid_enrollment).entry.first.dup.update!(record_type: 'service')
    end

    it 'deletes it, as the full rebuild did' do
      invalidate_in_place

      expect(record_types_for(valid_enrollment)).to eq(['entry', 'exit'])
    end
  end
end

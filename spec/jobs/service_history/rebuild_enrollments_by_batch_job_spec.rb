###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ServiceHistory::RebuildEnrollmentsByBatchJob, type: :job do
  let(:data_source) { create(:source_data_source) }
  let(:destination_data_source) { create(:destination_data_source) }
  let(:project) { create(:grda_warehouse_hud_project, data_source: data_source) }

  def create_linked_client
    source_client = create(:grda_warehouse_hud_client, data_source: data_source)
    destination_client = source_client.dup
    destination_client.data_source = destination_data_source
    destination_client.save!
    create(:warehouse_client, destination_id: destination_client.id, source_id: source_client.id)
    source_client
  end

  def create_processable_enrollment
    create(
      :hud_enrollment,
      data_source: data_source,
      project: project,
      client: create_linked_client,
      processed_as: nil,
      EntryDate: 5.days.ago.to_date,
    )
  end

  describe '#perform' do
    it "keeps processing the rest of the batch when one enrollment raises, and records only that one's error" do
      healthy_one = create_processable_enrollment
      poisoned = create_processable_enrollment
      healthy_two = create_processable_enrollment

      poisoned_record = GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find(poisoned.id)
      allow(GrdaWarehouse::Tasks::ServiceHistory::Enrollment).to receive(:find_by).and_call_original
      allow(GrdaWarehouse::Tasks::ServiceHistory::Enrollment).to receive(:find_by).
        with(id: poisoned.id).and_return(poisoned_record)
      allow(poisoned_record).to receive(:rebuild_service_history!).and_raise(RuntimeError, 'boom')

      described_class.new(enrollment_ids: [healthy_one.id, poisoned.id, healthy_two.id]).perform

      expect(GrdaWarehouse::Hud::Enrollment.find(healthy_one.id).processed_as).to be_present
      expect(GrdaWarehouse::Hud::Enrollment.find(healthy_two.id).processed_as).to be_present
      expect(GrdaWarehouse::Hud::Enrollment.find(poisoned.id).processing_error).to eq('RuntimeError: boom')
      expect(GrdaWarehouse::Hud::Enrollment.find(healthy_one.id).processing_error).to be_nil
    end

    it 'clears a previously recorded processing_error once the enrollment reprocesses successfully' do
      enrollment = create_processable_enrollment
      enrollment.update_column(:processing_error, 'RuntimeError: stale failure')

      described_class.new(enrollment_ids: [enrollment.id]).perform

      expect(GrdaWarehouse::Hud::Enrollment.find(enrollment.id).processing_error).to be_nil
      expect(GrdaWarehouse::Hud::Enrollment.find(enrollment.id).processed_as).to be_present
    end

    it 'skips an id that no longer exists without raising, and still processes the rest of the batch' do
      healthy = create_processable_enrollment
      missing_id = healthy.id + 1_000_000

      expect { described_class.new(enrollment_ids: [missing_id, healthy.id]).perform }.not_to raise_error
      expect(GrdaWarehouse::Hud::Enrollment.find(healthy.id).processed_as).to be_present
    end
  end
end

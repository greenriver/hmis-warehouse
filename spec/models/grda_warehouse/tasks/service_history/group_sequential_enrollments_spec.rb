###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe GrdaWarehouse::Tasks::ServiceHistory::GroupSequentialEnrollments, type: :model do
  let!(:data_source) { create(:source_data_source) }
  let!(:destination_data_source) { create(:destination_data_source) }
  let!(:client) { create(:hud_client, data_source: data_source) }
  let!(:destination_client) { create(:destination_client) }
  let!(:warehouse_client_source) do
    create(:warehouse_client_source, destination_id: destination_client.id, source_id: client.id, data_source_id: data_source.id)
  end

  let!(:project) do
    create(
      :hud_project,
      data_source: data_source,
      project_type: 1, # ES-NbN
    )
  end

  let(:grouping_class) { described_class }

  before do
    # Clear any existing service history enrollments
    GrdaWarehouse::ServiceHistoryEnrollment.delete_all
  end

  describe '.group_all_unprocessed!' do
    context 'with consecutive single-night enrollments' do
      let!(:enrollment_1) do
        create(
          :grda_warehouse_service_history_enrollment,
          client_id: destination_client.id,
          project_id: project.id,
          project_type: 1,
          data_source_id: data_source.id,
          first_date_in_program: Date.parse('2024-01-01'),
          last_date_in_program: Date.parse('2024-01-01'),
          relationship_to_hoh: 1,
          enrollment_leader_id: nil,
        )
      end

      let!(:enrollment_2) do
        create(
          :grda_warehouse_service_history_enrollment,
          client_id: destination_client.id,
          project_id: project.id,
          project_type: 1,
          data_source_id: data_source.id,
          first_date_in_program: Date.parse('2024-01-02'),
          last_date_in_program: Date.parse('2024-01-02'),
          relationship_to_hoh: 1,
          enrollment_leader_id: nil,
        )
      end

      let!(:enrollment_3) do
        create(
          :grda_warehouse_service_history_enrollment,
          client_id: destination_client.id,
          project_id: project.id,
          project_type: 1,
          data_source_id: data_source.id,
          first_date_in_program: Date.parse('2024-01-03'),
          last_date_in_program: Date.parse('2024-01-03'),
          relationship_to_hoh: 1,
          enrollment_leader_id: nil,
        )
      end

      it 'groups them together with the first enrollment as the group leader' do
        grouping_class.group_all_unprocessed!

        enrollment_1.reload
        enrollment_2.reload
        enrollment_3.reload

        expect(enrollment_1.enrollment_leader_id).to eq(enrollment_1.id)
        expect(enrollment_2.enrollment_leader_id).to eq(enrollment_1.id)
        expect(enrollment_3.enrollment_leader_id).to eq(enrollment_1.id)
      end

      it 'creates a group record with correct dates' do
        grouping_class.group_all_unprocessed!

        group = GrdaWarehouse::ServiceHistoryEnrollmentGroup.find_by(id: enrollment_1.id)
        expect(group).to be_present
        expect(group.logical_entry_date).to eq(Date.parse('2024-01-01'))
        expect(group.logical_exit_date).to eq(Date.parse('2024-01-03'))
        expect(group.enrollment_count).to eq(3)
      end
    end

    context 'with gap > 1 day' do
      let!(:enrollment_1) do
        create(
          :grda_warehouse_service_history_enrollment,
          client_id: destination_client.id,
          project_id: project.id,
          project_type: 1,
          data_source_id: data_source.id,
          first_date_in_program: Date.parse('2024-01-01'),
          last_date_in_program: Date.parse('2024-01-01'),
          relationship_to_hoh: 1,
          enrollment_leader_id: nil,
        )
      end

      let!(:enrollment_2) do
        create(
          :grda_warehouse_service_history_enrollment,
          client_id: destination_client.id,
          project_id: project.id,
          project_type: 1,
          data_source_id: data_source.id,
          first_date_in_program: Date.parse('2024-01-04'), # 3-day gap
          last_date_in_program: Date.parse('2024-01-04'),
          relationship_to_hoh: 1,
          enrollment_leader_id: nil,
        )
      end

      it 'does not group them' do
        grouping_class.group_all_unprocessed!

        enrollment_1.reload
        enrollment_2.reload

        expect(enrollment_1.enrollment_leader_id).to be_nil
        expect(enrollment_2.enrollment_leader_id).to be_nil
      end
    end

    context 'with exactly 1-day gap' do
      let!(:enrollment_1) do
        create(
          :grda_warehouse_service_history_enrollment,
          client_id: destination_client.id,
          project_id: project.id,
          project_type: 1,
          data_source_id: data_source.id,
          first_date_in_program: Date.parse('2024-01-01'),
          last_date_in_program: Date.parse('2024-01-01'),
          relationship_to_hoh: 1,
          enrollment_leader_id: nil,
        )
      end

      let!(:enrollment_2) do
        create(
          :grda_warehouse_service_history_enrollment,
          client_id: destination_client.id,
          project_id: project.id,
          project_type: 1,
          data_source_id: data_source.id,
          first_date_in_program: Date.parse('2024-01-03'), # 1-day gap
          last_date_in_program: Date.parse('2024-01-03'),
          relationship_to_hoh: 1,
          enrollment_leader_id: nil,
        )
      end

      it 'groups them' do
        grouping_class.group_all_unprocessed!

        enrollment_1.reload
        enrollment_2.reload

        expect(enrollment_1.enrollment_leader_id).to eq(enrollment_1.id)
        expect(enrollment_2.enrollment_leader_id).to eq(enrollment_1.id)
      end
    end

    context 'with different relationship_to_hoh' do
      let!(:enrollment_1) do
        create(
          :grda_warehouse_service_history_enrollment,
          client_id: destination_client.id,
          project_id: project.id,
          project_type: 1,
          data_source_id: data_source.id,
          first_date_in_program: Date.parse('2024-01-01'),
          last_date_in_program: Date.parse('2024-01-01'),
          relationship_to_hoh: 1,
          enrollment_leader_id: nil,
        )
      end

      let!(:enrollment_2) do
        create(
          :grda_warehouse_service_history_enrollment,
          client_id: destination_client.id,
          project_id: project.id,
          project_type: 1,
          data_source_id: data_source.id,
          first_date_in_program: Date.parse('2024-01-02'),
          last_date_in_program: Date.parse('2024-01-02'),
          relationship_to_hoh: 2, # Different relationship
          enrollment_leader_id: nil,
        )
      end

      it 'does not group them' do
        grouping_class.group_all_unprocessed!

        enrollment_1.reload
        enrollment_2.reload

        expect(enrollment_1.enrollment_leader_id).to be_nil
        expect(enrollment_2.enrollment_leader_id).to be_nil
      end
    end

    context 'with different projects' do
      let!(:project_2) do
        create(
          :hud_project,
          data_source: data_source,
          project_type: 1,
        )
      end

      let!(:enrollment_1) do
        create(
          :grda_warehouse_service_history_enrollment,
          client_id: destination_client.id,
          project_id: project.id,
          project_type: 1,
          data_source_id: data_source.id,
          first_date_in_program: Date.parse('2024-01-01'),
          last_date_in_program: Date.parse('2024-01-01'),
          relationship_to_hoh: 1,
          enrollment_leader_id: nil,
        )
      end

      let!(:enrollment_2) do
        create(
          :grda_warehouse_service_history_enrollment,
          client_id: destination_client.id,
          project_id: project_2.id,
          project_type: 1,
          data_source_id: data_source.id,
          first_date_in_program: Date.parse('2024-01-02'),
          last_date_in_program: Date.parse('2024-01-02'),
          relationship_to_hoh: 1,
          enrollment_leader_id: nil,
        )
      end

      it 'does not group them' do
        grouping_class.group_all_unprocessed!

        enrollment_1.reload
        enrollment_2.reload

        expect(enrollment_1.enrollment_leader_id).to be_nil
        expect(enrollment_2.enrollment_leader_id).to be_nil
      end
    end

    context 'with single isolated enrollment' do
      let!(:enrollment_1) do
        create(
          :grda_warehouse_service_history_enrollment,
          client_id: destination_client.id,
          project_id: project.id,
          project_type: 1,
          data_source_id: data_source.id,
          first_date_in_program: Date.parse('2024-01-01'),
          last_date_in_program: Date.parse('2024-01-01'),
          relationship_to_hoh: 1,
          enrollment_leader_id: nil,
        )
      end

      it 'does not assign a group id' do
        grouping_class.group_all_unprocessed!

        enrollment_1.reload
        expect(enrollment_1.enrollment_leader_id).to be_nil
      end
    end

    context 'with NULL exit date (open enrollment)' do
      let!(:enrollment_1) do
        create(
          :grda_warehouse_service_history_enrollment,
          client_id: destination_client.id,
          project_id: project.id,
          project_type: 1,
          data_source_id: data_source.id,
          first_date_in_program: Date.parse('2024-01-01'),
          last_date_in_program: Date.parse('2024-01-01'),
          relationship_to_hoh: 1,
          enrollment_leader_id: nil,
        )
      end

      let!(:enrollment_2) do
        create(
          :grda_warehouse_service_history_enrollment,
          client_id: destination_client.id,
          project_id: project.id,
          project_type: 1,
          data_source_id: data_source.id,
          first_date_in_program: Date.parse('2024-01-02'),
          last_date_in_program: nil, # Open enrollment
          relationship_to_hoh: 1,
          enrollment_leader_id: nil,
        )
      end

      it 'does not group open enrollments' do
        grouping_class.group_all_unprocessed!

        enrollment_1.reload
        enrollment_2.reload

        expect(enrollment_1.enrollment_leader_id).to be_nil
        expect(enrollment_2.enrollment_leader_id).to be_nil
      end
    end

    context 'with varying household_id (should still group)' do
      let!(:enrollment_1) do
        create(
          :grda_warehouse_service_history_enrollment,
          client_id: destination_client.id,
          project_id: project.id,
          project_type: 1,
          data_source_id: data_source.id,
          household_id: 'HH1',
          first_date_in_program: Date.parse('2024-01-01'),
          last_date_in_program: Date.parse('2024-01-01'),
          relationship_to_hoh: 1,
          enrollment_leader_id: nil,
        )
      end

      let!(:enrollment_2) do
        create(
          :grda_warehouse_service_history_enrollment,
          client_id: destination_client.id,
          project_id: project.id,
          project_type: 1,
          data_source_id: data_source.id,
          household_id: 'HH2', # Different household_id
          first_date_in_program: Date.parse('2024-01-02'),
          last_date_in_program: Date.parse('2024-01-02'),
          relationship_to_hoh: 1,
          enrollment_leader_id: nil,
        )
      end

      it 'groups them despite different household_id' do
        grouping_class.group_all_unprocessed!

        enrollment_1.reload
        enrollment_2.reload

        expect(enrollment_1.enrollment_leader_id).to eq(enrollment_1.id)
        expect(enrollment_2.enrollment_leader_id).to eq(enrollment_1.id)
      end
    end

    context 'with complex sequence including boundary changes' do
      let!(:enrollment_1) do
        create(
          :grda_warehouse_service_history_enrollment,
          client_id: destination_client.id,
          project_id: project.id,
          project_type: 1,
          data_source_id: data_source.id,
          first_date_in_program: Date.parse('2024-01-01'),
          last_date_in_program: Date.parse('2024-01-02'),
          relationship_to_hoh: 1,
          enrollment_leader_id: nil,
        )
      end

      let!(:enrollment_2) do
        create(
          :grda_warehouse_service_history_enrollment,
          client_id: destination_client.id,
          project_id: project.id,
          project_type: 1,
          data_source_id: data_source.id,
          first_date_in_program: Date.parse('2024-01-03'),
          last_date_in_program: Date.parse('2024-01-03'),
          relationship_to_hoh: 1,
          enrollment_leader_id: nil,
        )
      end

      let!(:enrollment_3) do
        create(
          :grda_warehouse_service_history_enrollment,
          client_id: destination_client.id,
          project_id: project.id,
          project_type: 1,
          data_source_id: data_source.id,
          first_date_in_program: Date.parse('2024-01-04'),
          last_date_in_program: Date.parse('2024-01-04'),
          relationship_to_hoh: 2, # Boundary: different relationship
          enrollment_leader_id: nil,
        )
      end

      let!(:enrollment_4) do
        create(
          :grda_warehouse_service_history_enrollment,
          client_id: destination_client.id,
          project_id: project.id,
          project_type: 1,
          data_source_id: data_source.id,
          first_date_in_program: Date.parse('2024-01-05'),
          last_date_in_program: Date.parse('2024-01-05'),
          relationship_to_hoh: 2,
          enrollment_leader_id: nil,
        )
      end

      it 'creates two separate groups' do
        grouping_class.group_all_unprocessed!

        enrollment_1.reload
        enrollment_2.reload
        enrollment_3.reload
        enrollment_4.reload

        expect(enrollment_1.enrollment_leader_id).to eq(enrollment_1.id)
        expect(enrollment_2.enrollment_leader_id).to eq(enrollment_1.id)
        expect(enrollment_3.enrollment_leader_id).to eq(enrollment_3.id)
        expect(enrollment_4.enrollment_leader_id).to eq(enrollment_3.id)
      end
    end
  end

  describe '.regroup_for_client_ids' do
    let!(:enrollment_1) do
      create(
        :grda_warehouse_service_history_enrollment,
        client_id: destination_client.id,
        project_id: project.id,
        project_type: 1,
        data_source_id: data_source.id,
        first_date_in_program: Date.parse('2024-01-01'),
        last_date_in_program: Date.parse('2024-01-01'),
        relationship_to_hoh: 1,
        enrollment_leader_id: 999,
      )
    end

    it 'clears existing groups and reprocesses' do
      expect(enrollment_1.enrollment_leader_id).to eq(999)

      grouping_class.regroup_for_client_ids([destination_client.id])

      enrollment_1.reload
      expect(enrollment_1.enrollment_leader_id).to be_nil
    end
  end

  describe '.regroup_for_project_ids' do
    let!(:enrollment_1) do
      create(
        :grda_warehouse_service_history_enrollment,
        client_id: destination_client.id,
        project_id: project.id,
        project_type: 1,
        data_source_id: data_source.id,
        first_date_in_program: Date.parse('2024-01-01'),
        last_date_in_program: Date.parse('2024-01-01'),
        relationship_to_hoh: 1,
        enrollment_leader_id: 999,
      )
    end

    it 'clears groups for affected projects and reprocesses' do
      expect(enrollment_1.enrollment_leader_id).to eq(999)

      grouping_class.regroup_for_project_ids([project.id])

      enrollment_1.reload
      expect(enrollment_1.enrollment_leader_id).to be_nil
    end
  end

  describe 'ServiceHistoryEnrollmentWithLogicalDates view' do
    let!(:enrollment_1) do
      create(
        :grda_warehouse_service_history_enrollment,
        client_id: destination_client.id,
        project_id: project.id,
        project_type: 1,
        data_source_id: data_source.id,
        first_date_in_program: Date.parse('2024-01-01'),
        last_date_in_program: Date.parse('2024-01-01'),
        relationship_to_hoh: 1,
        enrollment_leader_id: nil,
      )
    end

    let!(:enrollment_2) do
      create(
        :grda_warehouse_service_history_enrollment,
        client_id: destination_client.id,
        project_id: project.id,
        project_type: 1,
        data_source_id: data_source.id,
        first_date_in_program: Date.parse('2024-01-02'),
        last_date_in_program: Date.parse('2024-01-02'),
        relationship_to_hoh: 1,
        enrollment_leader_id: nil,
      )
    end

    before do
      grouping_class.group_all_unprocessed!
    end

    it 'provides logical dates for grouped enrollments' do
      view_enrollment = GrdaWarehouse::ServiceHistoryEnrollmentWithLogicalDates.find(enrollment_1.id)

      expect(view_enrollment.logical_entry_date).to eq(Date.parse('2024-01-01'))
      expect(view_enrollment.logical_exit_date).to eq(Date.parse('2024-01-02'))
      expect(view_enrollment.is_grouped).to be true
    end

    it 'provides original dates for ungrouped enrollments' do
      ungrouped = create(
        :grda_warehouse_service_history_enrollment,
        client_id: destination_client.id,
        project_id: project.id,
        project_type: 1,
        data_source_id: data_source.id,
        first_date_in_program: Date.parse('2024-02-01'),
        last_date_in_program: Date.parse('2024-02-01'),
        relationship_to_hoh: 1,
        enrollment_leader_id: nil,
      )

      view_enrollment = GrdaWarehouse::ServiceHistoryEnrollmentWithLogicalDates.find(ungrouped.id)

      expect(view_enrollment.logical_entry_date).to eq(Date.parse('2024-02-01'))
      expect(view_enrollment.logical_exit_date).to eq(Date.parse('2024-02-01'))
      expect(view_enrollment.is_grouped).to be false
    end
  end
end

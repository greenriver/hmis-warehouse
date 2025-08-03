# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::Expression::ClientFieldMap, type: :model do
  let!(:destination_data_source) { create :destination_data_source }
  let(:current_date) { Date.new(2024, 12, 26) }
  let(:field_map) { described_class.new(current_date: current_date) }

  let!(:client1) do
    create(:hmis_hud_client_with_warehouse_client, dob: 30.years.ago(current_date), veteran_status: 1)
  end
  let!(:destination_client1) { destination_client_for(client1) }

  let!(:client2) do
    create(:hmis_hud_client_with_warehouse_client, dob: 40.years.ago(current_date), veteran_status: 0)
  end
  let!(:destination_client2) { destination_client_for(client2) }

  let(:all_destination_clients) { GrdaWarehouse::Hud::Client.where(id: [destination_client1.id, destination_client2.id]) }

  # Helper method to get destination client from HMIS client
  def destination_client_for(hmis_client)
    GrdaWarehouse::Hud::Client.find(hmis_client.destination_client.id)
  end

  describe '#client_query' do
    context 'error handling' do
      it 'raises ArgumentError for unsupported field' do
        expect { field_map.client_query(all_destination_clients, 'unsupported_field') }.
          to raise_error(ArgumentError, 'Field "unsupported_field" is not supported')
      end
    end

    context 'edge cases' do
      context 'with client missing DOB' do
        let!(:client_no_dob) do
          create(:hmis_hud_client_with_warehouse_client, dob: nil, veteran_status: 1)
        end
        let!(:destination_client_no_dob) { destination_client_for(client_no_dob) }

        it 'handles missing DOB gracefully for current_age' do
          result = field_map.client_query(
            GrdaWarehouse::Hud::Client.where(id: destination_client_no_dob.id),
            'current_age',
          )
          expect(result[destination_client_no_dob.id]).to be_nil
        end
      end

      context 'with client having no enrollments' do
        let!(:client_no_enrollments) do
          create(:hmis_hud_client_with_warehouse_client, veteran_status: 1)
        end
        let!(:destination_client_no_enrollments) { destination_client_for(client_no_enrollments) }

        it 'returns nil for days_since_last_exit when no enrollments exist' do
          result = field_map.client_query(
            GrdaWarehouse::Hud::Client.where(id: destination_client_no_enrollments.id),
            'days_since_last_exit',
          )
          expect(result[destination_client_no_enrollments.id]).to be_nil
        end

        it 'returns empty array for project types when no enrollments exist' do
          result = field_map.client_query(
            GrdaWarehouse::Hud::Client.where(id: destination_client_no_enrollments.id),
            'open_enrollment_project_types',
          )
          expect(result[destination_client_no_enrollments.id]).to eq([])
        end
      end
    end

    context 'for veteran_status' do
      it 'returns the veteran status for each client' do
        result = field_map.client_query(all_destination_clients, 'veteran_status')
        expect(result).to eq(
          destination_client1.id => 1,
          destination_client2.id => 0,
        )
      end
    end

    context 'for current_age' do
      it 'returns the correct age for each client' do
        result = field_map.client_query(all_destination_clients, 'current_age')
        expect(result).to eq(
          destination_client1.id => 30,
          destination_client2.id => 40,
        )
      end
    end

    context 'for days_since_last_exit' do
      before do
        # Create an enrollment with exit for client1 (exited 10 days ago)
        ds1 = client1.data_source
        project1 = create(:hmis_hud_project, data_source: ds1)
        exit_date = current_date - 10.days
        enrollment1 = create(:hmis_hud_enrollment, client: client1, data_source: ds1, project: project1, entry_date: exit_date - 7.days)
        create(:hmis_base_hud_exit, enrollment: enrollment1, exit_date: exit_date, data_source: ds1)

        # Create an open enrollment for client2 (still enrolled, no exit)
        ds2 = client2.data_source
        project2 = create(:hmis_hud_project, data_source: ds2)
        create(:hmis_hud_enrollment, client: client2, data_source: ds2, project: project2, entry_date: current_date - 2.months)
      end

      it 'returns the days since the last exit' do
        result = field_map.client_query(all_destination_clients, 'days_since_last_exit')
        expect(result).to eq(
          destination_client1.id => 10,
          destination_client2.id => 0, # Still enrolled
        )
      end

      context 'with WIP enrollment' do
        let(:enrollment1) { client1.enrollments.first }
        before do
          # Convert enrollment1 to a WIP enrollment by setting project_id to nil
          enrollment1.update!(project_id: nil)
        end

        it 'still calculates days since last exit for WIP enrollments' do
          expect(enrollment1).to be_in_progress
          result = field_map.client_query(all_destination_clients, 'days_since_last_exit')
          expect(result).to eq(
            destination_client1.id => 10,
            destination_client2.id => 0, # Still enrolled
          )
        end
      end
    end

    context 'for open enrollment project types' do
      before do
        # Client 1: Open (wip) enrollment in PSH (3) and Street Outreach (4)
        ds1 = client1.data_source
        project1a = create(:hmis_hud_project, project_type: 3, data_source: ds1) # PSH
        create(:hmis_hud_wip_enrollment, client: client1, data_source: ds1, project: project1a)
        project1b = create(:hmis_hud_project, project_type: 4, data_source: ds1) # Street Outreach
        create(:hmis_hud_wip_enrollment, client: client1, data_source: ds1, project: project1b)

        # Client 2: Open (not wip) enrollment in TH (2)
        ds2 = client2.data_source
        project2 = create(:hmis_hud_project, project_type: 2, data_source: ds2) # TH
        create(:hmis_hud_enrollment, client: client2, data_source: ds2, project: project2, exit_date: nil)
      end

      it 'for open_enrollment_project_types returns project types for all open enrollments (including wip)' do
        result = field_map.client_query(all_destination_clients, 'open_enrollment_project_types')
        expect(result[destination_client1.id]).to contain_exactly(3, 4)
        expect(result[destination_client2.id]).to contain_exactly(2)
      end

      it 'for open_enrollment_project_types_excluding_incomplete returns project types for open enrollments (excluding wip)' do
        result = field_map.client_query(all_destination_clients, 'open_enrollment_project_types_excluding_incomplete')
        expect(result[destination_client1.id]).to be_empty
        expect(result[destination_client2.id]).to contain_exactly(2)
      end
    end

    context 'for open_referral_project_types' do
      before do
        ds1 = client1.data_source
        project1 = create(:hmis_hud_project, project_type: 3, data_source: ds1) # PSH
        create(:hmis_ce_referral, client: client1, data_source: client1.data_source, target_project: project1, status: 'active')

        ds2 = client2.data_source
        project2 = create(:hmis_hud_project, project_type: 2, data_source: ds2) # TH
        create(:hmis_ce_referral, client: client2, data_source: client2.data_source, target_project: project2, status: 'rejected') # not active
      end

      it 'returns project types for active referrals' do
        result = field_map.client_query(all_destination_clients, 'open_referral_project_types')
        expect(result[destination_client1.id]).to contain_exactly(3)
        expect(result[destination_client2.id]).to be_empty
      end
    end
  end

  describe '#format_for_display' do
    it 'formats veteran status using HUD utility' do
      formatted = field_map.format_for_display('veteran_status', 1)
      expect(formatted).to eq(HudUtility2026.veteran_status(1))
    end

    it 'formats project types using HUD utility' do
      formatted = field_map.format_for_display('open_enrollment_project_types', [2, 3])
      expected = [HudUtility2026.project_type(2), HudUtility2026.project_type(3)]
      expect(formatted).to eq(expected)
    end
  end
end

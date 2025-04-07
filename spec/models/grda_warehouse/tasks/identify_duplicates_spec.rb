###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Tasks::IdentifyDuplicates, type: :model do
  let(:source_data_source) { create :source_data_source }
  let(:destination_data_source) { create :grda_warehouse_data_source }

  let!(:client_in_source) { create :grda_warehouse_hud_client, data_source: source_data_source }
  let!(:client_in_destination) { create :grda_warehouse_hud_client, data_source: destination_data_source }
  let(:destination_scope) { GrdaWarehouse::Hud::Client.destination }
  let(:user) { create :user }

  # Clients need enrollments or ClientCleanup will delete them
  let!(:organization) { create(:hud_organization, data_source: source_data_source) }
  let!(:project) { create(:hud_project, project_type: 13, organization: organization, data_source: source_data_source) }
  let!(:enrollment) { create(:hud_enrollment, client: client_in_source, project: project, data_source: source_data_source, entry_date: 1.weeks.ago) }

  describe 'When matching is enabled' do
    before(:all) { GrdaWarehouse::Utility.clear! }
    after(:each) { @config.invalidate_cache }

    before(:each) do
      # Enable de-duplication (the default)
      @config = GrdaWarehouse::Config.first_or_create
      @config.update(enable_auto_deduplication: true)
    end

    it 'recognizes an obvious match' do
      expect(check_for_obvious_match(client_in_source)).to be client_in_destination.id
    end

    describe 'obvious match processing with a split' do
      let!(:split) { create :grda_warehouse_client_split_history, split_from: client_in_source.id, split_into: client_in_destination.id }

      it 'does not return an obvious match if it was split' do
        expect(check_for_obvious_match(client_in_source)).to be_nil
      end
    end

    describe 'find merge candidates' do
      let!(:client_two_in_source) { create :grda_warehouse_hud_client, data_source: source_data_source }
      let!(:warehouse_data_source) { create :destination_data_source }

      before(:each) do
        processor = GrdaWarehouse::Tasks::IdentifyDuplicates.new(run_post_processing: false)
        processor.run!
        processor.match_existing!
      end

      it 'merged client and client 2 into a single destination client' do
        expect(client_in_source.destination_client.id).to eq(client_two_in_source.destination_client.id)
        expect(GrdaWarehouse::Hud::Client.destination.count).to eq(1)
      end

      describe 'merge processing after a split' do
        it 'sees two destination clients after split' do
          expect { split_client }.to change(destination_scope, :count).from(1).to(2)
        end

        it 'does not re-merge the split clients' do
          expect do
            split_client
            GrdaWarehouse::Tasks::IdentifyDuplicates.new(run_post_processing: false).match_existing!
          end.to change(destination_scope, :count).from(1).to(2)
        end
      end
    end

    describe 'restores previously deleted destination client if the source client returns' do
      let!(:deleted_in_source) { create :grda_warehouse_hud_client, data_source: source_data_source, DateDeleted: Time.current }
      let!(:deleted_in_destination) { create :grda_warehouse_hud_client, data_source: destination_data_source, DateDeleted: Time.current }
      let!(:warehouse_client_for_deleted_pair) { create :warehouse_client, source_id: deleted_in_source.id, destination_id: deleted_in_destination.id }

      let!(:first_warehouse_client) { create :warehouse_client, source_id: client_in_source.id, destination_id: client_in_destination.id }

      let!(:second_deleted_in_source) { create :grda_warehouse_hud_client, data_source: source_data_source, DateDeleted: Time.current }
      let!(:second_deleted_in_destination) { create :grda_warehouse_hud_client, data_source: destination_data_source, DateDeleted: Time.current }
      let!(:warehouse_client_for_second_deleted_pair) { create :warehouse_client, source_id: second_deleted_in_source.id, destination_id: second_deleted_in_destination.id }

      it 'only has one Destination and source client' do
        expect(GrdaWarehouse::Hud::Client.source.count).to eq(1)
        expect(GrdaWarehouse::Hud::Client.destination.count).to eq(1)
      end
      describe 'after running restore_previously_deleted_destinations' do
        before do
          GrdaWarehouse::Tasks::IdentifyDuplicates.new.send(:restore_previously_deleted_destinations)
        end
        it 'only has one Destination and source client' do
          expect(GrdaWarehouse::Hud::Client.source.count).to eq(1)
          expect(GrdaWarehouse::Hud::Client.destination.count).to eq(1)
        end
      end
      describe 'after restoring the source client and then running restore_previously_deleted_destinations' do
        before do
          deleted_in_source.update(DateDeleted: nil)
          GrdaWarehouse::Tasks::IdentifyDuplicates.new.send(:restore_previously_deleted_destinations)
        end
        it 'only has one Destination and source client' do
          expect(GrdaWarehouse::Hud::Client.source.count).to eq(2)
          expect(GrdaWarehouse::Hud::Client.destination.count).to eq(2)
        end
        it 'does not restore still deleted pair' do
          expect(GrdaWarehouse::Hud::Client.source.only_deleted.count).to eq(1)
          expect(GrdaWarehouse::Hud::Client.source.only_deleted.pluck(:id)).to eq([second_deleted_in_source.id])
          expect(GrdaWarehouse::Hud::Client.destination.only_deleted.count).to eq(1)
          expect(GrdaWarehouse::Hud::Client.destination.only_deleted.pluck(:id)).to eq([second_deleted_in_destination.id])
        end
      end
    end

    # Exercise matching against an existing destination client
    describe 'running identify_duplicates' do
      before do
        GrdaWarehouse::Tasks::IdentifyDuplicates.new.identify_duplicates
      end
      it 'runs without error and generates one warehouse client record' do
        expect(GrdaWarehouse::WarehouseClient.count).to eq(1)
      end
      describe 'second run' do
        let!(:new_source_client) { create :grda_warehouse_hud_client, data_source: source_data_source, SSN: '123445678' }
        before do
          GrdaWarehouse::Tasks::IdentifyDuplicates.new.identify_duplicates
        end
        it 'runs without error a second time and connects the new client to the existing destination client' do
          expect(GrdaWarehouse::WarehouseClient.count).to eq(2)
          expect(GrdaWarehouse::Hud::Client.destination.count).to eq(1)
          ids_from_warehouse_clients = GrdaWarehouse::WarehouseClient.pluck(:source_id, :destination_id).sort
          ids_from_clients = [
            [client_in_source.id, client_in_destination.id],
            [new_source_client.id, client_in_destination.id],
          ].sort
          expect(ids_from_warehouse_clients).to eq(ids_from_clients)
        end
      end
    end

    describe 'When the client has non-ascii characters in their name' do
      before do
        client_in_destination.update(first_name: 'José')
        client_in_source.update(first_name: 'José')
        GrdaWarehouse::Tasks::IdentifyDuplicates.new.identify_duplicates
      end
      it 'runs without error and generates one warehouse client record' do
        expect(GrdaWarehouse::WarehouseClient.count).to eq(1)
      end
      describe 'second run' do
        let!(:new_source_client) { create :grda_warehouse_hud_client, data_source: source_data_source, first_name: 'Jose' }
        before do
          # identify duplicates is not setup to "transliterate" so does not see Jose and José as the same
          GrdaWarehouse::Tasks::IdentifyDuplicates.new.identify_duplicates
        end
        it 'does not connect the new client to the existing destination client' do
          aggregate_failures do
            expect(GrdaWarehouse::WarehouseClient.count).to eq(2)
            expect(GrdaWarehouse::Hud::Client.destination.count).to eq(2)
            expect(client_in_destination.source_client_ids).to_not include(new_source_client.id)
          end
        end
      end
    end

    describe 'source client threshold' do
      before(:each) do
        # We want to know the PPI data for this client, so set it specifically
        client_in_source.update(first_name: 'A', last_name: 'Client', dob: '2000-01-01', ssn: 'XXXXX1234')
        # Clear out the existing destination client, this will be generated for `client_in_source` later in the test
        client_in_destination.destroy
      end
      it 'never creates more than the maximum number of source clients' do
        number_sample_clients = 125

        # Generating n unique clients that won't match the existing client or each other.
        # We are generating `number_sample_clients` - 1 because we are using the existing client (`client_in_source`)
        # as a baseline. This will bring our total number of clients to `number_sample_clients`.
        (1..(number_sample_clients - 1)).each do |n|
          client = create :grda_warehouse_hud_client, data_source: source_data_source
          date = Date.new(2000, 1, 1) + n.days - n.months
          str_n = n.to_s.rjust(4, '0')
          ssn = "#{str_n.last(3)}#{str_n.last(2)}#{str_n.last(4)}"
          client.update(first_name: "client_#{n}", last_name: 'Test', dob: date, ssn: ssn)
        end

        GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
        GrdaWarehouse::Tasks::IdentifyDuplicates.new.match_existing!

        # Test that each unique client received a destination client
        expect(GrdaWarehouse::Hud::Client.destination.count).to eq(number_sample_clients)
        expect(GrdaWarehouse::WarehouseClient.count).to eq(number_sample_clients)

        # Update the n unique clients so that they all match the baseline client.
        (1..(number_sample_clients - 1)).each do |n|
          str_n = n.to_s.rjust(4, '0')
          ssn = "#{str_n.last(3)}#{str_n.last(2)}#{str_n.last(4)}"
          client = GrdaWarehouse::Hud::Client.source.find_by(SSN: ssn)
          client.update(first_name: 'A', last_name: 'Client', dob: '2000-01-01', ssn: 'XXXXX1234')
        end

        GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
        GrdaWarehouse::Tasks::IdentifyDuplicates.new.match_existing!

        # # The code below will calculate the number of expected destination clients in the case that MAX_SOURCE_CLIENTS changes enough to affect this number
        # expected_number_destination_clients = ((number_sample_clients * 1.0) / GrdaWarehouse::Tasks::IdentifyDuplicates::MAX_SOURCE_CLIENTS).ceil

        # With MAX_SOURCE_CLIENTS set to 50, we are expecting 3 destination clients. 2 with 50 source clients and 1 with 25 source clients.
        # We are setting this specifically instead of using the calculated number in case `MAX_SOURCE_CLIENTS` gets set to a number larger than
        # `number_sample_clients`. If that happened, we wouldn't be reaching the threshold for the number of source clients that we are testing.
        expected_number_destination_clients = 3

        destination_clients = GrdaWarehouse::Hud::Client.destination.to_a

        expect(destination_clients.count).to eq(expected_number_destination_clients)
        expect(GrdaWarehouse::WarehouseClient.count).to eq(number_sample_clients)

        # Pop the last client off of the array. This client will have less than the maximum number of source clients.
        last_client = destination_clients.pop
        destination_clients.each do |client|
          expect(client.source_clients.count).to eq(GrdaWarehouse::Tasks::IdentifyDuplicates::MAX_SOURCE_CLIENTS)
        end
        expect(last_client.source_clients.count).to eq(number_sample_clients % GrdaWarehouse::Tasks::IdentifyDuplicates::MAX_SOURCE_CLIENTS)
      end
    end
  end

  describe 'When matching is disabled' do
    before(:all) do
      GrdaWarehouse::Utility.clear!
      # Enable de-duplication (the default)
      @config = GrdaWarehouse::Config.first_or_create
      @config.invalidate_cache
      @config.update(enable_auto_deduplication: false)
    end

    it 'does not recognize an obvious match' do
      expect(check_for_obvious_match(client_in_source)).to be_nil
    end

    describe 'obvious match processing with a split' do
      let!(:split) { create :grda_warehouse_client_split_history, split_from: client_in_source.id, split_into: client_in_destination.id }

      it 'does not return an obvious match if it was split' do
        expect(check_for_obvious_match(client_in_source)).to be_nil
      end
    end

    describe 'find merge candidates' do
      let!(:client_two_in_source) { create :grda_warehouse_hud_client, data_source: source_data_source }
      let!(:warehouse_data_source) { create :destination_data_source }

      before(:each) do
        processor = GrdaWarehouse::Tasks::IdentifyDuplicates.new(run_post_processing: false)
        processor.run!
        processor.match_existing!
      end

      it 'does not merge client and client 2 into a single destination client' do
        expect(client_in_source.destination_client.id).to_not eq(client_two_in_source.destination_client.id)
        expect(GrdaWarehouse::Hud::Client.destination.count).to eq(3)
      end

      describe 'merge processing after a split' do
        it 'sees four destination clients after split' do
          expect { split_client }.to change(destination_scope, :count).from(3).to(4)
        end

        it 'does not re-merge the split clients' do
          GrdaWarehouse::Tasks::IdentifyDuplicates.new(run_post_processing: false).match_existing!

          expect { split_client }.to change(destination_scope, :count).from(3).to(4)
        end
      end
    end
  end

  # Check for obvious match is private...
  def check_for_obvious_match(client_id)
    inst = GrdaWarehouse::Tasks::IdentifyDuplicates.new
    inst.send(:build_destination_lookups)
    inst.send(:check_for_obvious_match, client_id)
  end

  def split_client
    destination_client = client_in_source.destination_client
    split_client_id = destination_client.source_clients.last.id
    destination_client.split(
      [split_client_id],
      destination_client.id,
      destination_client.id,
      user,
    )
  end
end

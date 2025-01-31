require 'rails_helper'

RSpec.describe GrdaWarehouse::Tasks::IdentifyDuplicates, type: :model do
  let(:source_data_source) { create :source_data_source }
  let(:destination_data_source) { create :grda_warehouse_data_source }

  let!(:client_in_source) { create :grda_warehouse_hud_client, data_source: source_data_source }
  let!(:client_in_destination) { create :grda_warehouse_hud_client, data_source: destination_data_source }
  let(:destination_scope) { GrdaWarehouse::Hud::Client.destination }
  let(:user) { create :user }

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

    describe 'source client threshold' do
      before(:each) do
        client_in_destination.destroy
        client_in_source.update(first_name: 'A', last_name: 'Client', dob: '2000-01-01', ssn: 'XXX-XX-1234')
        GrdaWarehouse::Tasks::IdentifyDuplicates.new.identify_duplicates
      end
      it 'never creates more than the maximum number of source clients' do
        expect(GrdaWarehouse::Hud::Client.destination.count).to eq(1)
        expect(GrdaWarehouse::WarehouseClient.count).to eq(1)

        number_sample_clients = 125

        (1..(number_sample_clients - 1)).each do |n|
          client = create :grda_warehouse_hud_client, data_source: source_data_source
          date = Date.new(2000, 1, 1) + n.days - n.months
          str_n = n.to_s.rjust(4, '0')
          ssn = "#{str_n.last(3)}-#{str_n.last(2)}-#{str_n.last(4)}"
          client.update(first_name: "client_#{n}", last_name: 'Test', dob: date, ssn: ssn)
        end

        GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
        GrdaWarehouse::Tasks::IdentifyDuplicates.new.match_existing!

        expect(GrdaWarehouse::Hud::Client.destination.count).to eq(number_sample_clients)
        expect(GrdaWarehouse::WarehouseClient.count).to eq(number_sample_clients)

        (1..(number_sample_clients - 1)).each do |n|
          str_n = n.to_s.rjust(4, '0')
          ssn = "#{str_n.last(3)}-#{str_n.last(2)}-#{str_n.last(4)}"
          client = GrdaWarehouse::Hud::Client.source.find_by(SSN: ssn)
          client.update(first_name: 'A', last_name: 'Client', dob: '2000-01-01', ssn: 'XXX-XX-1234')
        end

        GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
        GrdaWarehouse::Tasks::IdentifyDuplicates.new.match_existing!

        expected_number_destination_clients = ((number_sample_clients * 1.0) / GrdaWarehouse::Tasks::IdentifyDuplicates::MAX_SOURCE_CLIENTS).ceil
        destination_clients = [].tap do |clients|
          clients << GrdaWarehouse::Hud::Client.destination
        end.flatten

        expect(destination_clients.count).to eq(expected_number_destination_clients)
        expect(GrdaWarehouse::WarehouseClient.count).to eq(number_sample_clients)

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

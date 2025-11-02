# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Tasks::IdentifyDuplicatesQueryMatcher, type: :model do
  let!(:warehouse_data_source) { create(:grda_warehouse_data_source) }
  let(:warehouse_id) { warehouse_data_source.id }

  before do
    allow(GrdaWarehouse::DataSource).to receive(:warehouse_id).and_return(warehouse_id)
  end

  describe '.for_ssn_matches' do
    describe 'executing generated SQL for existing matches' do
      let!(:source_data_source) { create(:source_data_source) }
      let!(:destination_data_source) { create(:grda_warehouse_data_source) }

      it 'returns duplicate destination pairs when two clients share an SSN' do
        client1 = create(:grda_warehouse_hud_client, data_source: source_data_source, SSN: '555667777')
        client2 = create(:grda_warehouse_hud_client, data_source: source_data_source, SSN: '555667777')
        dest1 = create(:grda_warehouse_hud_client, data_source: destination_data_source)
        dest2 = create(:grda_warehouse_hud_client, data_source: destination_data_source)
        create(:warehouse_client, source_id: client1.id, destination_id: dest1.id)
        create(:warehouse_client, source_id: client2.id, destination_id: dest2.id)

        sql = described_class.for_ssn_matches(match_type: :existing).to_sql(warehouse_id: warehouse_id)
        results = GrdaWarehouse::Hud::Client.connection.execute(sql)

        expect(results.map { |row| [row['destination_one_id'], row['destination_two_id']].sort }).to contain_exactly([dest1.id, dest2.id].sort)
      end

      it 'filters out invalid SSNs' do
        client1 = create(:grda_warehouse_hud_client, data_source: source_data_source, SSN: '000000000')
        client2 = create(:grda_warehouse_hud_client, data_source: source_data_source, SSN: '000000000')
        dest1 = create(:grda_warehouse_hud_client, data_source: destination_data_source)
        dest2 = create(:grda_warehouse_hud_client, data_source: destination_data_source)
        create(:warehouse_client, source_id: client1.id, destination_id: dest1.id)
        create(:warehouse_client, source_id: client2.id, destination_id: dest2.id)

        sql = described_class.for_ssn_matches(match_type: :existing).to_sql(warehouse_id: warehouse_id)
        results = GrdaWarehouse::Hud::Client.connection.execute(sql)

        expect(results.count).to eq(0)
      end

      it 'generates all unique pairs when three clients share an SSN' do
        client1 = create(:grda_warehouse_hud_client, data_source: source_data_source, SSN: '555667777')
        client2 = create(:grda_warehouse_hud_client, data_source: source_data_source, SSN: '555667777')
        client3 = create(:grda_warehouse_hud_client, data_source: source_data_source, SSN: '555667777')
        dest1 = create(:grda_warehouse_hud_client, data_source: destination_data_source)
        dest2 = create(:grda_warehouse_hud_client, data_source: destination_data_source)
        dest3 = create(:grda_warehouse_hud_client, data_source: destination_data_source)
        create(:warehouse_client, source_id: client1.id, destination_id: dest1.id)
        create(:warehouse_client, source_id: client2.id, destination_id: dest2.id)
        create(:warehouse_client, source_id: client3.id, destination_id: dest3.id)

        sql = described_class.for_ssn_matches(match_type: :existing).to_sql(warehouse_id: warehouse_id)
        results = GrdaWarehouse::Hud::Client.connection.execute(sql)

        expect(results.map { |row| [row['destination_one_id'], row['destination_two_id']].sort }).to match_array([
                                                                                                                   [dest1.id, dest2.id].sort,
                                                                                                                   [dest1.id, dest3.id].sort,
                                                                                                                   [dest2.id, dest3.id].sort,
                                                                                                                 ])
      end
    end

    describe 'executing generated SQL for unprocessed matches' do
      let!(:source_data_source) { create(:source_data_source) }
      let!(:destination_data_source) { create(:grda_warehouse_data_source) }

      it 'returns all destination-source combinations for unprocessed clients' do
        common_ssn = '555667777'
        destination_a = create(:grda_warehouse_hud_client, data_source: destination_data_source, SSN: common_ssn)
        destination_b = create(:grda_warehouse_hud_client, data_source: destination_data_source, SSN: common_ssn)
        source_a = create(:grda_warehouse_hud_client, data_source: source_data_source, SSN: common_ssn)
        source_b = create(:grda_warehouse_hud_client, data_source: source_data_source, SSN: common_ssn)

        sql = described_class.for_ssn_matches(
          match_type: :unprocessed,
          destination_data_source_ids: [destination_data_source.id],
          unprocessed_ids: [source_a.id, source_b.id],
        ).to_sql(warehouse_id: warehouse_id)

        results = GrdaWarehouse::Hud::Client.connection.execute(sql)

        expect(results.map { |row| [row['destination_client_id'], row['source_client_id']] }).to match_array(
          [
            [destination_a.id, source_a.id],
            [destination_a.id, source_b.id],
            [destination_b.id, source_a.id],
            [destination_b.id, source_b.id],
          ],
        )
      end
    end
  end

  describe '#execute' do
    let!(:source_data_source) { create(:source_data_source) }
    let!(:destination_data_source) { create(:grda_warehouse_data_source) }

    it 'returns destination pairs ordered with the lower id first' do
      common_ssn = '555667777'
      source_clients = create_list(:grda_warehouse_hud_client, 3, data_source: source_data_source, SSN: common_ssn)
      destinations = create_list(:grda_warehouse_hud_client, 3, data_source: destination_data_source)

      source_clients.zip(destinations).each do |source_client, destination|
        create(:warehouse_client, source_id: source_client.id, destination_id: destination.id)
      end

      pairs = described_class.for_ssn_matches(match_type: :existing).execute

      destination_ids = destinations.map(&:id)
      expected_pairs = destination_ids.combination(2).map { |a, b| [a, b].sort }

      expect(pairs).to match_array(expected_pairs)
      pairs.each do |first_id, second_id|
        expect(first_id).to be < second_id
      end
    end
  end

  describe '.for_name_matches' do
    let!(:source_data_source) { create(:source_data_source) }
    let!(:destination_data_source) { create(:grda_warehouse_data_source) }

    it 'matches names with different casing and special characters' do
      client1 = create(:grda_warehouse_hud_client, data_source: source_data_source, FirstName: 'John', LastName: 'O\'Brien')
      client2 = create(:grda_warehouse_hud_client, data_source: source_data_source, FirstName: 'JOHN', LastName: 'OBRIEN')
      dest1 = create(:grda_warehouse_hud_client, data_source: destination_data_source)
      dest2 = create(:grda_warehouse_hud_client, data_source: destination_data_source)
      create(:warehouse_client, source_id: client1.id, destination_id: dest1.id)
      create(:warehouse_client, source_id: client2.id, destination_id: dest2.id)

      sql = described_class.for_name_matches(match_type: :existing).to_sql(warehouse_id: warehouse_id)
      results = GrdaWarehouse::Hud::Client.connection.execute(sql)

      expect(results.map { |row| [row['destination_one_id'], row['destination_two_id']].sort }).to contain_exactly([dest1.id, dest2.id].sort)
    end

    it 'ignores clients with blank names' do
      client1 = create(:grda_warehouse_hud_client, data_source: source_data_source, FirstName: '', LastName: '')
      client2 = create(:grda_warehouse_hud_client, data_source: source_data_source, FirstName: '', LastName: '')
      dest1 = create(:grda_warehouse_hud_client, data_source: destination_data_source)
      dest2 = create(:grda_warehouse_hud_client, data_source: destination_data_source)
      create(:warehouse_client, source_id: client1.id, destination_id: dest1.id)
      create(:warehouse_client, source_id: client2.id, destination_id: dest2.id)

      sql = described_class.for_name_matches(match_type: :existing).to_sql(warehouse_id: warehouse_id)
      results = GrdaWarehouse::Hud::Client.connection.execute(sql)

      expect(results.count).to eq(0)
    end
  end

  describe '.for_dob_matches' do
    let!(:source_data_source) { create(:source_data_source) }
    let!(:destination_data_source) { create(:grda_warehouse_data_source) }

    it 'matches clients with identical DOB' do
      common_dob = '1985-03-15'
      client1 = create(:grda_warehouse_hud_client, data_source: source_data_source, DOB: common_dob)
      client2 = create(:grda_warehouse_hud_client, data_source: source_data_source, DOB: common_dob)
      dest1 = create(:grda_warehouse_hud_client, data_source: destination_data_source)
      dest2 = create(:grda_warehouse_hud_client, data_source: destination_data_source)
      create(:warehouse_client, source_id: client1.id, destination_id: dest1.id)
      create(:warehouse_client, source_id: client2.id, destination_id: dest2.id)

      sql = described_class.for_dob_matches(match_type: :existing).to_sql(warehouse_id: warehouse_id)
      results = GrdaWarehouse::Hud::Client.connection.execute(sql)

      expect(results.map { |row| [row['destination_one_id'], row['destination_two_id']].sort }).to contain_exactly([dest1.id, dest2.id].sort)
    end

    it 'filters out DOBs before 1920' do
      old_dob = '1919-01-01'
      client1 = create(:grda_warehouse_hud_client, data_source: source_data_source, DOB: old_dob)
      client2 = create(:grda_warehouse_hud_client, data_source: source_data_source, DOB: old_dob)
      dest1 = create(:grda_warehouse_hud_client, data_source: destination_data_source)
      dest2 = create(:grda_warehouse_hud_client, data_source: destination_data_source)
      create(:warehouse_client, source_id: client1.id, destination_id: dest1.id)
      create(:warehouse_client, source_id: client2.id, destination_id: dest2.id)

      sql = described_class.for_dob_matches(match_type: :existing).to_sql(warehouse_id: warehouse_id)
      results = GrdaWarehouse::Hud::Client.connection.execute(sql)

      expect(results.count).to eq(0)
    end
  end

  describe '#to_sql error handling' do
    it 'raises when match_type invalid' do
      expect do
        described_class.for_ssn_matches(match_type: :unknown)
      end.to raise_error(ArgumentError, /Unsupported match_type/)
    end

    it 'raises when destination ids missing for unprocessed' do
      matcher = described_class.for_ssn_matches(match_type: :unprocessed, destination_data_source_ids: nil, unprocessed_ids: [1])

      expect { matcher.to_sql(warehouse_id: warehouse_id) }.to raise_error(ArgumentError, /destination_data_source_ids must be provided/)
    end

    it 'raises when unprocessed ids missing for unprocessed' do
      matcher = described_class.for_ssn_matches(match_type: :unprocessed, destination_data_source_ids: [1], unprocessed_ids: [])

      expect { matcher.to_sql(warehouse_id: warehouse_id) }.to raise_error(ArgumentError, /unprocessed_ids must be provided/)
    end
  end
end

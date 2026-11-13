###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudChronicDefinition, type: :model do
  let!(:warehouse_ds) { create :destination_data_source }
  let!(:source_ds) { create :source_data_source }
  let!(:project) { create :grda_warehouse_hud_project, ProjectType: 1, data_source_id: source_ds.id }

  # Clients enter an emergency shelter on entry_date and stay. The disability is recorded later, so on
  # date_before_disability a disabled client has been homeless for over 12 months but is not yet chronically
  # disabled (and so not HUD chronic), and on date_after_disability they are both.
  let(:entry_date) { Date.new(2014, 4, 1) }
  let(:disability_information_date) { Date.new(2016, 1, 1) }
  let(:date_before_disability) { Date.new(2015, 6, 1) }
  let(:date_after_disability) { Date.new(2016, 4, 1) }

  def create_destination_client(disabled:)
    destination = create(:grda_warehouse_hud_client, data_source_id: warehouse_ds.id)
    source = create(:grda_warehouse_hud_client, data_source_id: source_ds.id, PersonalID: destination.PersonalID)
    create(:warehouse_client, destination: destination, source: source, data_source_id: source_ds.id)
    enrollment = create(
      :hud_enrollment,
      ProjectID: project.ProjectID,
      EntryDate: entry_date,
      DateToStreetESSH: entry_date,
      DisablingCondition: 0,
      data_source_id: source_ds.id,
      PersonalID: source.PersonalID,
    )
    if disabled
      create(
        :hud_disability,
        EnrollmentID: enrollment.EnrollmentID,
        InformationDate: disability_information_date,
        data_source_id: source_ds.id,
        PersonalID: source.PersonalID,
        DisabilityType: 5,
        DisabilityResponse: 1,
        IndefiniteAndImpairs: 1,
      )
    end
    destination
  end

  let!(:disabled_client) { create_destination_client(disabled: true) }
  let!(:other_disabled_client) { create_destination_client(disabled: true) }
  let!(:not_disabled_client) { create_destination_client(disabled: false) }

  def fresh(client)
    GrdaWarehouse::Hud::Client.find(client.id)
  end

  # The chronically_disabled scope is the only query with this condition
  let(:chronically_disabled_sql) { '"disability_verified_on" IS NOT NULL' }

  # A filter on Client.id by a value or a list of values, but not "IN (SELECT ...)"
  let(:client_id_filter) { /"Client"\."id" (?:= |IN \((?!SELECT))/ }

  # The scope has an outer WHERE and two subqueries. The id filter must reach all three, or the
  # subqueries scan every destination client (~15 s instead of ~55 ms for a batch).
  let(:client_id_filters_per_query) { 3 }

  # SQL and bind values of the chronically_disabled queries run inside the block, as { sql:, binds: }
  def chronically_disabled_queries
    queries = []
    callback = ->(*, payload) do
      next unless payload[:sql].include?(chronically_disabled_sql)

      queries << { sql: payload[:sql], binds: payload[:type_casted_binds] }
    end
    ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') { yield }
    queries
  end

  describe '#disabled?' do
    it 'answers for each date on the same client instance' do
      client = fresh(disabled_client)

      expect(client.disabled?(on_date: date_after_disability)).to be true
      expect(client.disabled?(on_date: date_before_disability)).to be false
    end

    it 'answers for each date on separate client instances' do
      expect(fresh(disabled_client).disabled?(on_date: date_before_disability)).to be false
      expect(fresh(disabled_client).disabled?(on_date: date_after_disability)).to be true
      expect(fresh(not_disabled_client).disabled?(on_date: date_after_disability)).to be false
    end

    # Pins current behavior only. The scope subquery selects Enrollment.id from Client without a join,
    # so it is not limited to this client. That latent bug is tracked separately.
    it 'is true with a scope when the client is disabled through an enrollment in the scope' do
      client = fresh(disabled_client)
      scope = client.source_enrollments

      expect(client.disabled?(on_date: date_after_disability, scope: scope)).to be true
    end
  end

  describe '#meets_hud_chronic_duration?' do
    it 'checks homelessness only, without the disability check' do
      client = fresh(not_disabled_client)
      expect(GrdaWarehouse::Hud::Client).not_to receive(:chronically_disabled)

      expect(client.meets_hud_chronic_duration?(on_date: date_after_disability)).to be true
      expect(client.hud_chronic_data[:trigger]).to eq('All 12 of the last 12 months homeless')
    end
  end

  describe 'chronic calculator page path' do
    it 'checks only this client, once per date' do
      client = fresh(disabled_client)

      queries = chronically_disabled_queries do
        # Mirrors app/views/clients/chronic/_chronic_calculator.haml, which asks both questions per date
        [date_after_disability, date_before_disability].each do |date|
          client.hud_chronic?(on_date: date)
          client.disabled?(on_date: date)
        end
      end

      # One query per date, limited to this client everywhere, never the system-wide set
      expect(queries.size).to eq(2)
      queries.each do |query|
        expect(query[:sql].scan(client_id_filter).size).to eq(client_id_filters_per_query)
        expect(query[:binds].count(client.id)).to eq(client_id_filters_per_query)
      end
    end
  end

  describe 'HUD chronic backfill' do
    let(:all_client_ids) { [disabled_client.id, other_disabled_client.id, not_disabled_client.id] }

    [1, 3].each do |batch_size|
      it "runs chronically_disabled once for a batch of #{batch_size}" do
        batch_ids = all_client_ids.first(batch_size)
        expect(GrdaWarehouse::Hud::Client).to receive(:chronically_disabled).once.and_call_original

        Reporting::RunHudChronicJob.perform_now(batch_ids, date_after_disability.to_s)
      end
    end

    it "limits the batch's query to the batch's clients, including inside the scope's subqueries" do
      batch_ids = [disabled_client.id, not_disabled_client.id]

      queries = chronically_disabled_queries do
        Reporting::RunHudChronicJob.perform_now(batch_ids, date_after_disability.to_s)
      end

      expect(queries.size).to eq(1)
      query = queries.first
      expect(query[:sql].scan(client_id_filter).size).to eq(client_id_filters_per_query)
      batch_ids.each do |id|
        expect(query[:binds].count(id)).to eq(client_id_filters_per_query)
      end
      # Leaves out the disabled client outside the batch
      expect(query[:binds]).not_to include(other_disabled_client.id)
    end

    it 'runs one query per batch and writes correct HudChronic rows for each date' do
      allow(Reporting::RunHudChronicJob).to receive(:perform_later) do |ids, date|
        Reporting::RunHudChronicJob.perform_now(ids, date)
      end
      # Three clients in batches of two is two batches per date
      expect(GrdaWarehouse::Hud::Client).to receive(:chronically_disabled).exactly(4).times.and_call_original

      # The later date runs first, so a date-blind cache or memo would carry its answers into the earlier date
      [date_after_disability, date_before_disability].each do |date|
        GrdaWarehouse::Tasks::HudChronicallyHomeless.new(
          date: date,
          client_ids: all_client_ids,
          batch_size: 2,
        ).run!
      end

      expect(GrdaWarehouse::HudChronic.where(date: date_before_disability)).to be_empty
      chronic_client_ids = GrdaWarehouse::HudChronic.where(date: date_after_disability).pluck(:client_id)
      expect(chronic_client_ids).to contain_exactly(disabled_client.id, other_disabled_client.id)
    end
  end
end

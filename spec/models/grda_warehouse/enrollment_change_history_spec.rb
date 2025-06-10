###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::EnrollmentChangeHistory, type: :model do
  describe '.create_for_clients_on_date!' do
    let(:today) { Date.current }
    let!(:data_source) { create :grda_warehouse_data_source, authoritative: true }
    let!(:wh_data_source) { create :grda_warehouse_data_source, source_type: nil, authoritative: false }
    let!(:organization) { create :hud_organization, data_source: data_source }
    let!(:project) do
      create(
        :grda_warehouse_hud_project,
        organization: organization,
        project_type: 4,
        data_source: data_source,
      )
    end

    let(:days_homeless) { 30 }
    let!(:source_clients) do
      3.times.map do
        source_client = create :hud_client, data_source_id: data_source.id
        create :hud_enrollment, client: source_client, data_source: data_source, project: project, entry_date: today - days_homeless.days
        client = create(:hud_client, data_source: wh_data_source)
        create :warehouse_client, source_id: source_client.id, destination_id: client.id, data_source: data_source
        source_client
      end
    end
    let(:destination_clients) do
      source_clients.map(&:destination_client)
    end

    it 'passes a smoke test' do
      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.all.each(&:rebuild_service_history!)

      expect do
        described_class.create_for_clients_on_date!(client_ids: destination_clients.map(&:id), date: today)
      end.to change(described_class, :count).by(3).
        and make_database_queries(count: 20..70)

      # destination_clients.map(&:reload)
      destination_clients.each do |client|
        history = described_class.where(client_id: client.id).sole
        expect(history.on).to eq(today)

        JSON.parse(history.residential).tap do |parsed|
          expect(parsed).to be_one
          expect(parsed.dig(0, 'project_id')).to eq(project.id)
        end
        JSON.parse(history.other).tap do |parsed|
          expect(parsed).to be_empty
        end
        expect(history.days_homeless).to eq(days_homeless + 1)
      end
    end
  end
end

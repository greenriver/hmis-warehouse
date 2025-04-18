# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Cohorts::CohortAnalyticsGeneration, type: :model do
  let!(:cohort) { create :cohort }
  let!(:tabs) do
    GrdaWarehouse::CohortTab.default_rules.each do |rule|
      cohort.cohort_tabs.create(**rule)
    end
  end
  let!(:cohort_columns) do
    columns = cohort.class.available_columns.deep_dup
    columns.each do |column|
      column.visible = true
    end
    cohort.update(column_state: columns)
  end

  let!(:warehouse_clients) { create_list :warehouse_client, 5 }
  let!(:clients) { warehouse_clients.map(&:destination) }
  let!(:source_clients) { warehouse_clients.map(&:source) }

  let!(:cohort_clients) do
    clients.map do |client|
      create :cohort_client, cohort: cohort, client: client
    end
  end

  before(:all) do
    GrdaWarehouse::Cohorts::CohortColumn.maintain!
  end

  describe 'Processes cohort data into tables that back views' do
    before(:each) do
      GrdaWarehouse::Cohort.prepare_active_cohorts
      described_class.maintain_cohort_intermediate_data
    end

    it 'places data as expected' do
      aggregate_failures do
        expect(GrdaWarehouse::Cohorts::CohortColumnMetadata.count).to be > 5
        active_columns = cohort.active_columns.map(&:class) - cohort.class.excluded_from_analytics.to_a
        expect(GrdaWarehouse::Cohorts::CohortColumnMetadata.count).to eq(active_columns.count)

        expect(GrdaWarehouse::Cohorts::CohortClientTab.count).to be > 0
        expect(GrdaWarehouse::Cohorts::CohortClientTab.pluck(:cohort_client_id)).to contain_exactly(*cohort_clients.pluck(:id))

        expect(GrdaWarehouse::Cohorts::CohortClientData.count).to be > 500

        cc = cohort_clients.last
        ccd = GrdaWarehouse::Cohorts::CohortClientData.find_by(cohort_client_id: cc.id, column_name: :source_client_personal_ids)
        expect(ccd.value_string).to eq(cc.client.source_clients.pluck(:personal_id).join(', '))
        expect(ccd.value_string).to be_present
        expect(ccd.data_type).to eq('string')
      end
    end
  end
end

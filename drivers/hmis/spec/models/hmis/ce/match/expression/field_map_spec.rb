# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::Expression::FieldMap, type: :model do
  let(:current_date) { Date.new(2024, 12, 26) }
  let(:field_map) { described_class.new(current_date: current_date) }

  # Test doubles for orchestration testing
  let(:client_resolver) { instance_double(Hmis::Ce::Match::Expression::ClientFieldMap) }
  let(:cde_resolver) { instance_double(Hmis::Ce::Match::Expression::CdeFieldMap) }
  let(:custom_assessment_resolver) { instance_double(Hmis::Ce::Match::Expression::CustomAssessmentFieldMap) }

  let(:clients) { double('client_relation') }

  before do
    # Stub the resolvers registry to return our test doubles
    allow(field_map).to receive(:registered_resolvers).and_return({
                                                                    described_class::CLIENT => client_resolver,
                                                                    described_class::CDE => cde_resolver,
                                                                    described_class::CUSTOM_ASSESSMENT => custom_assessment_resolver,
                                                                  })
  end

  describe 'delegation' do
    it 'routes simple fields to the client resolver' do
      expect(client_resolver).to receive(:client_query).with(clients, 'veteran_status')
      field_map.client_query(clients, 'veteran_status')

      expect(client_resolver).to receive(:arel_field).with('veteran_status')
      field_map.arel_field('veteran_status')

      expect(client_resolver).to receive(:joins).with('veteran_status')
      field_map.joins('veteran_status')
    end

    it 'routes client-namespaced fields to the client resolver' do
      expect(client_resolver).to receive(:client_query).with(clients, 'current_age')
      field_map.client_query(clients, 'client.current_age')
    end

    it 'routes custom_assessment fields to the custom assessment resolver' do
      expect(custom_assessment_resolver).to receive(:client_query).with(clients, 'form.field')
      field_map.client_query(clients, 'custom_assessment.form.field')
    end

    it 'routes cde fields to the cde resolver' do
      expect(cde_resolver).to receive(:client_query).with(clients, 'form.field')
      field_map.client_query(clients, 'cde.form.field')
    end
  end

  describe '#resolve_field_for_display' do
    let!(:destination_data_source) { create :destination_data_source }
    let(:client) { create(:hmis_hud_client_with_warehouse_client).destination_client }
    let(:clients) { GrdaWarehouse::Hud::Client.where(id: client.id) }

    it 'delegates to the appropriate resolver' do
      # Set up mocks for a client field
      expect(client_resolver).to receive(:label_for).with('veteran_status').and_return('Veteran Status')
      expect(client_resolver).to receive(:client_query).with(clients, 'veteran_status').and_return({ client.id => 1 })
      expect(client_resolver).to receive(:format_for_display).with('veteran_status', 1).and_return('Yes')

      label, formatted = field_map.resolve_field_for_display(client, 'veteran_status')
      expect(label).to eq('Veteran Status')
      expect(formatted).to eq('Yes')
    end
  end
end

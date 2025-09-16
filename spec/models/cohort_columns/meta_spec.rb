# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CohortColumns::Meta, type: :model do
  let(:client) { create :hud_client }
  let(:cohort) { create :cohort }
  let(:cohort_client) { create :cohort_client, cohort: cohort, client: client }
  let(:meta_column) { described_class.new(cohort: cohort, cohort_client: cohort_client) }

  describe '#last_activity' do
    context 'when there are no activities' do
      it 'returns nil when no service history exists' do
        allow(cohort_client.client).to receive(:processed_service_history).and_return(nil)
        expect(meta_column.last_activity).to be_nil
      end
    end

    context 'when there are only homeless dates' do
      let(:last_homeless_date) { Date.current - 30.days }

      before do
        service_history = double(
          'processed_service_history',
          last_homeless_date: last_homeless_date,
          last_intentional_contacts: nil,
        )
        allow(cohort_client.client).to receive(:processed_service_history).and_return(service_history)
      end

      it 'returns the last homeless date' do
        expect(meta_column.last_activity).to eq(last_homeless_date)
      end
    end

    context 'when there are only intentional contacts' do
      let(:contact_date) { Date.current - 15.days }
      let(:contacts_json) { [{ 'date' => contact_date.to_fs(:db), 'project_id' => 1 }].to_json }

      before do
        service_history = double(
          'processed_service_history',
          last_homeless_date: nil,
          last_intentional_contacts: contacts_json,
        )
        allow(cohort_client.client).to receive(:processed_service_history).and_return(service_history)
      end

      it 'returns the last contact date' do
        expect(meta_column.last_activity).to eq(contact_date)
      end
    end

    context 'when there are both homeless dates and intentional contacts' do
      let(:last_homeless_date) { Date.current - 30.days }
      let(:contact_date) { Date.current - 15.days }
      let(:contacts_json) { [{ 'date' => contact_date.to_fs(:db), 'project_id' => 1 }].to_json }

      before do
        service_history = double(
          'processed_service_history',
          last_homeless_date: last_homeless_date,
          last_intentional_contacts: contacts_json,
        )
        allow(cohort_client.client).to receive(:processed_service_history).and_return(service_history)
      end

      it 'returns the most recent date between homeless and contact dates' do
        expect(meta_column.last_activity).to eq(contact_date)
      end
    end

    context 'when there are multiple intentional contacts' do
      let(:older_contact_date) { Date.current - 30.days }
      let(:newer_contact_date) { Date.current - 15.days }
      let(:contacts_json) do
        [
          { 'date' => older_contact_date.to_fs(:db), 'project_id' => 1 },
          { 'date' => newer_contact_date.to_fs(:db), 'project_id' => 2 },
        ].to_json
      end

      before do
        service_history = double(
          'processed_service_history',
          last_homeless_date: nil,
          last_intentional_contacts: contacts_json,
        )
        allow(cohort_client.client).to receive(:processed_service_history).and_return(service_history)
      end

      it 'returns the most recent contact date' do
        expect(meta_column.last_activity).to eq(newer_contact_date)
      end
    end
  end
end

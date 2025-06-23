# frozen_string_literal: true

require 'rails_helper'
require 'active_support/testing/time_helpers'

RSpec.describe Hmis::Ce::Match::Engine, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  # override in tests
  let(:requirement_expression) { 'TRUE' }
  let(:priority_expression) { '0' }
  let(:pool) do
    create(
      :hmis_ce_match_candidate_pool,
      requirement_expression: requirement_expression,
      priority_expression: priority_expression,
    )
  end

  def generate_candidates(pool, clients)
    described_class.call(pool, clients)
    pool.candidates
  end

  context 'demographic rules' do
    let(:client_adult_non_veteran) { create(:hmis_hud_client, veteran_status: 0, dob: 20.years.ago) }
    let(:client_minor_non_veteran) { create(:hmis_hud_client, veteran_status: 0, dob: 10.years.ago) }
    let(:client_adult_veteran) { create(:hmis_hud_client, veteran_status: 1, dob: 20.years.ago) }
    let(:client_senior_veteran) { create(:hmis_hud_client, veteran_status: 1, dob: 68.years.ago) }

    let(:clients) do
      Hmis::Hud::Client.where(id: [
        client_adult_non_veteran,
        client_minor_non_veteran,
        client_adult_veteran,
        client_senior_veteran,
      ].map(&:id))
    end

    let(:adult_clients) do
      clients - [client_minor_non_veteran]
    end

    describe 'Policy that is always false' do
      let(:requirement_expression) { '1=0' }
      it 'returns no candidates' do
        results = generate_candidates(pool, clients)
        expect(results).to be_empty
      end
    end

    describe 'Policy that is always true' do
      let(:requirement_expression) { '1=1' }
      it 'returns all candidates' do
        results = generate_candidates(pool, clients)
        expect(results.map(&:client_id).sort).to eq(clients.map(&:id).sort)
      end
    end

    describe 'Policy that evaluates age' do
      let(:requirement_expression) { 'current_age > 18' }
      it 'filters correctly' do
        results = generate_candidates(pool, clients)
        expect(results.map(&:client_id).sort).to eq(adult_clients.map(&:id).sort)
      end
    end

    describe 'Policy that evaluates age and veteran status' do
      let(:requirement_expression) { 'current_age >= 65 AND veteran_status = 1' }
      it 'filters correctly' do
        results = generate_candidates(pool, clients)
        expect(results.map(&:client_id).sort).to eq([client_senior_veteran.id])
      end

      it 'sets the candidates_generated_at timestamp' do
        freeze_time do
          expect do
            generate_candidates(pool, clients)
          end.to change(pool, :candidates_generated_at).from(nil).to(Time.current)
        end
      end
    end
  end

  context 'CDE fields' do
    let(:data_source) { create(:hmis_data_source) }
    let(:fd) { create(:hmis_form_definition, role: :CUSTOM_ASSESSMENT, status: :published, version: 1) }
    let(:cded) do
      create(
        :hmis_custom_data_element_definition,
        data_source: data_source,
        owner_type: 'Hmis::Hud::CustomAssessment',
        field_type: 'string',
        key: 'hat_client_interested_in_ph',
        form_definition_identifier: fd.identifier,
      )
    end

    let(:client_interested_in_ph) { create(:hmis_hud_client, data_source: data_source) }
    let(:client_not_interested_in_ph) { create(:hmis_hud_client, data_source: data_source) }
    let(:project) { create(:hmis_hud_project, data_source: data_source) }

    before do
      # setup assessments and cde values
      clients.each do |client|
        enrollment = create(:hmis_hud_enrollment, data_source: data_source, project: project, client: client)
        assessment = create(:hmis_custom_assessment, data_source: data_source, enrollment: enrollment, definition: fd)
        cde_value = client == client_interested_in_ph ? '1' : '0'
        assessment.custom_data_elements.create!( # cde factory doesn't seem to work
          value_string: cde_value,
          data_source: data_source,
          data_element_definition: cded,
          UserID: 'fake',
        )
      end
    end

    let(:clients) do
      Hmis::Hud::Client.where(id: [
        client_interested_in_ph,
        client_not_interested_in_ph,
      ].map(&:id))
    end

    describe 'Policy that evaluates a CDE field' do
      let(:requirement_expression) { "`cde.custom_assessment.hat_client_interested_in_ph` = '1'" }
      it 'filters correctly' do
        results = generate_candidates(pool, clients)
        expect(results.map(&:client_id).sort).to eq([client_interested_in_ph.id])
      end
    end
  end
end

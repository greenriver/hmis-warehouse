# frozen_string_literal: true

require 'rails_helper'
require 'active_support/testing/time_helpers'

RSpec.describe Hmis::Ce::Match::Engine, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:data_source) { create(:hmis_data_source) }
  let(:fd) { create(:hmis_form_definition, role: :CUSTOM_ASSESSMENT, status: :published, version: 1) }
  let(:project) { create(:hmis_hud_project, data_source: data_source) }
  let(:pool) do
    create(
      :hmis_ce_match_candidate_pool,
      requirement_expression: requirement_expression,
      priority_expression: priority_expression,
    )
  end

  # Override in specific tests
  let(:requirement_expression) { 'TRUE' }
  let(:priority_expression) { '0' }

  def generate_candidates(pool, clients)
    described_class.call(pool, clients)
    pool.candidates
  end

  shared_context 'with demographic test clients' do
    let(:client_adult_non_veteran) { create(:hmis_hud_client, veteran_status: 0, dob: 20.years.ago) }
    let(:client_minor_non_veteran) { create(:hmis_hud_client, veteran_status: 0, dob: 10.years.ago) }
    let(:client_adult_veteran) { create(:hmis_hud_client, veteran_status: 1, dob: 20.years.ago) }
    let(:client_senior_veteran) { create(:hmis_hud_client, veteran_status: 1, dob: 68.years.ago) }

    let(:all_clients) do
      [client_adult_non_veteran, client_minor_non_veteran, client_adult_veteran, client_senior_veteran]
    end

    let(:clients) { Hmis::Hud::Client.where(id: all_clients.map(&:id)) }
    let(:adult_clients) { clients.where.not(id: client_minor_non_veteran.id) }
  end

  shared_context 'with CDE assessment setup' do
    let(:cded) do
      create(
        :hmis_custom_data_element_definition,
        data_source: data_source,
        owner_type: 'Hmis::Hud::CustomAssessment',
        field_type: 'string',
        key: cde_key,
        form_definition_identifier: fd.identifier,
        repeats: multi_valued_cde,
      )
    end

    let(:multi_valued_cde) { false }

    def create_assessment_with_cde(client, cde_values)
      enrollment = create(:hmis_hud_enrollment, data_source: data_source, project: project, client: client)
      assessment = create(:hmis_custom_assessment, data_source: data_source, enrollment: enrollment, definition: fd)

      Array(cde_values).each do |value|
        assessment.custom_data_elements.create!(
          value_string: value,
          data_source: data_source,
          data_element_definition: cded,
          UserID: 'fake',
        )
      end
    end
  end

  context 'when evaluating demographic-based policies' do
    include_context 'with demographic test clients'

    describe 'policy that never matches' do
      let(:requirement_expression) { '1=0' }

      it 'returns no candidates' do
        results = generate_candidates(pool, clients)
        expect(results).to be_empty
      end
    end

    describe 'policy that always matches' do
      let(:requirement_expression) { '1=1' }

      it 'returns all candidates' do
        results = generate_candidates(pool, clients)
        expect(results.map(&:client_id).sort).to eq(clients.map(&:id).sort)
      end
    end

    describe 'age-based filtering' do
      let(:requirement_expression) { 'current_age > 18' }

      it 'excludes minors from candidates' do
        results = generate_candidates(pool, clients)
        expect(results.map(&:client_id).sort).to eq(adult_clients.map(&:id).sort)
      end
    end

    describe 'combined age and veteran status filtering' do
      let(:requirement_expression) { 'current_age >= 65 AND veteran_status = 1' }

      it 'only includes senior veterans' do
        results = generate_candidates(pool, clients)
        expect(results.map(&:client_id)).to eq([client_senior_veteran.id])
      end

      it 'updates the candidates_generated_at timestamp' do
        freeze_time do
          expect do
            generate_candidates(pool, clients)
          end.to change(pool, :candidates_generated_at).from(nil).to(Time.current)
        end
      end
    end
  end

  context 'when evaluating single-valued CDE policies' do
    include_context 'with CDE assessment setup'

    let(:cde_key) { 'hat_client_interested_in_ph' }
    let(:client_interested_in_ph) { create(:hmis_hud_client, data_source: data_source) }
    let(:client_not_interested_in_ph) { create(:hmis_hud_client, data_source: data_source) }
    let(:clients) { Hmis::Hud::Client.where(id: [client_interested_in_ph, client_not_interested_in_ph].map(&:id)) }

    before do
      create_assessment_with_cde(client_interested_in_ph, '1')
      create_assessment_with_cde(client_not_interested_in_ph, '0')
    end

    describe 'CDE field matching' do
      let(:requirement_expression) { "`cde.custom_assessment.hat_client_interested_in_ph` = '1'" }

      it 'filters based on CDE value' do
        results = generate_candidates(pool, clients)
        expect(results.map(&:client_id)).to eq([client_interested_in_ph.id])
      end
    end
  end

  context 'when evaluating multi-valued CDE policies' do
    include_context 'with CDE assessment setup'

    let(:cde_key) { 'primary_languages' }
    let(:multi_valued_cde) { true }
    let(:client_english_spanish) { create(:hmis_hud_client, data_source: data_source) }
    let(:client_french_only) { create(:hmis_hud_client, data_source: data_source) }
    let(:clients) { Hmis::Hud::Client.where(id: [client_english_spanish, client_french_only].map(&:id)) }

    before do
      create_assessment_with_cde(client_english_spanish, ['English', 'Spanish'])
      create_assessment_with_cde(client_french_only, 'French')
    end

    describe 'multi-valued CDE inclusion matching' do
      let(:requirement_expression) { "`cde.custom_assessment.primary_languages` = 'English'" }

      it 'matches clients with the specified language among multiple values' do
        results = generate_candidates(pool, clients)
        expect(results.map(&:client_id)).to eq([client_english_spanish.id])
      end
    end

    describe 'multi-valued CDE exclusion matching' do
      let(:requirement_expression) { "`cde.custom_assessment.primary_languages` != 'French'" }

      it 'excludes clients who have the specified language' do
        results = generate_candidates(pool, clients)
        expect(results.map(&:client_id)).to eq([client_english_spanish.id])
      end
    end
  end
end

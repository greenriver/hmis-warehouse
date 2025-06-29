# frozen_string_literal: true

require 'rails_helper'
require 'active_support/testing/time_helpers'

RSpec.describe Hmis::Ce::Match::Engine, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  # must exist for identify duplicates, we match on destination clients
  let!(:destination_data_source) { create :destination_data_source }
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
    # create destination clients
    GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
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

  shared_context 'with enrolled test clients' do
    let(:es_project) { create(:hmis_hud_project, data_source: data_source, project_type: 1) }
    let(:ce_project) { create(:hmis_hud_project, data_source: data_source, project_type: 14) }
    let(:ph_project) { create(:hmis_hud_project, data_source: data_source, project_type: 9) }
    let(:client_enrolled_in_ce_and_es) do
      client = create(:hmis_hud_client, data_source: data_source)
      create(:hmis_hud_enrollment, data_source: data_source, project: ce_project, exit_date: nil, client: client)
      create(:hmis_hud_enrollment, data_source: data_source, project: es_project, exit_date: nil, client: client)
      client
    end
    let(:client_enrolled_in_es) do
      client = create(:hmis_hud_client, data_source: data_source)
      create(:hmis_hud_enrollment, data_source: data_source, project: es_project, exit_date: nil, client: client)
      client
    end
    let(:client_enrolled_in_ph) do
      client = create(:hmis_hud_client, data_source: data_source)
      create(:hmis_hud_enrollment, data_source: data_source, project: ph_project, exit_date: nil, client: client)
      client
    end
    let(:client_exited_from_ce) do
      client = create(:hmis_hud_client, data_source: data_source)
      create(:hmis_hud_enrollment, data_source: data_source, project: ce_project, exit_date: 1.week.ago, client: client)
      client
    end
    let(:client_unenrolled) { create(:hmis_hud_client, data_source: data_source) }

    let(:all_clients) do
      [client_enrolled_in_ce_and_es, client_enrolled_in_es, client_enrolled_in_ph, client_exited_from_ce, client_unenrolled]
    end

    let(:clients) { Hmis::Hud::Client.where(id: all_clients.map(&:id)) }
    let(:clients_not_enrolled_in_ph) { clients.where.not(id: client_enrolled_in_ph.id) }
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
        expect(results.map(&:client_id).sort).to eq(clients.map { |c| c.destination_client.id }.sort)
      end
    end

    describe 'age-based filtering' do
      let(:requirement_expression) { 'current_age > 18' }

      it 'excludes minors from candidates' do
        results = generate_candidates(pool, clients)
        expect(results.map(&:client_id).sort).to eq(adult_clients.map { |c| c.destination_client.id }.sort)
      end
    end

    describe 'combined age and veteran status filtering' do
      let(:requirement_expression) { 'current_age >= 65 AND veteran_status = 1' }

      it 'only includes senior veterans' do
        results = generate_candidates(pool, clients)
        expect(results.map(&:client_id)).to eq([client_senior_veteran.destination_client.id])
      end

      it 'updates the candidates_generated_at timestamp' do
        freeze_time do
          expect do
            generate_candidates(pool, clients)
          end.to change(pool, :candidates_generated_at).from(nil).to(Time.current)
        end
      end
    end

    describe 'with missing demographic data' do
      let!(:client_with_missing_dob) { create(:hmis_hud_client, veteran_status: 1, dob: nil) }
      let!(:client_with_missing_veteran_status) { create(:hmis_hud_client, veteran_status: nil, dob: 20.years.ago) }

      let(:clients_with_missing_data) do
        Hmis::Hud::Client.where(id: all_clients.map(&:id) + [client_with_missing_dob.id, client_with_missing_veteran_status.id])
      end

      context 'when expression requires age' do
        let(:requirement_expression) { 'current_age > 18' }

        it 'excludes clients with missing DOB' do
          results = generate_candidates(pool, clients_with_missing_data)

          expected_dest_client_ids = [
            client_adult_non_veteran.destination_client.id,
            client_adult_veteran.destination_client.id,
            client_senior_veteran.destination_client.id,
            client_with_missing_veteran_status.destination_client.id,
          ]

          expect(results.map(&:client_id).sort).to eq(expected_dest_client_ids.sort)
        end
      end

      context 'when expression requires veteran status' do
        let(:requirement_expression) { 'veteran_status = 1' }

        it 'excludes clients with missing veteran status' do
          results = generate_candidates(pool, clients_with_missing_data)

          expected_dest_client_ids = [
            client_adult_veteran.destination_client.id,
            client_senior_veteran.destination_client.id,
            client_with_missing_dob.destination_client.id,
          ]

          expect(results.map(&:client_id).sort).to eq(expected_dest_client_ids.sort)
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
        expect(results.map(&:client_id)).to eq([client_interested_in_ph.destination_client.id])
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
      let(:requirement_expression) { "includes(`cde.custom_assessment.primary_languages`, 'English')" }

      it 'matches clients with the specified language among multiple values' do
        results = generate_candidates(pool, clients)
        expect(results.map(&:client_id)).to eq([client_english_spanish.destination_client.id])
      end
    end

    describe 'multi-valued CDE exclusion matching' do
      let(:requirement_expression) { "excludes(`cde.custom_assessment.primary_languages`, 'French')" }

      it 'excludes clients who have the specified language' do
        results = generate_candidates(pool, clients)
        expect(results.map(&:client_id)).to eq([client_english_spanish.destination_client.id])
      end
    end
  end

  context 'when evaluating enrollment-based policies' do
    include_context 'with enrolled test clients'

    describe 'project-type-based filtering' do
      describe 'when requiring ANY open enrollment to be in a CE (14) project' do
        # Requirement: must have open enrollment in Coordinated Entry (14) project type
        let(:requirement_expression) { 'ANY(open_enrollment_project_types, project_type, project_type = 14)' }

        it 'includes clients with open enrollments at the correct project type' do
          results = generate_candidates(pool, clients)
          expect(results.map(&:client_id).sort).to eq([client_enrolled_in_ce_and_es.destination_client.id].sort)
        end

        it 'excludes clients with exited enrollments at the correct project type' do
          results = generate_candidates(pool, clients)
          expect(results.map(&:client_id)).not_to include(client_exited_from_ce.destination_client.id)
        end

        it 'excludes clients with no enrollments' do
          results = generate_candidates(pool, clients)
          expect(results.map(&:client_id)).not_to include(client_unenrolled.destination_client.id)
        end

        it 'excludes clients that are only enrolled in projects of other types' do
          results = generate_candidates(pool, clients)
          expect(results.map(&:client_id)).not_to include(client_enrolled_in_es.destination_client.id)
        end
      end

      describe 'when requiring ALL open enrollments to not be in PH project types' do
        # Requirement: must NOT have open enrollment in any Permanent Housing project (3, 9, 10, 13)
        let(:requirement_expression) { 'ALL(open_enrollment_project_types, project_type, project_type != 3 AND project_type != 9 AND project_type != 10 AND project_type != 13)' }

        it 'excludes client with open enrollment in PH ' do
          results = generate_candidates(pool, clients)
          expect(results.map(&:client_id).sort).to eq(clients_not_enrolled_in_ph.map { |c| c.destination_client.id }.sort)
          expect(results.map(&:client_id)).not_to include(client_enrolled_in_ph.destination_client.id)
        end
      end
    end

    # TODO add spec for open_referral_project_types filtering
  end
end

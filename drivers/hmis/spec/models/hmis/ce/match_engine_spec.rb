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

  def generate_candidates(pool, clients: nil)
    described_class.call(pool, clients: clients)
    candidates = pool.candidates
    # return results mapped to client IDs for easier comparison
    candidates.map do |candidate|
      candidate.client_proxy.client_id
    end.sort
  end

  def destination_clients_for(clients)
    # NOTE: GrdaWarehouse::Tasks::IdentifyDuplicates must be run before this method is called.
    # get the GrdaWarehouse::Hud::Client destination client for each source client
    GrdaWarehouse::Hud::Client.where(id: clients.map(&:destination_client).compact.map(&:id))
  end

  shared_context 'with demographic test clients' do
    let!(:client_adult_non_veteran) { create(:hmis_hud_client, last_name: 'AdultNonVeteran', veteran_status: 0, dob: 20.years.ago) }
    let!(:client_minor_non_veteran) { create(:hmis_hud_client, last_name: 'MinorNonVeteran', veteran_status: 0, dob: 10.years.ago) }
    let!(:client_adult_veteran) { create(:hmis_hud_client, last_name: 'AdultVeteran', veteran_status: 1, dob: 20.years.ago) }
    let!(:client_senior_veteran) { create(:hmis_hud_client, last_name: 'SeniorVeteran', veteran_status: 1, dob: 68.years.ago) }

    let(:clients) { [client_adult_non_veteran, client_minor_non_veteran, client_adult_veteran, client_senior_veteran] }
    let(:destination_clients) { destination_clients_for(clients) }

    let(:adult_clients) { destination_clients.where.not(id: client_minor_non_veteran.destination_client.id) }

    before { GrdaWarehouse::Tasks::IdentifyDuplicates.new.run! }
  end

  shared_context 'with enrolled test clients' do
    let(:es_project) { create(:hmis_hud_project, data_source: data_source, project_type: 1) }
    let(:ce_project) { create(:hmis_hud_project, data_source: data_source, project_type: 14) }
    let(:ph_project) { create(:hmis_hud_project, data_source: data_source, project_type: 9) }
    let!(:client_enrolled_in_ce) do
      client = create(:hmis_hud_client, last_name: 'EnrolledInCE', data_source: data_source)
      create(:hmis_hud_enrollment, data_source: data_source, project: ce_project, exit_date: nil, client: client)
      create(:hmis_hud_enrollment, data_source: data_source, project: es_project, exit_date: nil, client: client) # cruft: ES enrollment
      client
    end
    let!(:client_wip_enrolled_in_ce) do
      client = create(:hmis_hud_client, last_name: 'WipEnrolledInCE', data_source: data_source)
      create(:hmis_hud_wip_enrollment, data_source: data_source, project: ce_project, exit_date: nil, client: client)
      client
    end
    let!(:client_enrolled_in_es) do
      client = create(:hmis_hud_client, last_name: 'EnrolledInES', data_source: data_source)
      create(:hmis_hud_enrollment, data_source: data_source, project: es_project, exit_date: nil, client: client)
      client
    end
    let!(:client_enrolled_in_ph) do
      client = create(:hmis_hud_client, last_name: 'EnrolledInPH', data_source: data_source)
      create(:hmis_hud_enrollment, data_source: data_source, project: ph_project, exit_date: nil, client: client)
      client
    end
    let!(:client_exited_from_ce) do
      client = create(:hmis_hud_client, last_name: 'ExitedFromCE', data_source: data_source)
      create(:hmis_hud_enrollment, data_source: data_source, project: ce_project, exit_date: 1.week.ago, client: client)
      client
    end
    let!(:client_unenrolled) { create(:hmis_hud_client, last_name: 'Unenrolled', data_source: data_source) }

    let!(:all_clients) do
      [client_enrolled_in_ce, client_wip_enrolled_in_ce, client_enrolled_in_es, client_enrolled_in_ph, client_exited_from_ce, client_unenrolled]
    end

    let(:clients) { Hmis::Hud::Client.where(id: all_clients.map(&:id)) }
    let(:destination_clients) { destination_clients_for(clients) }
    let(:clients_not_enrolled_in_ph) { clients.where.not(id: client_enrolled_in_ph.id) }

    before { GrdaWarehouse::Tasks::IdentifyDuplicates.new.run! }
  end

  shared_context 'with referred test clients' do
    let(:ph_project) { create(:hmis_hud_project, data_source: data_source, project_type: 9) }
    let(:es_project) { create(:hmis_hud_project, data_source: data_source, project_type: 1) }
    let!(:client_referred_to_ph) do
      client = create(:hmis_hud_client, last_name: 'ReferredToPH', data_source: data_source, with_enrollment_at: es_project)
      create(:hmis_ce_referral, data_source: data_source, project: ph_project, client: client, status: 'in_progress')
      create(:hmis_ce_referral, data_source: data_source, project: es_project, client: client, status: 'in_progress') # additional referral to ES
      client
    end
    let!(:client_referred_to_es) do
      client = create(:hmis_hud_client, last_name: 'ReferredToES', data_source: data_source, with_enrollment_at: es_project)
      create(:hmis_ce_referral, data_source: data_source, project: es_project, client: client, status: 'in_progress')
      client
    end
    let!(:client_previously_referred_to_ph) do
      client = create(:hmis_hud_client, last_name: 'PreviouslyReferredToPH', data_source: data_source, with_enrollment_at: es_project)
      create(:hmis_ce_referral, data_source: data_source, project: ph_project, client: client, status: 'rejected') # previous referral, should be ignored
      create(:hmis_ce_referral, data_source: data_source, project: es_project, client: client, status: 'in_progress') # additional referral to ES
      client
    end

    let!(:all_clients) do
      [client_referred_to_ph, client_previously_referred_to_ph, client_referred_to_es]
    end

    let(:clients) { Hmis::Hud::Client.where(id: all_clients.map(&:id)) }
    let(:destination_clients) { destination_clients_for(clients) }
    let(:clients_not_referred_to_ph) { clients.where.not(id: client_referred_to_ph.id) }

    before { GrdaWarehouse::Tasks::IdentifyDuplicates.new.run! }
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
      assessment = create(:hmis_custom_assessment, data_source: data_source, enrollment: enrollment, client: client, definition: fd)

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
        results = generate_candidates(pool)
        expect(results).to be_empty
      end
    end

    describe 'policy that always matches' do
      let(:requirement_expression) { '1=1' }

      it 'returns all candidates' do
        results = generate_candidates(pool)
        expect(results).to eq(destination_clients.map(&:id).sort)
      end
    end

    describe 'age-based filtering' do
      let(:requirement_expression) { 'current_age > 18' }

      it 'excludes minors from candidates' do
        results = generate_candidates(pool)
        expect(results).to eq(adult_clients.map(&:id).sort)
      end
    end

    describe 'combined age and veteran status filtering' do
      let(:requirement_expression) { 'current_age >= 65 AND veteran_status = 1' }

      it 'only includes senior veterans' do
        results = generate_candidates(pool)
        expect(results).to eq([client_senior_veteran.destination_client.id])
      end

      it 'updates the candidates_generated_at timestamp' do
        freeze_time do
          expect do
            generate_candidates(pool)
          end.to change(pool, :candidates_generated_at).from(nil).to(Time.current)
        end
      end
    end

    describe 'with missing demographic data' do
      let!(:client_with_missing_dob) { create(:hmis_hud_client, last_name: 'MissingDob', veteran_status: 1, dob: nil) }
      let!(:client_with_missing_veteran_status) { create(:hmis_hud_client, last_name: 'MissingVeteranStatus', veteran_status: nil, dob: 20.years.ago) }

      let(:clients_with_missing_data) do
        GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
        GrdaWarehouse::Hud::Client.where(id: destination_clients.map(&:id) + [client_with_missing_dob.destination_client.id, client_with_missing_veteran_status.destination_client.id])
      end

      context 'when expression requires age' do
        let(:requirement_expression) { 'current_age > 18' }

        it 'excludes clients with missing DOB' do
          results = generate_candidates(pool, clients: clients_with_missing_data)

          expected_dest_client_ids = [
            client_adult_non_veteran.destination_client.id,
            client_adult_veteran.destination_client.id,
            client_senior_veteran.destination_client.id,
            client_with_missing_veteran_status.destination_client.id,
          ]

          expect(results).to eq(expected_dest_client_ids.sort)
        end
      end

      context 'when expression requires veteran status' do
        let(:requirement_expression) { 'veteran_status = 1' }

        it 'excludes clients with missing veteran status' do
          results = generate_candidates(pool, clients: clients_with_missing_data)

          expected_dest_client_ids = [
            client_adult_veteran.destination_client.id,
            client_senior_veteran.destination_client.id,
            client_with_missing_dob.destination_client.id,
          ]

          expect(results).to eq(expected_dest_client_ids.sort)
        end
      end
    end
  end

  context 'when evaluating single-valued CDE policies' do
    include_context 'with CDE assessment setup'

    let(:cde_key) { 'hat_client_interested_in_ph' }
    let!(:client_interested_in_ph) { create(:hmis_hud_client, last_name: 'InterestedInPH', data_source: data_source) }
    let!(:client_not_interested_in_ph) { create(:hmis_hud_client, last_name: 'NotInterestedInPH', data_source: data_source) }
    let(:destination_clients) { destination_clients_for([client_interested_in_ph, client_not_interested_in_ph]) }

    before do
      create_assessment_with_cde(client_interested_in_ph, '1')
      create_assessment_with_cde(client_not_interested_in_ph, '0')
      GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
    end

    describe 'CDE field matching' do
      let(:requirement_expression) { "`cde.custom_assessment.hat_client_interested_in_ph` = '1'" }

      it 'filters based on CDE value' do
        results = generate_candidates(pool)
        expect(results).to eq([client_interested_in_ph.destination_client.id])
      end
    end
  end

  context 'when evaluating multi-valued CDE policies' do
    include_context 'with CDE assessment setup'

    let(:cde_key) { 'primary_languages' }
    let(:multi_valued_cde) { true }
    let!(:client_english_spanish) { create(:hmis_hud_client, last_name: 'EnglishSpanish', data_source: data_source) }
    let!(:client_french_only) { create(:hmis_hud_client, last_name: 'FrenchOnly', data_source: data_source) }

    before do
      create_assessment_with_cde(client_english_spanish, ['English', 'Spanish'])
      create_assessment_with_cde(client_french_only, 'French')
      GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
    end

    describe 'multi-valued CDE inclusion matching' do
      let(:requirement_expression) { "INCLUDES(`cde.custom_assessment.primary_languages`, 'English')" }

      it 'matches clients with the specified language among multiple values' do
        results = generate_candidates(pool)
        expect(results).to eq([client_english_spanish.destination_client.id])
      end
    end

    describe 'multi-valued CDE exclusion matching' do
      let(:requirement_expression) { "EXCLUDES(`cde.custom_assessment.primary_languages`, 'French')" }

      it 'excludes clients who have the specified language' do
        results = generate_candidates(pool)
        expect(results).to eq([client_english_spanish.destination_client.id])
      end
    end
  end

  context 'when evaluating enrollment-based policies' do
    include_context 'with enrolled test clients'

    describe 'project-type-based filtering' do
      describe 'when requiring open enrollment in a CE (14) project' do
        # Requirement: must have open enrollment in Coordinated Entry (14) project type
        let(:requirement_expression) { 'INCLUDES(open_enrollment_project_types, PROJECT_TYPE("CE"))' }

        it 'includes clients with open enrollments at the correct project type' do
          results = generate_candidates(pool)
          expected_clients = [client_enrolled_in_ce, client_wip_enrolled_in_ce]
          expect(results.sort).to eq(expected_clients.map { |c| c.destination_client.id }.sort)
        end

        it 'excludes clients with exited enrollments at the correct project type' do
          results = generate_candidates(pool)
          expect(results).not_to include(client_exited_from_ce.destination_client.id)
        end

        it 'excludes clients with no enrollments' do
          results = generate_candidates(pool)
          expect(results).not_to include(client_unenrolled.destination_client.id)
        end

        it 'excludes clients that are only enrolled in projects of other types' do
          results = generate_candidates(pool)
          expect(results).not_to include(client_enrolled_in_es.destination_client.id)
        end
      end

      describe 'when requiring open enrollment in a CE (14) project, excluding WIP enrollments' do
        # Requirement: must have open enrollment in Coordinated Entry (14) project type, excluding WIP enrollments
        let(:requirement_expression) { 'INCLUDES(open_enrollment_project_types_excluding_incomplete, PROJECT_TYPE("CE"))' }

        it 'excludes clients with WIP (incomplete) enrollments at the project type' do
          results = generate_candidates(pool)
          expect(results).not_to include(client_wip_enrolled_in_ce.destination_client.id)
        end

        it 'includes clients with open enrollments at the correct project type' do
          results = generate_candidates(pool)
          expect(results.sort).to eq([client_enrolled_in_ce.destination_client.id])
        end
      end

      describe 'when requiring no open enrollments in PH project types' do
        # Requirement: must NOT have open enrollment in any Permanent Housing project (3, 9, 10, 13)
        let(:requirement_expression) { 'EXCLUDES(open_enrollment_project_types, PROJECT_TYPE("PH_PSH")) AND EXCLUDES(open_enrollment_project_types, PROJECT_TYPE("PH_PH")) AND EXCLUDES(open_enrollment_project_types, PROJECT_TYPE("PH_OPH")) AND EXCLUDES(open_enrollment_project_types, PROJECT_TYPE("PH_RRH"))' }

        it 'excludes client with open enrollment in PH ' do
          results = generate_candidates(pool)
          expect(results.sort).to eq(clients_not_enrolled_in_ph.map { |c| c.destination_client.id }.sort)
          expect(results).not_to include(client_enrolled_in_ph.destination_client.id)
        end
      end
    end
  end

  context 'when evaluating referral-based policies' do
    include_context 'with referred test clients'
    before { GrdaWarehouse::Tasks::IdentifyDuplicates.new.run! }

    describe 'project-type-based filtering' do
      describe 'when requiring no open referral in a PH (9) project' do
        let(:requirement_expression) { 'EXCLUDES(open_referral_project_types, PROJECT_TYPE("PH_PH"))' }

        it 'excludes clients with open referrals to PH (9) projects' do
          results = generate_candidates(pool)
          expect(results).not_to include(client_referred_to_ph.destination_client.id)
        end
        it 'includes clients without open referrals to PH (9) projects' do
          results = generate_candidates(pool)
          expect(results).to eq(clients_not_referred_to_ph.map { |c| c.destination_client.id })
        end
      end
    end
  end

  context 'when destination client has multiple source clients' do
    def create_client_and_deduplicate
      client = create(:hmis_hud_client, personal_id: '100', data_source: data_source, first_name: 'Margaret', last_name: 'Blue', dob: '1999-12-01', ssn: '123-45-6789')
      # Run deduplication after each client creation to ensure that duplicates are correctly recognized
      GrdaWarehouse::Tasks::IdentifyDuplicates.new.run!
      client
    end

    let!(:source_1) { create_client_and_deduplicate }
    let!(:source_2) { create_client_and_deduplicate }
    let(:destination_clients) { destination_clients_for([source_1, source_2]) }

    it 'deduplicates on the waitlist' do
      expect(destination_clients.count).to eq(1)
      results = generate_candidates(pool)
      expect(results.size).to eq(1)
      expect(results.sole).to eq(destination_clients.sole.id)
    end
  end

  describe 'incremental mode' do
    include_context 'with demographic test clients'

    let(:destination_clients) { destination_clients_for([client_adult_non_veteran, client_adult_veteran, client_minor_non_veteran]) }
    let(:pool) { create(:hmis_ce_match_candidate_pool, requirement_expression: requirement_expression) }

    context 'when client no longer passes SQL filter' do
      let(:requirement_expression) { 'current_age > 18' }

      it 'removes candidate for client who no longer meets age requirement' do
        # Initial state: adult client meets requirement
        adult_client = destination_clients.find { |c| c.id == client_adult_non_veteran.destination_client.id }

        # Generate initial candidates using full refresh mode
        initial_results = generate_candidates(pool)
        expect(initial_results).to include(adult_client.id)

        # Change the client's age to be under 18 (simulate data change)
        adult_client.update!(DOB: 10.years.ago)

        # Run incremental processing on just this client
        generate_candidates(pool, clients: GrdaWarehouse::Hud::Client.where(id: adult_client.id))

        # Verify the candidate was actually removed from the pool
        all_candidates = pool.candidates.joins(:client_proxy).pluck('ce_client_proxies.client_id')
        expect(all_candidates).not_to include(adult_client.id)
      end
    end

    context 'when client now passes requirements' do
      let(:requirement_expression) { 'current_age > 18' }

      it 'adds candidate for client who now meets requirements' do
        # Initial state: minor client does not meet requirement
        minor_client = destination_clients.find { |c| c.id == client_minor_non_veteran.destination_client.id }

        # Generate initial candidates using full refresh mode
        initial_results = generate_candidates(pool)
        expect(initial_results).not_to include(minor_client.id)

        # Change the client's age to be over 18 (simulate data change)
        minor_client.update!(DOB: 20.years.ago)

        # Run incremental processing on just this client
        generate_candidates(pool, clients: GrdaWarehouse::Hud::Client.where(id: minor_client.id))

        # Verify the candidate was actually added to the pool
        all_candidates = pool.candidates.joins(:client_proxy).pluck('ce_client_proxies.client_id')
        expect(all_candidates).to include(minor_client.id)
      end
    end

    context 'when processing multiple clients incrementally' do
      let(:requirement_expression) { 'current_age > 18' }

      it 'processing subset of clients does not remove candidates for unprocessed clients' do
        # Generate initial candidates by processing all our test clients (this will be incremental mode)
        generate_candidates(pool, clients: destination_clients)
        adult_client = destination_clients.find { |c| c.id == client_adult_non_veteran.destination_client.id }
        veteran_client = destination_clients.find { |c| c.id == client_adult_veteran.destination_client.id }

        # Verify both clients have candidates initially
        all_candidates_before = pool.candidates.joins(:client_proxy).pluck('ce_client_proxies.client_id')
        expect(all_candidates_before).to include(adult_client.id, veteran_client.id)

        # Process only one client incrementally (without changing their data - they should still be eligible)
        generate_candidates(pool, clients: GrdaWarehouse::Hud::Client.where(id: adult_client.id))

        # Both clients should still have candidates - the unprocessed client's candidate should NOT be removed
        all_candidates_after = pool.candidates.joins(:client_proxy).pluck('ce_client_proxies.client_id')
        expect(all_candidates_after).to include(adult_client.id, veteran_client.id)
      end
    end
  end

  describe 'candidate event logging' do
    include_context 'with demographic test clients'

    let(:requirement_expression) { 'current_age > 18' }
    let(:priority_expression) { 'current_age' }
    let(:pool) { create(:hmis_ce_match_candidate_pool, requirement_expression: requirement_expression, priority_expression: priority_expression) }

    def find_events_for_client(client_id)
      proxy = Hmis::Ce::ClientProxy.for_warehouse_clients.find_by!(client_id: client_id)

      Hmis::Ce::Match::CandidateEvent.where(candidate_pool: pool, client_proxy: proxy).order(:created_at)
    end

    context 'when adding new candidates' do
      it 'creates add events for newly eligible clients' do
        adult_client = destination_clients.find { |c| c.id == client_adult_non_veteran.destination_client.id }

        expect do
          generate_candidates(pool)
        end.to(change { Hmis::Ce::Match::CandidateEvent.count })

        events = find_events_for_client(adult_client.id)
        expect(events.size).to eq(1)
        expect(events.first).to have_attributes(
          event_name: 'add',
          candidate_pool: pool,
        )
        expect(events.first.snapshot).to include('current_age' => 20)
      end
    end

    context 'when updating existing candidates' do
      it 'creates update events with new snapshot when client data changes but they remain eligible' do
        adult_client = destination_clients.find { |c| c.id == client_adult_non_veteran.destination_client.id }
        generate_candidates(pool) # Initial run
        expect(adult_client.ce_client_proxy.ce_match_candidates.first.priority_score).to eq(adult_client.age)

        # Change data that affects priority score but not eligibility
        adult_client.update!(DOB: 30.years.ago) # current_age changes from 20 to 30
        generate_candidates(pool, clients: GrdaWarehouse::Hud::Client.where(id: adult_client.id))

        events = find_events_for_client(adult_client.id)
        expect(events.last).to have_attributes(
          event_name: 'update',
          candidate_pool: pool,
        )
        expect(events.last.snapshot).to include('current_age' => 30)
        expect(adult_client.ce_client_proxy.ce_match_candidates.first.priority_score).to eq(30)
      end
    end

    context 'when removing candidates' do
      it 'creates remove events for clients who no longer meet requirements' do
        adult_client = destination_clients.find { |c| c.id == client_adult_non_veteran.destination_client.id }

        # First run - client is eligible
        generate_candidates(pool)
        initial_events = find_events_for_client(adult_client.id)
        expect(initial_events.last.event_name).to eq('add')

        # Change client to no longer meet requirements
        adult_client.update!(DOB: 10.years.ago)

        # Second run - client should be removed
        generate_candidates(pool, clients: GrdaWarehouse::Hud::Client.where(id: adult_client.id))

        events = find_events_for_client(adult_client.id)
        expect(events.last).to have_attributes(
          event_name: 'remove',
          candidate_pool: pool,
        )
        expect(events.last.snapshot).to include('current_age' => 10)
      end
    end

    context 'when client fails priority evaluation' do
      let(:priority_expression) { 'IF(current_age > 18, current_age, NULL)' }

      it 'creates remove events for clients with nil priority scores' do
        adult_client = destination_clients.find { |c| c.id == client_adult_non_veteran.destination_client.id }
        generate_candidates(pool, clients: GrdaWarehouse::Hud::Client.where(id: adult_client.id))
        adult_client.update!(DOB: 10.years.ago)

        # Process client - should be excluded due to nil priority score
        generate_candidates(pool, clients: GrdaWarehouse::Hud::Client.where(id: adult_client.id))

        # Should not be in candidates since priority is nil
        all_candidates = pool.candidates.joins(:client_proxy).pluck('ce_client_proxies.client_id')
        expect(all_candidates).not_to include(adult_client.id)

        # Should have a remove event logged
        events = find_events_for_client(adult_client.id)
        expect(events.size).to eq(2)
        expect(events.first).to have_attributes(
          event_name: 'add',
          candidate_pool: pool,
        )
        expect(events.last).to have_attributes(
          event_name: 'remove',
          candidate_pool: pool,
        )
      end
    end

    context 'when processing in full refresh mode' do
      it 'creates events for all eligible clients' do
        expect do
          generate_candidates(pool)
        end.to change { Hmis::Ce::Match::CandidateEvent.count }.by(3) # 3 adult clients

        # Verify each adult client has an add event
        adult_clients.each do |client|
          events = find_events_for_client(client.id)
          expect(events.size).to eq(1)
          expect(events.first.event_name).to eq('add')
        end
      end
    end

    context 'event snapshot content' do
      let(:priority_expression) { 'current_age + veteran_status' }

      it 'includes relevant field values in the snapshot' do
        veteran_client = destination_clients.find { |c| c.id == client_adult_veteran.destination_client.id }

        generate_candidates(pool)

        events = find_events_for_client(veteran_client.id)
        snapshot = events.first.snapshot

        expect(snapshot).to include(
          'current_age' => 20,
          'veteran_status' => 1,
        )
      end
    end
  end
end

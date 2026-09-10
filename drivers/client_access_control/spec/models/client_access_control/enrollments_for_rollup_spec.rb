###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'shared_contexts/enrollment_rollup_context'

RSpec.describe 'GrdaWarehouse::Hud::Client#enrollments_for_rollup', type: :model do
  include_context 'enrollment rollup context'

  def residential_rollup(client)
    client.enrollments_for_rollup(
      user: user,
      en_scope: client.scope_for_residential_enrollments(user),
      include_confidential_names: false,
    )
  end

  describe 'residential rollup values' do
    let(:rollup) { residential_rollup(destination_client) }
    let(:by_name) { rollup.index_by { |e| e[:project_name] } }

    it 'orders enrollments by entry date descending' do
      expect(rollup.map { |e| e[:project_name] }).to eq(['Housing < Test Org ', 'Shelter B < Test Org ', 'Shelter A < Test Org '])
    end

    it 'counts served, adjusted, and homeless days per enrollment' do
      expect(by_name['Shelter A < Test Org ']).to include(days: 10, adjusted_days: 6, homeless_days: 6, homeless: true, residential: true)
      expect(by_name['Shelter B < Test Org ']).to include(days: 14, adjusted_days: 14, homeless_days: 13, homeless: true, residential: true)
      expect(by_name['Housing < Test Org ']).to include(days: 17, adjusted_days: 17, homeless_days: 4, homeless: false, residential: true)
    end

    it 'reports entry, exit, move-in, and most recent service dates' do
      expect(by_name['Shelter A < Test Org ']).to include(
        entry_date: Date.new(2021, 1, 1),
        exit_date: Date.new(2021, 1, 11),
        most_recent_service: Date.new(2021, 1, 10),
        move_in_date: nil,
        move_in_date_inherited: false,
        destination: 10,
      )
      expect(by_name['Housing < Test Org ']).to include(
        entry_date: Date.new(2021, 1, 15),
        exit_date: Date.new(2021, 2, 1),
        most_recent_service: Date.new(2021, 1, 31),
        move_in_date: Date.new(2021, 1, 18),
        move_in_date_inherited: false,
      )
    end

    it 'marks only the first shelter stay as a new episode' do
      expect(rollup.map { |e| [e[:project_name], e[:new_episode]] }).to contain_exactly(
        ['Housing < Test Org ', false],
        ['Shelter B < Test Org ', false],
        ['Shelter A < Test Org ', true],
      )
    end

    it 'returns months served as year/month pairs' do
      expect(by_name['Shelter A < Test Org '][:months_served]).to match_array([[2021, 1]])
      expect(by_name['Housing < Test Org '][:months_served]).to match_array([[2021, 1]])
    end

    it 'does not flag chronic homelessness when the disabling condition is no' do
      expect(rollup.map { |e| [e[:chronically_homeless_at_start], e[:chronically_homeless_at_most_recent]] }.uniq).to eq([[false, false]])
    end

    it 'lists other household members with their entry dates' do
      household = by_name['Shelter A < Test Org '][:household]
      expect(household.size).to eq(1)
      expect(household.first).to include(
        'FirstName' => 'Mia',
        'LastName' => 'Member',
        'client_id' => household_member_destination.id,
        'head_of_household' => false,
        'first_date_in_program' => Date.new(2021, 1, 1),
        'last_date_in_program' => Date.new(2021, 1, 11),
      )
      expect(by_name['Shelter B < Test Org '][:household]).to be_nil
    end

    it 'carries identifiers the view links on' do
      expect(by_name['Shelter A < Test Org ']).to include(
        project_id: shelter_a.id,
        ProjectID: shelter_a.ProjectID,
        project_type_id: 0,
        client_source_id: source_client.id,
        enrollment_id: shelter_a_enrollment.EnrollmentID,
        hmis_id: shelter_a_enrollment.id,
        hmis_exit_id: shelter_a_enrollment.exit.id,
        data_source_id: data_source.id,
        confidential_project: false,
        total_enrollment_count: 3,
        visible_enrollment_count: 3,
      )
    end
  end

  describe 'visibility counts' do
    let!(:hidden_data_source) { create :non_window_data_source }
    let!(:hidden_project) { create :hud_project, data_source_id: hidden_data_source.id, ProjectName: 'Hidden', ProjectType: 0 }
    let!(:hidden_source_client) do
      source = create(:hud_client, data_source_id: hidden_data_source.id, FirstName: 'Sam', LastName: 'Hidden')
      create(:warehouse_client, destination_id: destination_client.id, source_id: source.id, data_source_id: hidden_data_source.id, id_in_source: source.PersonalID)
      source
    end
    let!(:hidden_enrollment) do
      create(
        :hud_enrollment,
        data_source_id: hidden_data_source.id,
        PersonalID: hidden_source_client.PersonalID,
        ProjectID: hidden_project.ProjectID,
        EntryDate: Date.new(2019, 1, 1),
        DisablingCondition: 0,
      )
    end

    before { rebuild_service_history! }

    it 'excludes enrollments the user cannot see but counts them in the total' do
      rollup = residential_rollup(destination_client)
      expect(rollup.map { |e| e[:project_name] }).not_to include('Hidden < Test Org ')
      expect(rollup.first).to include(total_enrollment_count: 4, visible_enrollment_count: 3)
    end
  end

  describe 'only_ongoing' do
    it 'drops exited enrollments' do
      rollup = destination_client.enrollments_for_rollup(
        user: user,
        en_scope: destination_client.scope_for_residential_enrollments(user),
        only_ongoing: true,
      )
      expect(rollup).to eq([])
    end
  end

  describe 'query scaling' do
    it 'issues the same number of queries for two enrollments as for eight' do
      few = build_client_with_es_enrollments(count: 2)
      many = build_client_with_es_enrollments(count: 8)
      # Warm class-level caches (HudHelper, service_types) and each client's memoized
      # household index (GrdaWarehouse::Hud::Client#households) so neither block pays
      # a one-time cost the other one doesn't.
      residential_rollup(few)
      residential_rollup(many)

      few_queries = count_database_queries { residential_rollup(few) }
      many_queries = count_database_queries { residential_rollup(many) }

      expect(residential_rollup(many).size).to eq(8)
      expect(many_queries).to eq(few_queries)
    end
  end
end

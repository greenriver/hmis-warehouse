###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cohorts::CopyController, type: :request do
  let!(:cohort_a) { create(:cohort, name: 'Cohort A') }
  let!(:cohort_b) { create(:cohort, name: 'Cohort B') }

  def role_with(*permissions)
    create(:role, **permissions.index_with { true })
  end

  def grant_acl(user, permissions, *records)
    collection = create(:collection)
    collection.set_viewables({ cohorts: records.map(&:id) })
    setup_access_control(user, role_with(*permissions), collection)
  end

  def grant_legacy(user, permissions, *records)
    access_group = create(:access_group)
    role_with(*permissions).add(user)
    access_group.add(user)
    records.each { |record| access_group.add_viewable(record) }
  end

  def refused?
    response.redirect? && !response.location.include?('/cohorts/')
  end

  before do
    Collection.maintain_system_groups
    [cohort_a, cohort_b].each { |cohort| cohort.update!(column_state: GrdaWarehouse::Cohort.available_columns) }
    sign_in user
  end

  shared_examples 'per-cohort copy authorization' do
    it 'refuses new and create on a cohort without add-clients' do
      grant(user, [:can_view_cohorts, :can_participate_in_cohorts, :can_add_cohort_clients], cohort_a)
      grant_view_only(user, cohort_b)

      get new_cohort_copy_path(cohort_b)
      expect(refused?).to be(true)

      expect do
        post cohort_copy_path(cohort_b), params: { copy: { cohort_id: cohort_a.id, columns: ['rank'] } }
      end.not_to change(cohort_b.cohort_clients, :count)
      expect(refused?).to be(true)
    end

    it 'allows new where add-clients was granted without participate' do
      grant(user, [:can_view_cohorts, :can_add_cohort_clients], cohort_a)

      get new_cohort_copy_path(cohort_a)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(cohort_a.name)
    end

    it 'refuses new for a participant without add-clients' do
      grant(user, [:can_view_cohorts, :can_participate_in_cohorts], cohort_a)

      get new_cohort_copy_path(cohort_a)

      expect(refused?).to be(true)
    end

    it 'returns not found for a cohort that does not exist' do
      grant(user, [:can_view_cohorts, :can_add_cohort_clients], cohort_a)

      get new_cohort_copy_path(GrdaWarehouse::Cohort.maximum(:id) + 1)

      expect(response).to have_http_status(:not_found)
    end
  end

  shared_examples 'copy behavior' do
    let!(:client) { create(:grda_warehouse_hud_client) }
    let!(:source_row) { GrdaWarehouse::CohortClient.create!(cohort: cohort_b, client: client, user_string_1: 'from source', user_string_2: 'source two') }
    let!(:destination_row) { GrdaWarehouse::CohortClient.create!(cohort: cohort_a, client: client, user_string_1: 'old', user_string_2: 'dest two') }
    let(:editable_title) { CohortColumns::UserString1.new.title }
    let(:locked_title) { CohortColumns::UserString2.new.title }

    before do
      [cohort_a, cohort_b].each { |cohort| GrdaWarehouse::CohortTab.default_rules.each { |rule| cohort.cohort_tabs.create!(**rule) } }
      cohort_a.update!(column_state: [CohortColumns::UserString1.new, CohortColumns::UserString2.new(editable: false)])
      cohort_b.update!(column_state: [CohortColumns::UserString1.new, CohortColumns::UserString2.new])
    end

    def grant_copy_access
      grant(user, [:can_view_cohorts, :can_participate_in_cohorts, :can_add_cohort_clients], cohort_a)
      grant(user, [:can_view_cohorts], cohort_b)
    end

    def destination_values
      destination_row.reload.attributes.slice('user_string_1', 'user_string_2')
    end

    it 'copies the chosen column and redirects to the cohort' do
      grant_copy_access

      post cohort_copy_path(cohort_a), params: { copy: { cohort_id: cohort_b.id, columns: ['user_string_1'] } }

      expect(response).to redirect_to(cohort_path(cohort_a))
      expect(destination_values).to eq('user_string_1' => 'from source', 'user_string_2' => 'dest two')
    end

    it 'returns not found for a source the user cannot view and changes nothing' do
      hidden = create(:cohort, name: 'Hidden Source')
      grant_copy_access

      post cohort_copy_path(cohort_a), params: { copy: { cohort_id: hidden.id, columns: ['user_string_1'] } }

      expect(response).to have_http_status(:not_found)
      expect(destination_values).to eq('user_string_1' => 'old', 'user_string_2' => 'dest two')
    end

    it 'lists the viewable cohorts except the destination' do
      hidden = create(:cohort, name: 'Hidden Source')
      grant_copy_access

      get new_cohort_copy_path(cohort_a)

      expect(response.body).to include(cohort_b.name)
      expect(response.body).not_to include(hidden.name)
    end

    it 'lists only the columns the user can edit in the destination' do
      grant_copy_access

      get new_cohort_copy_path(cohort_a)

      expect(response.body).to include(editable_title)
      expect(response.body).not_to include(locked_title)
    end

    it 're-renders new with a message on self-copy and changes nothing' do
      grant_copy_access

      post cohort_copy_path(cohort_a), params: { copy: { cohort_id: cohort_a.id, columns: ['user_string_1'] } }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Choose a different cohort to copy from.')
      expect(destination_values).to eq('user_string_1' => 'old', 'user_string_2' => 'dest two')
    end

    it 'requires a source and at least one allowed column' do
      grant_copy_access

      post cohort_copy_path(cohort_a), params: { copy: { cohort_id: cohort_b.id, columns: ['user_string_2'] } }
      expect(response.body).to include('All fields are required.')

      post cohort_copy_path(cohort_a), params: { copy: { cohort_id: '', columns: ['user_string_1'] } }
      expect(response.body).to include('All fields are required.')
      expect(destination_values).to eq('user_string_1' => 'old', 'user_string_2' => 'dest two')
    end

    it 're-renders new for a non-scalar cohort id' do
      grant_copy_access

      post cohort_copy_path(cohort_a), params: { copy: { cohort_id: [cohort_b.id], columns: ['user_string_1'] } }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('All fields are required.')
      expect(destination_values).to eq('user_string_1' => 'old', 'user_string_2' => 'dest two')
    end

    it 're-renders new when copy is a scalar' do
      grant_copy_access

      post cohort_copy_path(cohort_a), params: { copy: 'x' }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('All fields are required.')
    end

    it 'redirects away from new and create on an auto-maintained cohort' do
      grant_copy_access
      cohort_a.update_columns(project_group_id: GrdaWarehouse::ProjectGroup.create!(name: 'Auto Group').id)

      get new_cohort_copy_path(cohort_a)
      expect(response).to redirect_to(cohort_path(cohort_a))

      post cohort_copy_path(cohort_a), params: { copy: { cohort_id: cohort_b.id, columns: ['user_string_1'] } }
      expect(response).to redirect_to(cohort_path(cohort_a))
      expect(destination_values).to eq('user_string_1' => 'old', 'user_string_2' => 'dest two')
    end

    it 'redirects away from new and create on a system cohort' do
      grant_copy_access
      cohort_a.update_columns(system_cohort: true)

      get new_cohort_copy_path(cohort_a)
      expect(response).to redirect_to(cohort_path(cohort_a))

      post cohort_copy_path(cohort_a), params: { copy: { cohort_id: cohort_b.id, columns: ['user_string_1'] } }
      expect(response).to redirect_to(cohort_path(cohort_a))
      expect(destination_values).to eq('user_string_1' => 'old', 'user_string_2' => 'dest two')
    end

    context 'when the user can add clients but edit no columns' do
      before { grant(user, [:can_view_cohorts, :can_add_cohort_clients], cohort_a) }

      it 'shows the no-columns message on new and create' do
        get new_cohort_copy_path(cohort_a)
        expect(response.body).to include("You can't edit any columns in this cohort.")

        post cohort_copy_path(cohort_a), params: { copy: { cohort_id: cohort_b.id, columns: ['user_string_1'] } }
        expect(response.body).to include("You can't edit any columns in this cohort.")
        expect(destination_values).to eq('user_string_1' => 'old', 'user_string_2' => 'dest two')
      end

      it 'hides the Import link on the cohort page' do
        get cohort_path(cohort_a)

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include(new_cohort_copy_path(cohort_a))
      end
    end

    it 'shows the Import link on the cohort page to a user who can edit columns' do
      grant_copy_access

      get cohort_path(cohort_a)

      expect(response.body).to include(new_cohort_copy_path(cohort_a))
    end
  end

  context 'with an ACL user' do
    let(:user) { create(:acl_user) }

    def grant(...) = grant_acl(...)

    def grant_view_only(user, cohort) = grant_acl(user, [:can_view_cohorts], cohort)

    include_examples 'per-cohort copy authorization'
    include_examples 'copy behavior'

    it 'limits new to the cohort in the collection that carries add-clients' do
      grant(user, [:can_view_cohorts, :can_add_cohort_clients], cohort_a)
      grant(user, [:can_view_cohorts], cohort_b)

      get new_cohort_copy_path(cohort_b)

      expect(refused?).to be(true)
    end
  end

  context 'with a legacy user' do
    let(:user) { create(:user) }

    def grant(...) = grant_legacy(...)

    # Legacy roles are user-global, so the second cohort stays outside the user's access group
    def grant_view_only(_user, _cohort)
    end

    include_examples 'per-cohort copy authorization'
    include_examples 'copy behavior'
  end
end

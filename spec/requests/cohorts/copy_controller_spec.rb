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

  context 'with an ACL user' do
    let(:user) { create(:acl_user) }

    def grant(...) = grant_acl(...)

    def grant_view_only(user, cohort) = grant_acl(user, [:can_view_cohorts], cohort)

    include_examples 'per-cohort copy authorization'

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
  end
end

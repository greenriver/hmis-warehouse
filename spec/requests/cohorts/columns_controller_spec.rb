###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cohorts::ColumnsController, type: :request do
  let!(:cohort_a) { create(:cohort, name: 'Cohort A') }
  let!(:cohort_b) { create(:cohort, name: 'Cohort B') }
  let(:original_state) { [CohortColumns::FirstName.new, CohortColumns::Rank.new] }
  let(:update_params) { { column_state: { visible: { 'rank' => '1' }, editable: { 'rank' => '1' } } } }

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
    [cohort_a, cohort_b].each { |cohort| cohort.update!(column_state: original_state) }
    sign_in user
  end

  shared_examples 'per-cohort column editing' do
    it 'refuses edit and update on a cohort without the grant and leaves its columns alone' do
      grant(user, [:can_view_cohorts, :can_edit_cohort_columns], cohort_a)
      state_before = cohort_b.reload.column_state.map { |c| [c.column, c.visible, c.editable] }

      get edit_cohort_columns_path(cohort_b)
      expect(refused?).to be(true)

      patch cohort_columns_path(cohort_b), params: update_params
      expect(refused?).to be(true)
      expect(cohort_b.reload.column_state.map { |c| [c.column, c.visible, c.editable] }).to eq(state_before)
    end

    it 'allows edit and update where the grant was given' do
      grant(user, [:can_view_cohorts, :can_edit_cohort_columns], cohort_a)

      get edit_cohort_columns_path(cohort_a)
      expect(response).to have_http_status(:ok)

      patch cohort_columns_path(cohort_a), params: update_params
      expect(cohort_a.reload.column_state.select(&:visible).map(&:column)).to eq(['rank'])
    end

    it 'refuses a viewer without the edit-columns permission' do
      grant(user, [:can_view_cohorts], cohort_a)

      get edit_cohort_columns_path(cohort_a)

      expect(refused?).to be(true)
    end

    it 'returns not found for a cohort that does not exist' do
      grant(user, [:can_view_cohorts, :can_edit_cohort_columns], cohort_a)

      get edit_cohort_columns_path(GrdaWarehouse::Cohort.maximum(:id) + 1)

      expect(response).to have_http_status(:not_found)
    end
  end

  context 'with an ACL user' do
    let(:user) { create(:acl_user) }

    def grant(...) = grant_acl(...)

    include_examples 'per-cohort column editing'

    it 'limits the permission to the cohort in the collection that carries it' do
      grant(user, [:can_view_cohorts, :can_edit_cohort_columns], cohort_a)
      grant(user, [:can_view_cohorts], cohort_b)

      get edit_cohort_columns_path(cohort_b)

      expect(refused?).to be(true)
    end
  end

  context 'with a legacy user' do
    let(:user) { create(:user) }

    def grant(...) = grant_legacy(...)

    include_examples 'per-cohort column editing'
  end
end

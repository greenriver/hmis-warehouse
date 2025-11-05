# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { create :user }
  let(:agency) { create :agency }

  describe 'validations' do
    context 'if email missing' do
      let(:user) { build :user, email: nil }

      it 'is invalid' do
        expect(user).to be_invalid
      end
    end
  end

  describe '.text_search' do
    let!(:user1) { create(:user, first_name: 'Alice', last_name: 'Smith', email: 'alice.smith@example.com') }
    let!(:user2) { create(:user, first_name: 'Alicea', last_name: 'Smythe', email: 'alicia.smythe@example.com') }
    let!(:user3) { create(:user, first_name: 'Bob', last_name: 'Jones', email: 'bob.jones@example.com') }

    it 'finds users by first name' do
      results = User.text_search('Alice')
      expect(results).to include(user1)
      expect(results).not_to include(user3)
    end

    it 'finds users by last name' do
      results = User.text_search('Jones')
      expect(results).to include(user3)
      expect(results).not_to include(user1)
    end

    it 'finds users by email' do
      results = User.text_search('alice.smith@example.com')
      expect(results).to include(user1)
      expect(results).not_to include(user3)
    end

    it 'returns none for no match' do
      results = User.text_search('Nonexistent')
      expect(results).to be_empty
    end

    it 'orders results by best match when sort_by_best_match is true' do
      results = User.text_search('Alice', sort_by_best_match: true)
      expect(results.first).to eq(user1)
      expect(results).to include(user2)
      expect(results).not_to include(user3)
    end
  end

  describe '#populate_external_reporting_permissions!' do
    subject(:populate_permissions) { user.populate_external_reporting_permissions! }

    let(:user) { create(:user, email: 'reporter@example.com') }
    let(:project_a) { 101 }
    let(:project_b) { 202 }
    let(:project_ids) { [project_a, project_a, project_b] }
    let(:cohort_a) { 303 }
    let(:cohort_ids) { [cohort_a, cohort_a] }
    let(:permissions) do
      [
        :can_view_assigned_reports,
        :can_view_full_ssn,
        :can_view_full_dob,
        :can_view_client_name,
        :can_view_hiv_status,
      ]
    end
    let(:project_scope) { instance_double(ActiveRecord::Relation, pluck: project_ids) }
    let(:cohort_scope) { instance_double(ActiveRecord::Relation, pluck: cohort_ids) }
    let(:project_relation) { instance_double(ActiveRecord::Relation, delete_all: true) }
    let(:cohort_relation) { instance_double(ActiveRecord::Relation, delete_all: true) }
    let(:project_records) { [] }
    let(:cohort_records) { [] }

    before do
      user.access_group.destroy!

      allow(GrdaWarehouse::Hud::Project).to receive(:viewable_by).and_return(project_scope)
      allow(GrdaWarehouse::Cohort).to receive(:viewable_by).with(user).and_return(cohort_scope)

      allow(GrdaWarehouse::ExternalReportingProjectPermission).to receive(:transaction).and_yield
      allow(GrdaWarehouse::ExternalReportingProjectPermission).to receive(:where).with(user_id: user.id).and_return(project_relation)
      allow(GrdaWarehouse::ExternalReportingProjectPermission).to receive(:import) do |records|
        project_records.replace(records)
      end

      allow(GrdaWarehouse::ExternalReportingCohortPermission).to receive(:transaction).and_yield
      allow(GrdaWarehouse::ExternalReportingCohortPermission).to receive(:where).with(user_id: user.id).and_return(cohort_relation)
      allow(GrdaWarehouse::ExternalReportingCohortPermission).to receive(:import) do |records|
        cohort_records.replace(records)
      end
    end

    it 'rebuilds external reporting project and cohort permissions with unique ids' do
      populate_permissions

      permissions.each do |permission|
        expect(GrdaWarehouse::Hud::Project).to have_received(:viewable_by).with(user, permission: permission)
      end

      expected_project_pairs = permissions.product(project_ids.uniq).map do |permission, project_id|
        [project_id, permission.to_s]
      end
      expect(project_records.map { |record| [record.project_id, record.permission] }).to match_array(expected_project_pairs)
      expect(project_relation).to have_received(:delete_all)
      expect(GrdaWarehouse::ExternalReportingProjectPermission).to have_received(:import)
      expect(project_records).to all(have_attributes(user_id: user.id, email: user.email))

      expect(GrdaWarehouse::Cohort).to have_received(:viewable_by).with(user)
      expect(cohort_relation).to have_received(:delete_all)
      expect(GrdaWarehouse::ExternalReportingCohortPermission).to have_received(:import)

      expect(cohort_records.map(&:cohort_id)).to contain_exactly(*cohort_ids.uniq)
      expect(cohort_records).to all(have_attributes(user_id: user.id, email: user.email, permission: 'can_view_cohorts'))
    end
  end

  describe '#all_access_group_ids' do
    context 'when the personal access group is not persisted' do
      it 'excludes nil ids' do
        user.access_group.destroy!
        user.instance_variable_set(:@access_group, nil)

        group = create(:access_group)
        create(:access_group_member, user: user, access_group: group)

        expect(user.all_access_group_ids).to contain_exactly(group.id)
      end
    end
  end
end

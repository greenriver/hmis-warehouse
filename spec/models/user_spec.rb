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

  describe 'invitation handling' do
    context 'when user has an outstanding invitation' do
      before do
        User.invite!({ email: 'unconfirmed@example.com', first_name: 'Unconfirmed', last_name: 'User', agency_id: agency.id }, User.system_user)
        @user = User.last
      end

      describe 'confirming a user' do
        it 'adds an error and returns false' do
          expect(@user.invitation_token).to be_present
          expect(@user.invitation_status).to eq(:pending_confirmation)
          expect(@user.confirm).to be false
          expect(@user.confirmed?).to be false
          expect(@user.errors[:email]).to include('There is an open invitation for this account.')
        end

        it 'Refuses to accept the invitation after the invitation has expired' do
          travel_to(@user.invitation_due_at + 1.weeks) do
            expect do
              User.accept_invitation!(invitation_token: @user.invitation_token)
            end.to not_change(@user, :invitation_status)
          end
        end

        it 'Refuses to confirm email after the invitation has expired' do
          travel_to(@user.invitation_due_at + 1.weeks) do
            expect(@user.invitation_token).to be_present
            expect(@user.invitation_status).to eq(:invitation_expired)
            expect(@user.confirm).to be false
            expect(@user.confirmed?).to be false
            expect(@user.errors[:email]).to include('There is an open invitation for this account.')
          end
        end
      end

      describe 'after accepting the invitation and confirming the user' do
        before do
          @user.accept_invitation!
          @user.confirm
        end

        it 'confirming a user returns true' do
          expect(@user.confirmed?).to be true
        end
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

  describe '#login_to?' do
    context 'when user is a system user' do
      let(:system_user) { create(:user, first_name: 'System', last_name: 'User') }

      it 'returns false for :warehouse' do
        expect(system_user.login_to?(:warehouse)).to be false
      end

      it 'returns false for :hmis' do
        expect(system_user.login_to?(:hmis)).to be false
      end
    end

    context 'when destination is :warehouse' do
      context 'with ACL user (permission_context: acls)' do
        let(:acl_user) { create(:acl_user) }

        it 'returns true when user is in a warehouse UserGroup' do
          user_group = create(:user_group)
          user_group.add(acl_user)

          expect(acl_user.login_to?(:warehouse)).to be true
        end

        it 'returns false when user has no warehouse UserGroup membership' do
          expect(acl_user.login_to?(:warehouse)).to be false
        end
      end

      context 'with legacy/role-based user' do
        it 'returns true even without UserGroup membership' do
          expect(user.login_to?(:warehouse)).to be true
        end
      end
    end

    context 'when destination is :hmis' do
      it 'returns true when user is in an HMIS UserGroup' do
        hmis_user_group = create(:hmis_user_group)
        hmis_user_group.add(user)

        expect(user.login_to?(:hmis)).to be true
      end

      it 'returns false when user has no HMIS UserGroup membership' do
        expect(user.login_to?(:hmis)).to be false
      end
    end

    context 'when destination is unknown' do
      it 'returns false' do
        expect(user.login_to?(:invalid)).to be false
      end

      it 'accepts string and normalizes to symbol' do
        expect(user.login_to?('warehouse')).to eq(user.login_to?(:warehouse))
      end
    end
  end
end

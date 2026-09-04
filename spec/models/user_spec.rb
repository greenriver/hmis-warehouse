###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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

  describe 'invitation handling', :devise_only do
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
    let!(:user2) { create(:user, first_name: 'Alicea', last_name: 'Smythe', email: 'alicia.smythe@green.com') }
    let!(:user3) { create(:user, first_name: 'Bob', last_name: 'Jones', email: 'bob.jones@green.com') }

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

    it 'finds users by email domain (substring match)' do
      results = User.text_search('green')
      expect(results).to include(user2, user3) # accounts with email domain 'green.com'
      expect(results).not_to include(user1)
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

    context 'when the user is on ACLs' do
      let(:user) { create(:acl_user, email: 'reporter@example.com') }
      let(:cohort_b) { 404 }
      let(:cohort_c) { 505 }
      let(:cohort_ids) { [cohort_a, cohort_b] }
      let(:name_scope) { instance_double(ActiveRecord::Relation, pluck: [cohort_b, cohort_c]) }

      before do
        allow(GrdaWarehouse::Cohort).to receive(:viewable_by).with(user, permission: :can_view_client_name).and_return(name_scope)
      end

      it 'adds a can_view_client_name row only for cohorts that are both viewable and name-permitted' do
        populate_permissions

        pairs = cohort_records.map { |record| [record.cohort_id, record.permission] }
        expect(pairs).to contain_exactly(
          [cohort_a, 'can_view_cohorts'],
          [cohort_b, 'can_view_cohorts'],
          [cohort_b, 'can_view_client_name'],
        )
      end
    end

    context 'when the user is on legacy roles' do
      context 'and none of their roles grant can_view_client_name' do
        before { user.legacy_roles = [create(:cohort_client_viewer)] }

        it 'does not add a can_view_client_name row' do
          populate_permissions

          pairs = cohort_records.map { |record| [record.cohort_id, record.permission] }
          expect(pairs).to contain_exactly([cohort_a, 'can_view_cohorts'])
        end
      end

      context 'and a role unrelated to cohort access grants can_view_client_name' do
        before do
          user.legacy_roles = [
            create(:cohort_client_viewer),
            create(:role, can_view_client_name: true),
          ]
        end

        it 'adds a can_view_client_name row for every legacy-viewable cohort' do
          populate_permissions

          pairs = cohort_records.map { |record| [record.cohort_id, record.permission] }
          expect(pairs).to contain_exactly(
            [cohort_a, 'can_view_cohorts'],
            [cohort_a, 'can_view_client_name'],
          )
        end
      end
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

  # Regression coverage for CVE-2026-32700: confirmation_token/unconfirmed_email desync.
  # The app previously carried a monkey patch (DeviseUserPatch) working around this on
  # Devise 4; Devise 5.0.4 fixes it natively, so the patch was removed. This spec confirms
  # the native behavior still holds.
  describe 'CVE-2026-32700 - confirmation token/unconfirmed_email sync', :devise_only do
    it 'prevents desync when a concurrent request modifies unconfirmed_email mid-flight' do
      attacker_email = 'attacker@example.com'
      victim_email   = 'victim@example.com'

      user = create(:user)
      # First email change — clears dirty tracking; in-memory clean value is now attacker_email
      user.update!(email: attacker_email)

      # Simulate a concurrent request that stomps unconfirmed_email in the DB
      # while the attacker's AR instance is still in memory
      User.where(id: user.id).update_all(
        unconfirmed_email: victim_email,
        confirmation_token: 'injected_token',
      )

      # Second update with the same email — without the fix, AR would consider
      # unconfirmed_email unchanged (still 'attacker_email' in memory) and
      # omit it from the UPDATE, leaving 'victim_email' in the DB
      user.update!(email: attacker_email)

      user.reload
      # Devise 5 ensures unconfirmed_email is always written, correcting the DB
      expect(user.unconfirmed_email).to eq(attacker_email)
      expect(user.confirmation_token).not_to eq('injected_token')
    end
  end

  describe 'devise-security password_archivable', :devise_only do
    around do |example|
      original = Devise.deny_old_passwords
      Devise.deny_old_passwords = 2
      example.run
      Devise.deny_old_passwords = original
    end

    let(:user) { create(:user) }

    def change_password!(user, password)
      user.update!(password: password, password_confirmation: password)
    end

    it 'accepts a new password that has never been used' do
      change_password!(user, 'Unique-Password-1')

      expect(user).to be_valid
    end

    it 'rejects a password that is still within the archived window' do
      # user starts on the factory-default password (pw0); build a chain of changes
      # so pw1 and pw2 remain archived (deny_old_passwords: 2) after the 3rd change.
      change_password!(user, 'History-Pass-1')
      change_password!(user, 'History-Pass-2')
      change_password!(user, 'History-Pass-3')

      expect(user.old_passwords.count).to eq(2)

      user.assign_attributes(password: 'History-Pass-2', password_confirmation: 'History-Pass-2')

      expect(user).to be_invalid
      expect(user.errors[:password]).to include('was used previously.')
    end

    it 'allows reusing a password once it has aged out of the archive window' do
      original_password = user.password

      change_password!(user, 'History-Pass-1')
      change_password!(user, 'History-Pass-2')
      change_password!(user, 'History-Pass-3') # pushes the original factory password out of the 2-entry window

      user.assign_attributes(password: original_password, password_confirmation: original_password)

      expect(user).to be_valid
    end
  end

  describe 'devise-security expirable', :devise_only do
    let(:user) { create(:user) }

    it 'is active when recently active' do
      user.update_column(:last_activity_at, Time.current)

      expect(user.expired?).to be false
      expect(user.active_for_authentication?).to be true
    end

    it 'is not expired just inside the configured expire_after window (boundary)' do
      user.update_column(:last_activity_at, (Devise.expire_after - 1.hour).ago)

      expect(user.expired?).to be false
    end

    it 'is expired once inactivity exceeds the configured expire_after window' do
      user.update_column(:last_activity_at, (Devise.expire_after + 1.day).ago)

      expect(user.expired?).to be true
      expect(user.active_for_authentication?).to be false
      expect(user.inactive_message).to eq(:expired)
    end

    it 'treats a manually-set expired_at as authoritative even when recently active' do
      user.update_column(:last_activity_at, Time.current)
      user.expire!(1.day.ago)

      expect(user.expired?).to be true
      expect(user.active_for_authentication?).to be false
    end
  end

  describe 'devise-security secure_validatable password complexity', :devise_only do
    around do |example|
      original = Devise.password_complexity
      Devise.password_complexity = { digit: 1, lower: 1, upper: 1, symbol: 1 }
      example.run
      Devise.password_complexity = original
    end

    it 'accepts a password satisfying every configured character class' do
      user = build(:user, password: 'Abcdefgh1!', password_confirmation: 'Abcdefgh1!')

      expect(user).to be_valid
    end

    it 'rejects a password missing a required character class' do
      user = build(:user, password: 'Abcdefgh12', password_confirmation: 'Abcdefgh12')

      expect(user).to be_invalid
      expect(user.errors[:password]).to include('must contain at least one punctuation mark or symbol')
    end

    it 'does not enforce complexity when disabled' do
      Devise.password_complexity = {}
      user = build(:user, password: 'alllowercase123', password_confirmation: 'alllowercase123')

      expect(user).to be_valid
    end
  end

  describe '#reporting_policy_for_project' do
    let(:data_source) { create(:data_source_fixed_id) }
    let(:organization) { create(:hud_organization, data_source: data_source) }
    let(:project) { create(:grda_warehouse_hud_project, organization: organization, data_source: data_source) }

    it 'returns AllowPiiPolicy when project_id is nil' do
      expect(user.reporting_policy_for_project(project_id: nil)).to eq(GrdaWarehouse::AuthPolicies::AllowPiiPolicy.instance)
    end

    it 'wraps AllowPiiPolicy when project_id is nil and the given client is restricted' do
      allow(user.policy_context).to receive(:client_restricted?).with(42).and_return(true)
      policy = user.reporting_policy_for_project(project_id: nil, client_id: 42)
      expect(policy).to be_a(GrdaWarehouse::PiiProvider::RestrictedPolicy)
      expect(policy.can_view_name?).to eq(false)
    end

    it 'does not wrap AllowPiiPolicy when project_id is nil and the given client is not restricted' do
      allow(user.policy_context).to receive(:client_restricted?).with(42).and_return(false)
      policy = user.reporting_policy_for_project(project_id: nil, client_id: 42)
      expect(policy).to eq(GrdaWarehouse::AuthPolicies::AllowPiiPolicy.instance)
    end

    it 'is unaffected by restriction when client_id is not provided' do
      expect(user.reporting_policy_for_project(project_id: project.id)).to be_a(GrdaWarehouse::AuthPolicies::ProjectPiiPolicy)
    end

    it 'wraps the resolved policy when the given client is restricted' do
      allow(user.policy_context).to receive(:client_restricted?).with(42).and_return(true)
      policy = user.reporting_policy_for_project(project_id: project.id, client_id: 42)
      expect(policy).to be_a(GrdaWarehouse::PiiProvider::RestrictedPolicy)
    end

    it 'does not wrap the resolved policy when the given client is not restricted' do
      allow(user.policy_context).to receive(:client_restricted?).with(42).and_return(false)
      policy = user.reporting_policy_for_project(project_id: project.id, client_id: 42)
      expect(policy).to be_a(GrdaWarehouse::AuthPolicies::ProjectPiiPolicy)
    end
  end

  describe '#reporting_policy_for_client' do
    let(:destination_data_source) { create(:destination_data_source) }
    let(:client) { create(:grda_warehouse_hud_client, data_source: destination_data_source) }
    let!(:warehouse_client) { create(:warehouse_client, destination: client) }

    it 'returns DenyPiiPolicy when client is nil' do
      expect(user.reporting_policy_for_client(client: nil)).to eq(GrdaWarehouse::AuthPolicies::DenyPiiPolicy.instance)
    end

    it 'wraps the resolved policy when the given client is restricted' do
      allow(user.policy_context).to receive(:client_restricted?).with(client.id).and_return(true)
      policy = user.reporting_policy_for_client(client: client, mode: :browse)
      expect(policy).to be_a(GrdaWarehouse::PiiProvider::RestrictedPolicy)
    end

    it 'does not wrap the resolved policy when the given client is not restricted' do
      allow(user.policy_context).to receive(:client_restricted?).with(client.id).and_return(false)
      policy = user.reporting_policy_for_client(client: client, mode: :browse)
      expect(policy).not_to be_a(GrdaWarehouse::PiiProvider::RestrictedPolicy)
    end

    context 'with a real HMIS-restricted client' do
      let!(:hmis_ds) { create(:hmis_primary_data_source) }
      let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
      let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds) }
      let!(:restricted_destination_client) { create(:grda_warehouse_hud_client) }
      let!(:open_source_client) { create(:hmis_hud_client, data_source: hmis_ds) }
      let!(:open_destination_client) { create(:grda_warehouse_hud_client) }

      before do
        GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
        GrdaWarehouse::WarehouseClient.create!(destination_id: open_destination_client.id, source_id: open_source_client.id, data_source_id: hmis_ds.id, id_in_source: open_source_client.id.to_s)
        restricted_source_client.mark_as_restricted!(user: hmis_user)
        # Stub the base PII policy permissive so the assertions below are attributable
        # only to the real Hmis::RestrictedRecord -> client_restricted? chain, not to
        # this permission-less user's underlying (also-denying) DestinationClientPolicy.
        allow(user).to receive(:policy_for).and_return(GrdaWarehouse::AuthPolicies::AllowPiiPolicy.instance)
      end

      it 'redacts PII for a client restricted via a real Hmis::RestrictedRecord, but not for an unrestricted one' do
        restricted_policy = user.reporting_policy_for_client(client: restricted_destination_client, mode: :browse)
        open_policy = user.reporting_policy_for_client(client: open_destination_client, mode: :browse)

        expect(restricted_policy.can_view_name?).to eq(false)
        expect(open_policy.can_view_name?).to eq(true)
      end
    end
  end
end

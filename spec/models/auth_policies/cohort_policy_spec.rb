###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::AuthPolicies::CohortPolicy, type: :model do
  let(:cohort) { create(:cohort) }
  let(:other_cohort) { create(:cohort) }

  # predicate => permission that grants it (in addition to view access on the cohort)
  let(:gated_predicates) do
    {
      can_add_clients?: :can_add_cohort_clients,
      can_manage_data?: :can_manage_cohort_data,
      can_participate?: :can_participate_in_cohorts,
      can_manage_inactive_clients?: :can_manage_inactive_cohort_clients,
      can_view_inactive_clients?: :can_view_inactive_cohort_clients,
      can_view_deleted_clients?: :can_view_deleted_cohort_clients,
      can_download?: :can_download_cohorts,
      can_edit_columns?: :can_edit_cohort_columns,
      can_view_changes_report?: :can_view_cohort_client_changes_report,
    }
  end

  def role_with(*permissions)
    create(:role, **permissions.index_with { true })
  end

  def policy_for(user, record = cohort)
    # a fresh user instance so memoized contexts don't leak between examples
    User.find(user.id).policy_for(record)
  end

  shared_examples 'cohort policy predicates' do
    # grant(user, permissions, record) gives the user the permissions through the given cohort
    it 'grants each gated predicate only with its permission plus view access' do
      gated_predicates.each do |predicate, permission|
        user = build_user
        grant(user, [:can_view_cohorts, permission], cohort)
        expect(policy_for(user).public_send(predicate)).to be(true), "#{predicate} should be true with #{permission}"
      end
    end

    it 'denies each gated predicate when the permission is held on another cohort only' do
      gated_predicates.each do |predicate, permission|
        user = build_user
        grant(user, [:can_view_cohorts, permission], other_cohort)
        expect(policy_for(user).public_send(predicate)).to be(false), "#{predicate} leaked across cohorts"
      end
    end

    it 'denies every predicate with no grant' do
      user = build_user
      policy = policy_for(user)
      (gated_predicates.keys + [:can_view?, :can_configure?, :can_update_data?, :can_edit_clients?]).each do |predicate|
        expect(policy.public_send(predicate)).to be(false), "#{predicate} should be false"
      end
    end

    it 'denies can_add_clients? without view or edit permission on the cohort' do
      user = build_user
      grant(user, [:can_add_cohort_clients], cohort)
      policy = policy_for(user)
      expect(policy.can_view?).to be(false)
      expect(policy.can_add_clients?).to be(false)
    end

    it 'allows view with can_manage_cohort_data or can_participate_in_cohorts alone' do
      [:can_manage_cohort_data, :can_participate_in_cohorts].each do |permission|
        user = build_user
        grant(user, [permission], cohort)
        expect(policy_for(user).can_view?).to be(true), "#{permission} should imply view"
      end
    end

    it 'derives update and edit predicates from their component permissions' do
      {
        [:can_manage_cohort_data] => { can_update_data?: true, can_edit_clients?: true },
        [:can_participate_in_cohorts] => { can_update_data?: true, can_edit_clients?: true },
        [:can_view_cohorts, :can_manage_inactive_cohort_clients] => { can_update_data?: true, can_edit_clients?: false },
        [:can_view_cohorts, :can_add_cohort_clients] => { can_update_data?: false, can_edit_clients?: false },
      }.each do |permissions, expected|
        user = build_user
        grant(user, permissions, cohort)
        policy = policy_for(user)
        expected.each { |predicate, value| expect(policy.public_send(predicate)).to be(value), "#{predicate} for #{permissions}" }
      end
    end

    it 'permission? requires view access' do
      user = build_user
      grant(user, [:can_view_cohorts, :can_download_cohorts], cohort)
      policy = policy_for(user)
      expect(policy.permission?(:can_download_cohorts)).to be(true)
      expect(policy.permission?(:can_edit_cohort_columns)).to be(false)

      no_view = build_user
      grant(no_view, [:can_download_cohorts], cohort)
      expect(policy_for(no_view).permission?(:can_download_cohorts)).to be(false)
    end
  end

  context 'with a legacy user' do
    def build_user
      create(:user)
    end

    def grant(user, permissions, record)
      access_group = create(:access_group)
      role_with(*permissions).add(user)
      access_group.add(user)
      access_group.add_viewable(record)
    end

    include_examples 'cohort policy predicates'

    it 'lets a configure-only role configure without view or listing via other permissions' do
      user = build_user
      grant(user, [:can_configure_cohorts], cohort)
      policy = policy_for(user)
      expect(policy.can_configure?).to be(true)
      expect(policy.can_view?).to be(false)
    end
  end

  context 'with an ACL user' do
    def build_user
      create(:acl_user)
    end

    def grant(user, permissions, record)
      collection = create(:collection)
      collection.set_viewables({ cohorts: [record.id] })
      user_group = create(:user_group)
      user_group.add(user)
      create(:access_control, role: role_with(*permissions), collection: collection, user_group: user_group)
    end

    include_examples 'cohort policy predicates'

    it 'lets a manager-only user configure and list but not view' do
      user = build_user
      grant(user, [:can_configure_cohorts], cohort)
      policy = policy_for(user)
      expect(policy.can_configure?).to be(true)
      expect(policy.can_list?).to be(true)
      expect(policy.can_view?).to be(false)
      expect(policy.can_manage_data?).to be(false)
    end

    it 'can_list? is false with only an unrelated permission' do
      user = build_user
      grant(user, [:can_download_cohorts], cohort)
      expect(policy_for(user).can_list?).to be(false)
    end

    it 'ignores collections that have been deleted' do
      user = build_user
      grant(user, [:can_view_cohorts], cohort)
      user.access_controls.map(&:collection).each(&:destroy!)
      expect(policy_for(user).can_view?).to be(false)
    end

    it 'preloads several cohorts in no more queries than one' do
      cohorts = create_list(:cohort, 3)
      user = build_user
      cohorts.each { |c| grant(user, [:can_view_cohorts], c) }
      count_queries = lambda do |ids|
        context = User.find(user.id).send(:policy_context)
        n = 0
        counter = ->(*, payload) { n += 1 unless payload[:name] == 'SCHEMA' }
        ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') { context.preload_cohort_dependencies(ids) }
        [n, context]
      end
      single, = count_queries.call([cohorts.first.id])
      many, context = count_queries.call(cohorts.map(&:id))
      expect(many).to eq(single)
      expect(cohorts.map { |c| context.cohort_role_permissions(c.id).include?(:can_view_cohorts) }).to eq([true, true, true])
    end

    describe 'consistency with Cohort.viewable_by' do
      let(:user) { create(:acl_user) }
      let(:user_group) { create(:user_group).tap { |g| g.add(user) } }
      let(:permissions) { [:can_view_cohorts, :can_configure_cohorts, :can_add_cohort_clients] }
      let(:role) { role_with(*permissions) }

      shapes = {
        'a direct entity collection' => ->(ctx) { ctx.create(:collection).tap { |c| c.set_viewables({ cohorts: [ctx.cohort.id] }) } },
        'the All Cohorts system collection' => lambda { |_ctx|
          Collection.maintain_system_groups(group: :cohorts)
          Collection.system_collection(:cohorts)
        },
        'the All Data Sources system collection' => lambda { |_ctx|
          Collection.maintain_system_groups(group: :data_sources)
          Collection.system_collection(:data_sources)
        },
        'a collection without the cohort' => ->(ctx) { ctx.create(:collection).tap { |c| c.set_viewables({ cohorts: [ctx.other_cohort.id] }) } },
      }

      shapes.each do |name, builder|
        it "matches the scope for #{name}" do
          cohort
          other_cohort
          collection = builder.call(self)
          create(:access_control, role: role, collection: collection, user_group: user_group)
          context = User.find(user.id).send(:policy_context)
          fresh_user = User.find(user.id)

          permissions.each do |permission|
            expect(GrdaWarehouse::Cohort.viewable_by(fresh_user, permission: permission).exists?(cohort.id)).
              to eq(context.cohort_role_permissions(cohort.id).include?(permission)), "mismatch for #{permission} with #{name}"
          end
        end
      end

      it 'matches the scope when no grant exists' do
        cohort
        context = User.find(user.id).send(:policy_context)
        permissions.each do |permission|
          expect(GrdaWarehouse::Cohort.viewable_by(User.find(user.id), permission: permission).exists?(cohort.id)).to be(false)
          expect(context.cohort_role_permissions(cohort.id)).to be_empty
        end
      end
    end
  end
end

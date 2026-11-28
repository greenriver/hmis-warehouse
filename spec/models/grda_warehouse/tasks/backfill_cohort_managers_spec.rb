###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Tasks::BackfillCohortManagers do
  let(:participant) { create(:acl_user) }
  let(:other_user) { create(:acl_user) }
  let(:configure_role) { create(:role, can_configure_cohorts: true) }
  let!(:cohort) { create(:cohort) }

  before do
    Collection.maintain_system_groups
    setup_access_control(participant, configure_role, create(:collection))
    cohort.replace_access(participant, scope: :editor)
  end

  def manager_user_ids(cohort)
    UserGroup.system.where(source: cohort, context: :manager).flat_map { |group| group.users.pluck(:id) }
  end

  it 'makes a participant who holds a non-system configure role a manager' do
    described_class.new.run!

    expect(manager_user_ids(cohort)).to eq([participant.id])
  end

  it 'grants configure on that cohort only' do
    create(:cohort)

    described_class.new.run!

    expect(GrdaWarehouse::Cohort.viewable_by(participant.reload, permission: :can_configure_cohorts)).to contain_exactly(cohort)
  end

  it 'returns counts of grants and skipped cohorts' do
    skipped = create(:cohort)
    skipped.replace_access(other_user, scope: :manager)

    expect(described_class.new.run!).to eq(granted: 1, skipped_existing: 1)
  end

  it 'skips a participant whose configure comes only from a system role' do
    AccessControl.where(role: configure_role).destroy_all
    system_role = Role.system.create!(name: 'System Role - Test Configure', can_configure_cohorts: true)
    setup_access_control(participant, system_role, create(:collection))

    described_class.new.run!

    expect(manager_user_ids(cohort)).to be_empty
  end

  it 'skips a participant who does not hold a configure role' do
    AccessControl.where(role: configure_role).destroy_all

    described_class.new.run!

    expect(manager_user_ids(cohort)).to be_empty
  end

  it 'skips a user with configure who is not a participant' do
    setup_access_control(other_user, configure_role, create(:collection))
    cohort.replace_access(other_user, scope: :viewer)

    described_class.new.run!

    expect(manager_user_ids(cohort)).to eq([participant.id])
  end

  it 'skips a legacy participant even when they hold a configure role' do
    legacy = create(:user)
    setup_access_control(legacy, configure_role, create(:collection))
    cohort.replace_access([participant, legacy], scope: :editor)

    described_class.new.run!

    expect(manager_user_ids(cohort)).to eq([participant.id])
  end

  it 'skips an inactive participant' do
    participant.update!(active: false)

    described_class.new.run!

    expect(manager_user_ids(cohort)).to be_empty
  end

  # Under AUTH_METHOD=jwt the identity provider owns account expiry, so User.active ignores expired_at.
  it 'skips a participant whose account has expired', :devise_only do
    participant.update!(expired_at: 1.day.ago)

    described_class.new.run!

    expect(manager_user_ids(cohort)).to be_empty
  end

  it 'skips a system cohort' do
    system_cohort = create(:cohort, system_cohort: true)
    system_cohort.replace_access(participant, scope: :editor)

    described_class.new.run!

    expect(manager_user_ids(system_cohort)).to be_empty
  end

  it 'does not change a cohort that already has a manager group' do
    cohort.replace_access(other_user, scope: :manager)

    described_class.new.run!

    expect(manager_user_ids(cohort)).to eq([other_user.id])
  end

  it 'skips a cohort whose manager group is empty' do
    cohort.replace_access([participant], scope: :manager)
    cohort.replace_access([], scope: :manager)

    described_class.new.run!

    expect(manager_user_ids(cohort)).to be_empty
  end

  it 'makes no changes on a second run' do
    described_class.new.run!

    counts = -> { [UserGroup.count, AccessControl.count, UserGroupMember.count] }

    expect { described_class.new.run! }.not_to change(&counts)
  end

  it 'records the grant as the system user' do
    PaperTrailHelper.with_paper_trail { described_class.new.run! }

    group = UserGroup.system.find_by(source: cohort, context: :manager)
    expect(group.versions.pluck(:whodunnit).uniq).to eq([User.system_user.id.to_s])
  end

  it 'runs on a database with no cohorts' do
    GrdaWarehouse::Cohort.destroy_all

    expect(described_class.new.run!).to eq(granted: 0, skipped_existing: 0)
  end

  context 'when the task is run on its own and the grant fails for one cohort' do
    let!(:second_cohort) { create(:cohort) }

    before do
      second_cohort.replace_access(participant, scope: :editor)
      allow_any_instance_of(UserGroup).to receive(:add).and_wrap_original do |original, *args|
        raise ActiveRecord::StatementInvalid, 'boom' if original.receiver.source == second_cohort

        original.call(*args)
      end
    end

    it 'rolls back only the failing cohort, keeping earlier grants' do
      expect { described_class.new.run! }.to raise_error(ActiveRecord::StatementInvalid)

      expect(UserGroup.system.where(source: second_cohort, context: :manager)).not_to exist
      expect(manager_user_ids(cohort)).to eq([participant.id])
    end
  end
end

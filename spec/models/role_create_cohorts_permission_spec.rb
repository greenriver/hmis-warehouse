###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Role, type: :model do
  include AccessControlSetup

  describe 'can_create_cohorts' do
    it 'is a registered permission' do
      expect(Role.permissions).to include(:can_create_cohorts)
    end

    it 'has a column on roles' do
      expect(Role.column_names).to include('can_create_cohorts')
    end

    it 'is described for the admin UI' do
      metadata = Role.permissions_with_descriptions[:can_create_cohorts]

      expect(metadata[:description]).to eq('Ability to create cohorts and edit cohort-wide column names and options. Applies to all cohorts, including under Access Controls.')
      expect(metadata[:category]).to eq('Cohorts')
      expect(metadata[:sub_category]).to eq('Cohort Administration')
      expect(metadata[:administrative]).to eq(false)
    end

    it 'defaults to false on a new role' do
      expect(create(:role, can_configure_cohorts: true).can_create_cohorts).to eq(false)
    end
  end

  describe 'migration backfill' do
    let(:migration_file) { Dir[Rails.root.join('db/migrate/*_add_can_create_cohorts_permission.rb').to_s].first }

    def run_backfill
      require migration_file
      AddCanCreateCohortsPermission.new.up
      Role.reset_column_information
    end

    it 'grants the permission to non-system roles with can_configure_cohorts only' do
      configure_role = create(:role, can_configure_cohorts: true)
      system_role = Role.system.create!(name: 'system configure', can_configure_cohorts: true)
      other_role = create(:role, can_view_cohorts: true)

      run_backfill

      expect(configure_role.reload.can_create_cohorts).to eq(true)
      expect(system_role.reload.can_create_cohorts).to eq(false)
      expect(other_role.reload.can_create_cohorts).to eq(false)
    end

    it 'leaves a user whose only grant is a system role without can_create_cohorts?' do
      user = create(:user, permission_context: 'acls')
      system_role = Role.system.create!(name: 'system configure', can_configure_cohorts: true)
      setup_access_control(user, system_role, create(:collection))

      run_backfill

      expect(user.reload.can_create_cohorts?).to eq(false)
    end
  end

  describe 'cohort access' do
    it 'lets a user with only can_create_cohorts reach the cohort index' do
      user = create(:user, permission_context: 'acls')
      role = create(:role, can_create_cohorts: true)
      setup_access_control(user, role, create(:collection))

      expect(user.can_access_some_cohorts).to eq(true)
    end

    it 'does not grant cohort access to a user with an unrelated role' do
      user = create(:user, permission_context: 'acls')
      role = create(:role, can_view_clients: true)
      setup_access_control(user, role, create(:collection))

      expect(user.can_access_some_cohorts).to eq(false)
    end
  end
end

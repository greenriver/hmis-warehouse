###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../requests/hmis/login_and_permissions'

RSpec.describe Hmis::AuthPolicies::UserContext, type: :model do
  let(:data_source) { create(:hmis_data_source) }
  let(:user) { create(:hmis_user, data_source: data_source) }
  let(:context) { Hmis::AuthPolicies::UserContext.new(user) }

  describe '#initialize' do
    it 'raises an error if the user is not an Hmis::User' do
      expect { Hmis::AuthPolicies::UserContext.new(create(:user)) }.to raise_error(ArgumentError, /must be an HMIS user/i)
    end

    it 'raises an error if the user is not tied to an HMIS data source' do
      expect { Hmis::AuthPolicies::UserContext.new(create(:hmis_user, data_source: nil)) }.to raise_error(ArgumentError, /tied to an HMIS data source/i)
    end
  end

  describe '#project_permissions' do
    let(:project) { create(:hmis_hud_project, data_source: data_source) }

    context 'when the project belongs to the users current hmis data source' do
      before do
        create_access_control(user, project, with_permission: :can_view_project)
      end

      it 'returns the granted permissions' do
        expect(context.project_permissions(project.id)).to include(:can_view_project)
      end
    end

    context 'when the project belongs to a different data source' do
      let(:other_data_source) { create(:hmis_data_source) }
      let(:other_project) { create(:hmis_hud_project, data_source: other_data_source) }

      before do
        # Even if the user is somehow granted permission to a project in another data source
        create_access_control(user, other_project, with_permission: :can_view_project)
      end

      it 'returns an empty permission set' do
        expect(context.project_permissions(other_project.id)).to be_empty
      end

      it 'reports the mismatch to Sentry' do
        expect(Sentry).to receive(:capture_message).with(/HMIS Data Source Mismatch/)
        context.project_permissions(other_project.id)
      end
    end
  end

  describe '#global_permissions' do
    context 'with no access controls' do
      it 'returns an empty set' do
        expect(context.global_permissions).to be_empty
      end
    end

    context 'when user has permissions in multiple data sources' do
      let(:other_data_source) { create(:hmis_data_source) }
      let(:current_project) { create(:hmis_hud_project, data_source: data_source) }
      let(:other_project) { create(:hmis_hud_project, data_source: other_data_source) }

      before do
        # Grant permission in current data source
        create_access_control(user, current_project, with_permission: :can_view_project)
        # Grant permission in other data source
        create_access_control(user, other_project, with_permission: :can_view_clients)
        create_access_control(user, other_data_source, with_permission: :can_administrate_config)
      end

      it 'only returns permissions associated with the current data source' do
        permissions = context.global_permissions
        expect(permissions).to include(:can_view_project)
        expect(permissions).not_to include(:can_view_clients)
        expect(permissions).not_to include(:can_administrate_config)
      end
    end

    context 'when permissions are granted at the data source level' do
      before do
        create_access_control(user, data_source, with_permission: :can_view_project)
      end

      it 'returns the granted permissions' do
        expect(context.global_permissions).to include(:can_view_project)
      end
    end

    context 'when permissions are granted at the organization level' do
      let(:organization) { create(:hmis_hud_organization, data_source: data_source) }

      before do
        create_access_control(user, organization, with_permission: :can_edit_organization)
      end

      it 'returns the granted permissions' do
        expect(context.global_permissions).to include(:can_edit_organization)
      end
    end

    context 'when permissions are granted at the project group level' do
      let(:project) { create(:hmis_hud_project, data_source: data_source) }
      let(:project_group) { create(:hmis_project_group, data_source: data_source, with_projects: [project]) }

      before do
        create_access_control(user, project_group, with_permission: :can_view_project)
      end

      it 'returns the granted permissions' do
        expect(context.global_permissions).to include(:can_view_project)
      end
    end

    context 'when permissions are granted at the project level' do
      let(:project) { create(:hmis_hud_project, data_source: data_source) }

      before do
        create_access_control(user, project, with_permission: :can_view_project)
      end

      it 'returns the granted permissions' do
        expect(context.global_permissions).to include(:can_view_project)
      end
    end

    context 'memoization' do
      let(:project) { create(:hmis_hud_project, data_source: data_source) }

      before do
        create_access_control(user, project, with_permission: :can_view_project)
      end

      it 'returns the same object instance on subsequent calls' do
        first_call = context.global_permissions
        second_call = context.global_permissions
        third_call = context.global_permissions

        # Memoization should return the exact same object (same object_id)
        expect(first_call.object_id).to eq(second_call.object_id)
        expect(second_call.object_id).to eq(third_call.object_id)
      end

      it 'only executes expensive database queries once' do
        # Create a fresh context to avoid memoization from previous tests
        fresh_context = Hmis::AuthPolicies::UserContext.new(user)

        # Count how many times the database query is executed
        query_count = 0
        allow(::Hmis::GroupViewableEntity).to receive(:includes_any_entity_in_data_source).and_wrap_original do |method, *args|
          query_count += 1
          method.call(*args)
        end

        # Call global_permissions multiple times
        fresh_context.global_permissions
        fresh_context.global_permissions
        fresh_context.global_permissions

        # Verify the database query was only executed once (memoization prevents re-execution)
        expect(query_count).to eq(1)
      end
    end
  end
end

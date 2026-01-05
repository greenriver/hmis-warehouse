###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::AuthPolicies::UserContext, type: :model do
  let(:data_source) { create(:hmis_data_source) }
  let(:user) do
    u = create(:hmis_user)
    u.hmis_data_source_id = data_source.id
    u
  end
  let(:context) { Hmis::AuthPolicies::UserContext.new(user) }

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
end

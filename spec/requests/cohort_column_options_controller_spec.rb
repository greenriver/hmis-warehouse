###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CohortColumnOptionsController, type: :request do
  let(:user) { create(:acl_user) }
  let(:all_cohorts_collection) { Collection.system_collection(:cohorts) }

  before do
    Collection.maintain_system_groups
    GrdaWarehouse::Cohorts::CohortColumn.maintain!
    setup_access_control(user, role, all_cohorts_collection)
    sign_in user
  end

  context 'with a role that only configures cohorts (as a manager role grants)' do
    let(:role) { create(:role, can_configure_cohorts: true) }

    it 'refuses the options index' do
      get cohort_column_options_path

      expect(response).to redirect_to(root_path)
    end
  end

  context 'with a role that can create cohorts' do
    let(:role) { create(:role, can_create_cohorts: true) }

    it 'allows the options index' do
      get cohort_column_options_path

      expect(response).to have_http_status(:ok)
    end
  end
end

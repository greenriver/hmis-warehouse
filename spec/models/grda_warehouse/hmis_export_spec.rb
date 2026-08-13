###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::HmisExport, type: :model do
  let!(:data_source) { create :data_source_fixed_id }
  let!(:organization) { create :grda_warehouse_hud_organization }
  let!(:project) { create :grda_warehouse_hud_project, OrganizationID: organization.OrganizationID }
  let!(:user) { create :acl_user }
  let!(:can_view_projects_role) { create :role, can_view_projects: true }
  let!(:entity_group) { create :collection }

  before do
    entity_group.set_viewables({ data_sources: [data_source.id] })
    setup_access_control(user, can_view_projects_role, entity_group)
  end

  describe '#filter' do
    # Filters::HmisExport#to_h (which becomes the persisted `options` column
    # via options_for_job) never serializes user_id, so a filter rebuilt from
    # stored options has always had a nil user_id. #filter merges in the
    # export's own user_id column to compensate for that gap.
    it "carries the export's own user_id into the rebuilt filter even though options omits it" do
      export = create(:grda_warehouse_hmis_export, user_id: user.id, options: { 'project_ids' => [project.id] }).reload

      expect(export.options).not_to have_key('user_id')
      expect(export.filter.user_id).to eq(user.id)
    end
  end

  describe '#describe_filter_as_html' do
    # Regression: describe_filter_as_html -> chosen_projects calls
    # effective_project_ids, which resolves the filter's user via
    # User.find(user_id). Before the #filter fix, user_id was always nil
    # here, raising ActiveRecord::RecordNotFound ("Couldn't find User
    # without an ID") for any export with project_ids selected.
    it 'does not raise for a persisted export with project_ids selected' do
      export = create(:grda_warehouse_hmis_export, user_id: user.id, options: { 'project_ids' => [project.id] }).reload

      expect { export.describe_filter_as_html }.not_to raise_error
      expect(export.describe_filter_as_html).to include(project.ProjectName)
    end

    # Mirrors WarehouseReports::HmisExportsController#set_jobs, which builds
    # an in-memory (never-persisted) report from a queued Delayed::Job's
    # stored arguments to list running exports on the index page.
    it 'does not raise for an unsaved export built from queued job arguments' do
      export = described_class.new(user_id: user.id, options: { 'project_ids' => [project.id] })

      expect { export.describe_filter_as_html }.not_to raise_error
      expect(export.describe_filter_as_html).to include(project.ProjectName)
    end
  end
end

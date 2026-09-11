###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module DataSources
  class UnprocessedEnrollmentsController < ApplicationController
    before_action :require_can_view_imports_projects_or_organizations!
    before_action :set_data_source

    def index
      @enrollments = @data_source.enrollments.
        unprocessed_with_resolvable_project_and_client.
        preload(:project, :client, :destination_client).
        order(EntryDate: :desc, id: :desc)
    end

    private def set_data_source
      @data_source = GrdaWarehouse::DataSource.viewable_by(current_user).find(params[:data_source_id].to_i)
    end
  end
end

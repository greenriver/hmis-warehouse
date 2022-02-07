###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisCsvTwentyTwenty::ImporterExtensionsController < ApplicationController
  before_action :require_can_view_imports!
  before_action :require_can_manage_config!, only: [:update]
  before_action :set_data_source

  def edit
  end

  def update
    config = {
      import_aggregators: {},
      import_cleanups: {},
      refuse_imports_with_errors: params.dig(:extensions, :refuse_imports_with_errors),
    }
    allowed_extensions.each do |extension|
      next unless params[:extensions][extension.to_s] == '1'

      config.deep_merge!(extension.enable) do |_, v1, v2|
        v1 + v2
      end
    end

    @data_source.update(config)

    flash[:notice] = 'Configuration updated'
    redirect_to action: :edit
  end

  def allowed_extensions
    @allowed_extensions = [
      HmisCsvTwentyTwenty::HmisCsvCleanup::ForceValidEnrollmentCoc,
      HmisCsvTwentyTwenty::HmisCsvCleanup::MoveInOutsideEnrollment,
      HmisCsvTwentyTwenty::HmisCsvCleanup::PrependProjectId,
      HmisCsvTwentyTwenty::HmisCsvCleanup::PrependOrganizationId,
      HmisCsvTwentyTwenty::Aggregated::CombineEnrollments,
      HmisCsvTwentyTwenty::HmisCsvCleanup::DeleteEmptyEnrollments,
      HmisCsvTwentyTwenty::HmisCsvCleanup::EnforceRelationshipToHoh,
    ].sort_by(&:associated_model).
      freeze
  end
  helper_method :allowed_extensions

  def set_data_source
    @data_source = GrdaWarehouse::DataSource.editable_by(current_user).find(params[:id].to_i)
  end
end

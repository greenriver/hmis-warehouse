###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class HmisCsvTwentyTwenty::ImporterExtensionsController < ApplicationController
  before_action :require_can_view_imports!
  before_action :require_can_manage_config!, only: [:edit, :update]
  before_action :set_data_source

  def show
  end

  def edit
  end

  def update
    config = {
      import_cleanups: {},
    }
    allowed_extensions.each do |extension|
      next unless params[:extensions][extension.to_s] == '1'

      config.deep_merge!(extension.enable) do |_, v1, v2|
        v1 + v2
      end
    end

    @data_source.update(config)
    redirect_to action: :show
  end

  def allowed_extensions
    @allowed_extensions = [
      HmisCsvTwentyTwenty::HmisCsvCleanup::ForceValidEnrollmentCoc,
      HmisCsvTwentyTwenty::HmisCsvCleanup::MoveInOutsideEnrollment,
      HmisCsvTwentyTwenty::HmisCsvCleanup::PrependProjectId,
    ].freeze
  end
  helper_method :allowed_extensions

  def set_data_source
    @data_source = GrdaWarehouse::DataSource.find(params[:id].to_i)
  end
end

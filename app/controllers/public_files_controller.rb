###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class PublicFilesController < ApplicationController
  before_action :load_file

  def show
    filename = @file.file&.file&.filename&.to_s || 'file'
    send_data(@file.content, type: @file.content_type, filename: filename)
  end

  def load_file
    @file = file_source.find(params[:id].to_i)
  end

  def file_source
    GrdaWarehouse::PublicFile
  end
end

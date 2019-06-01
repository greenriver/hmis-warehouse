###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class PublicFilesController < ApplicationController

  before_action :load_file

  def show
    send_data(@file.content, type: @file.content_type, filename: File.basename(@file.file.to_s))
  end

  def load_file
    @file = file_source.find(params[:id].to_i)
  end

  def file_source
    GrdaWarehouse::PublicFile
  end
end
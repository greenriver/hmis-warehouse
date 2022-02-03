###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class BackgroundRenderChannel < ApplicationCable::Channel
  def subscribed
    stream_from self.class.stream_name(params[:id])
  end

  def self.stream_name(id)
    "background_render:#{id}"
  end
end

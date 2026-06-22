###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class BackgroundRenderChannel < ApplicationCable::Channel
  def subscribed
    stream_from self.class.stream_name(params[:id])
  end

  def self.stream_name(id)
    "background_render:#{id}"
  end
end

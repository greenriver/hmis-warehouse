###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class TestChannel < ApplicationCable::Channel
  def subscribed
    stream_from "test"
  end

  def unsubscribed
  end
end

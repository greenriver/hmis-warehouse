###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class TestChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'test'
  end

  def unsubscribed
  end
end

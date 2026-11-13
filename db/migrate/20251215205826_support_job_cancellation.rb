###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class SupportJobCancellation < ActiveRecord::Migration[7.2]
  def change
    add_column :delayed_jobs, :cancellation_requested_at, :datetime
  end
end

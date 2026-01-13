# frozen_string_literal: true

class SupportJobCancellation < ActiveRecord::Migration[7.2]
  def change
    add_column :delayed_jobs, :cancellation_requested_at, :datetime
  end
end

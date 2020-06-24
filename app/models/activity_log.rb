###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ActivityLog < ApplicationRecord
  include ArelHelper

  belongs_to :user

  scope :created_in_range, -> (range:) do
    where(created_at: range)
  end

  def clean_object_name
    item_model&.gsub('GrdaWarehouse::Hud::', '')
  end

  # increment can be: minute, hour, day, week, month, year
  def self.for_chart(increment: 'hour', range: 1.weeks.ago..Time.current)
    return [] unless valid_increments.include?(increment)
    data = {}
    where(created_at: range).
    group(:created_at_trunc, :user_id).
    pluck(Arel.sql("date_trunc('#{increment}', created_at) as created_at_trunc"), :user_id).
    each do |time, user_id|
      data[time.strftime('%Y-%m-%d %H:%M')] ||= 0
      data[time.strftime('%Y-%m-%d %H:%M')] += 1
    end
    [
      ['x'] + data.keys,
      ['Active Users'] + data.values
    ]
  end

  def self.valid_increments
    ['minute', 'hour', 'day', 'week', 'month', 'year']
  end
end
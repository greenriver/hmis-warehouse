###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudSpmReport::Fy2024
  class Debugger
    def log(str)
      puts str
    end

    def log_timeline(label, dates)
      return log "#{label}: No dates provided." if dates.empty?

      dates = dates.map(&:last) unless dates.first.is_a?(Date)

      # Sort dates to ensure chronological order
      sorted_dates = dates.sort.uniq

      log "#{label}:"

      # Find contiguous date ranges
      ranges = []
      current_range = [sorted_dates.first]

      sorted_dates[1..].each do |date|
        # Check if current date is consecutive to the previous one
        if date == current_range.last + 1
          current_range << date
        else
          # Store the completed range and start a new one
          ranges << current_range
          current_range = [date]
        end
      end

      # Add the last range
      ranges << current_range

      # Print each contiguous range
      ranges.each do |range|
        start_date = range.first
        end_date = range.last
        days = (end_date - start_date).to_i + 1

        log "  #{start_date.to_fs(:db)} - #{end_date.to_fs(:db)}, #{days} days"
      end
      nil
    end
  end
end

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'csv'

# Base CSV reader for report data stored in Active Storage
# Uses streaming to avoid loading entire CSVs into memory
class ReportCsvReader
  attr_reader :report, :attachment_name

  def initialize(report, attachment_name)
    @report = report
    @attachment_name = attachment_name
  end

  def count
    return 0 unless attached?

    @count ||= begin
      row_count = 0
      each_row { row_count += 1 }
      row_count
    end
  end

  # Stream CSV rows in batches without loading entire file into memory
  # Yields an array of rows to the given block
  def batch_read(batch_size: 5_000)
    return unless attached?

    batch = []
    each_row do |row|
      batch << row
      if batch.size >= batch_size
        yield batch
        batch = []
      end
    end

    # Yield any remaining rows
    yield batch if batch.any?
  end

  private

  def attached?
    report.send(attachment_name).attached?
  end

  # Stream CSV rows without loading entire file into memory
  # Yields each row as a hash to the given block
  def each_row
    file = attachment_file
    return unless file.present?

    file.open do |io|
      CSV.foreach(io, headers: true, header_converters: :symbol) do |csv_row|
        yield csv_row.to_h
      end
    end
  rescue StandardError => e
    Rails.logger.error("Error reading CSV: #{e.message}")
  end

  def attachment_file
    return nil unless attached?

    attachment = report.send(attachment_name)
    return nil unless attachment.attached?

    # Get the first attached file (for has_one_attached) or most recent (for has_many_attached)
    if attachment.respond_to?(:first)
      attachment.first
    else
      attachment
    end
  end
end

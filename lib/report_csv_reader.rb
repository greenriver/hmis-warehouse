###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'csv'

# Base CSV reader for report data stored in Active Storage
class ReportCsvReader
  attr_reader :report, :attachment_name, :csv_data

  def initialize(report, attachment_name)
    @report = report
    @attachment_name = attachment_name
    @csv_data = nil
  end

  def load!
    return false unless attached?

    attachment = report.send(attachment_name)
    return false unless attachment.attached?

    # Get the first attached file (for has_one_attached) or most recent (for has_many_attached)
    file = if attachment.respond_to?(:first)
      attachment.first
    else
      attachment
    end

    return false unless file.present?

    # Download and parse CSV
    csv_content = file.download
    @csv_data = CSV.parse(csv_content, headers: true, header_converters: :symbol)
    true
  end

  def loaded?
    @csv_data.present?
  end

  def attached?
    report.send(attachment_name).attached?
  end

  def all
    load! unless loaded?
    return [] unless @csv_data.present?

    @csv_data.map(&:to_h)
  end

  def find_by(conditions)
    load! unless loaded?
    return nil unless @csv_data.present?

    row = @csv_data.find do |csv_row|
      conditions.all? { |key, value| csv_row[key.to_sym] == value }
    end

    row&.to_h
  end

  def where(conditions)
    load! unless loaded?
    return [] unless @csv_data.present?

    matching_rows = @csv_data.select do |csv_row|
      conditions.all? { |key, value| csv_row[key.to_sym] == value }
    end

    matching_rows.map(&:to_h)
  end

  def pluck(*columns)
    load! unless loaded?
    return [] unless @csv_data.present?

    @csv_data.map do |row|
      if columns.size == 1
        row[columns.first.to_sym]
      else
        columns.map { |col| row[col.to_sym] }
      end
    end
  end

  def count
    load! unless loaded?
    return 0 unless @csv_data.present?

    @csv_data.size
  end

  def empty?
    count.zero?
  end

  def any?
    !empty?
  end
end

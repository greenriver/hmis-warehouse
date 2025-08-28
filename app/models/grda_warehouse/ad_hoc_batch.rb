###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'roo'
class GrdaWarehouse::AdHocBatch < GrdaWarehouseBase
  acts_as_paranoid
  include ArelHelper
  include ::Import::ClientMatching

  belongs_to :ad_hoc_data_source, optional: true
  has_many :ad_hoc_clients, foreign_key: :batch_id, dependent: :destroy
  belongs_to :user, optional: true

  has_one_attached :batch_file

  validates_presence_of :description
  validate :batch_file_attached, on: :create
  validate :batch_file_format, on: :create

  private def batch_file_attached
    return if batch_file.attached?

    errors.add(:batch_file, 'must be attached')
  end

  private def batch_file_format
    return unless batch_file.attached?

    allowed_types = [
      'text/plain',
      'text/csv',
      'application/csv',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', # .xlsx
      'application/vnd.ms-excel', # .xls
    ]

    return if batch_file.content_type.in?(allowed_types)

    errors.add(:batch_file, 'must be a CSV or Excel file')
  end

  scope :un_started, -> do
    where(started_at: nil)
  end

  def status
    if import_errors.present?
      import_errors
    elsif started_at.blank?
      'Queued'
    elsif started_at.present? && completed_at.blank?
      if started_at < 24.hours.ago
        'Failed'
      else
        "Running since #{started_at}"
      end
    elsif completed?
      'Complete'
    end
  end

  def completed?
    completed_at.present?
  end

  def sanitized_name
    # See https://www.keynotesupport.com/excel-basics/worksheet-names-characters-allowed-prohibited.shtml
    description.gsub(/['\*\/\\\?\[\]\:]/, '-')
  end

  def self.process!
    with_advisory_lock('ad_hoc_processing', timeout_seconds: 0) do
      un_started.each(&:process!)
    end
  end

  private def start
    update(started_at: Time.current)
  end

  def process!
    transaction do
      start
      if check_header!
        match_clients!
      else
        self.import_errors = "Headers do not match expected headers: #{self.class.csv_headers.join(',')}; found: #{headers_from_csv.join(',')}"
      end
      self.completed_at = Time.current
      save(validate: false)
    end
  end

  private def csv
    return nil unless batch_file.attached?

    content = batch_file.download
    content_type = batch_file.content_type
    @csv ||= if content_type.in?(['text/plain', 'text/csv', 'application/csv'])
      sheet = ::Roo::CSV.new(StringIO.new(content))
      @csv_headers = sheet.first
      sheet.parse(headers: true).drop(1) # rubocop:disable Style/IdenticalConditionalBranches
    else
      sheet = ::Roo::Excelx.new(StringIO.new(content).binmode)
      return nil if sheet&.first_row.blank?

      @csv_headers = sheet.first
      sheet.parse(headers: true).drop(1) # rubocop:disable Style/IdenticalConditionalBranches
    end
  end

  private def check_header!
    headers_from_csv == self.class.csv_headers
  end

  private def headers_from_csv
    # Force header calculation
    csv
    @csv_headers || []
  end

  def self.csv_headers
    header_map.values
  end

  def self.header_map
    {
      first_name: 'First Name',
      middle_name: 'Middle Name',
      last_name: 'Last Name',
      ssn: 'SSN',
      dob: 'DOB',
    }.freeze
  end

  private def match_clients!
    self.uploaded_count = csv.count
    self.matched_count = 0
    csv.each do |row|
      client = GrdaWarehouse::AdHocClient.new(clean(row).merge(ad_hoc_data_source_id: ad_hoc_data_source_id, batch_id: id))
      client.matching_client_ids = []
      client.matching_client_ids += name_matches(client)
      client.matching_client_ids += ssn_matches(client)
      client.matching_client_ids += dob_matches(client)
      # See if any clients matched more than once
      counts = client.matching_client_ids.
        each_with_object(Hash.new(0)) { |id, internal_counts| internal_counts[id] += 1 }.
        select { |_, c| c > 1 }
      # If only one client matched more than once, make note
      if counts.count == 1
        client.client_id = counts.keys.first
        self.matched_count += 1
      end
      client.save
    end
  end

  # for file migration
  scope :unprocessed_s3_migration, -> do
    migrated = ActiveStorage::Attachment.where(record_type: 'GrdaWarehouse::AdHocBatch').pluck(:record_id)
    all = pluck(:id)
    unmigrated = all - migrated
    return none if unmigrated.blank?

    where(id: unmigrated)
  end

  def copy_to_s3!
    return unless content.present?
    return unless valid? # Ignore uploads that are already invalid (data source deleted?)
    return if batch_file.attached? # don't re-process

    puts "Migrating #{file} to S3"

    Tempfile.create(binmode: true) do |tmp_file|
      tmp_file.write(content)
      tmp_file.rewind
      batch_file.attach(io: tmp_file, content_type: content_type, filename: file, identify: false)
    end

    # Save no-matter validity state
    self.content = nil
    save!(validate: false)
  end
  # END for file migration
end

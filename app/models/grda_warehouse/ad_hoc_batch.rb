###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
require 'roo'
class GrdaWarehouse::AdHocBatch < GrdaWarehouseBase
  acts_as_paranoid
  mount_uploader :file, AdHocDataSourceUploader
  include ArelHelper
  include ::Import::ClientMatching

  belongs_to :ad_hoc_data_source
  has_many :ad_hoc_clients, foreign_key: :batch_id, dependent: :destroy
  belongs_to :user, optional: true

  validates_presence_of :file
  validates_presence_of :description

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

  def self.process!
    return if advisory_lock_exists?('ad_hoc_processing')

    with_advisory_lock('ad_hoc_processing') do
      un_started.each(&:process!)
    end
  end

  private def start
    update(started_at: Time.current)
  end

  def process!
    start
    if check_header!
      match_clients!
    else
      self.import_errors = "Headers do not match expected headers: #{self.class.csv_headers.join(',')}; found: #{headers_from_csv.join(',')}"
    end
    self.completed_at = Time.current
    save(validate: false)
  end

  private def csv
    return nil unless content.length > 10

    @csv ||= if content_type.in?(['text/plain', 'text/csv'])
      sheet = ::Roo::CSV.new(StringIO.new(content))
      @csv_headers = sheet.first
      sheet.parse(headers: true).drop(1)
    else
      sheet = ::Roo::Excelx.new(StringIO.new(content).binmode)
      return nil if sheet&.first_row.blank?

      @csv_headers = sheet.first
      sheet.parse(headers: true).drop(1)
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
        each_with_object(Hash.new(0)) { |id, counts| counts[id] += 1 }.
        select { |_, c| c > 1 }
      # If only one client matched more than once, make note
      if counts.count == 1
        client.client_id = counts.keys.first
        self.matched_count += 1
      end
      client.save
    end
  end

end

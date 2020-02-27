###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###
require 'csv'
class GrdaWarehouse::AdHocBatch < GrdaWarehouseBase
  acts_as_paranoid
  mount_uploader :file, AdHocDataSourceUploader
  include ArelHelper

  CACHE_EXPIRY = if Rails.env.production? then 20.hours else 20.seconds end

  belongs_to :ad_hoc_data_source
  has_many :ad_hoc_clients, foreign_key: :batch_id, dependent: :destroy
  belongs_to :user, optional: :true

  validates_presence_of :file
  validates_presence_of :description

  scope :un_started, -> do
    where(started_at: nil)
  end

  def status
    if import_errors.present?
      import_errors
    elsif started_at.blank?
      "Queued"
    elsif started_at.present? && completed_at.blank?
      if started_at < 24.hours.ago
        'Failed'
      else
        "Running since #{started_at}"
      end
    elsif completed?
      "Complete"
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
      self.import_errors = "CSV headers do not match expected headers: #{self.class.csv_headers.join(',')}; found: #{csv.headers.join(',')}"
    end
    self.completed_at = Time.current
    save(validate: false)
  end

  private def csv
    @csv ||= CSV.parse(content, headers: true)
  end

  private def check_header!
    csv.headers == self.class.csv_headers
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
        each_with_object(Hash.new(0)) { |id,counts| counts[id] += 1 }.
        select{ |_,c| c > 1 }
      # If only one client matched more than once, make note
      if counts.count == 1
        client.client_id = counts.keys.first
        self.matched_count += 1
      end
      client.save
    end

  end

  # match name, case insensitive, ignoring all whitespace
  private def name_matches(client)
    return [] unless client.first_name && client.last_name
    key = [client.first_name&.downcase&.gsub(/\s+/, ""), client.last_name&.downcase&.gsub(/\s+/, "")]
    clients_by_name[key]&.map{ |c| c[:destination_id]} || []
  end

  private def ssn_matches(client)
    return [] unless valid_social?(client.ssn)
    clients_by_ssn[client.ssn]&.map{ |c| c[:destination_id]} || []
  end

  private def dob_matches(client)
    return [] unless client.dob
    clients_by_dob[client.dob]&.map{ |c| c[:destination_id]} || []
  end

  def all_clients
    Rails.cache.fetch('all_clients_for_matching_ad_hoc', expires_in: CACHE_EXPIRY) do
      GrdaWarehouse::Hud::Client.source.joins(:warehouse_client_source).
        distinct.
        pluck(*client_columns.values).map do |row|
          Hash[client_columns.keys.zip(row)]
        end
    end
  end

  private def clients_by_name
    @clients_by_name ||= all_clients.group_by{ |row| [row[:first_name]&.downcase&.gsub(/\s+/, ""), row[:last_name]&.downcase&.gsub(/\s+/, "")] }
  end

  private def clients_by_ssn
    @clients_by_ssn ||= all_clients.group_by{ |row| row[:ssn] }
  end

  private def clients_by_dob
    @clients_by_dob ||= all_clients.group_by{ |row| row[:dob] }
  end

  private def client_columns
    {
      first_name: :FirstName,
      last_name: :LastName,
      ssn: :SSN,
      dob: :DOB,
      destination_id: wc_t[:destination_id].to_sql,
    }
  end

  private def valid_social?(ssn)
    ::HUD.valid_social?(ssn)
  end

  private def clean(row)

    clean_row = {}
    self.class.header_map.each do |k,title|
      begin
        case k
        when :ssn
          clean_row[k] = row[title]&.gsub('-', '')
        when :dob
          clean_row[k] = row[title]&.to_date
        else
          clean_row[k] = row[title]
        end
      rescue
        Rails.logger.error "Error processing #{k}"
      end
    end
    clean_row
  end

end

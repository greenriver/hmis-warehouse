###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

require 'roo'
module GrdaWarehouse::HealthEmergency
  class TestBatch < GrdaWarehouseBase
    include Rails.application.routes.url_helpers
    include ::HealthEmergency
    include ArelHelper
    include ::Import::ClientMatching
    acts_as_paranoid
    mount_uploader :file, TestResultsUploader

    belongs_to :user
    has_many :uploaded_tests, foreign_key: :batch_id, inverse_of: :batch

    scope :visible_to, -> (user) do
      return current_scope if user.can_see_health_emergency_clinical?

      none
    end

    def visible_to?(user)
      user.can_see_health_emergency_clinical?
    end

    def title
      'Testing Results Upload'
    end

    def url
      warehouse_reports_health_emergency_uploaded_results_url(host: ENV.fetch('FQDN'))
    end

    scope :newest_first, -> do
      order(created_at: :desc)
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

    def self.process!
      return if advisory_lock_exists?('test_upload_processing')

      with_advisory_lock('test_upload_processing') do
        un_started.each(&:process!)
      end
    end

    private def start
      update(started_at: Time.current)
    end

    private def upload
      @upload ||= Roo::Spreadsheet.open(file)
    end

    def process!
      start
      if check_header!
        match_clients!
        add_test_results!
        notify_user
      else
        self.import_errors = "File headers do not match expected headers: #{self.class.headers.join(',')}; found: #{upload_headers.join(',')}"
      end
      self.completed_at = Time.current
      save(validate: false)
    end

    private def match_clients!
      self.uploaded_count = sheet.last_row - 1
      self.matched_count = 0
      sheet.each_row_streaming(offset: 1) do |row|
        row = self.class.headers.zip(row.map(&:value)).to_h
        client = GrdaWarehouse::HealthEmergency::UploadedTest.new(clean(row).merge( batch_id: id))
        matching_client_ids = []
        matching_client_ids += name_matches(client)
        matching_client_ids += ssn_matches(client)
        matching_client_ids += dob_matches(client)
        # See if any clients matched more than once
        counts = matching_client_ids.
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

    private def add_test_results!
      GrdaWarehouse::HealthEmergency::UploadedTest.test_addition_pending.
        find_each do |uploaded_test|
          test = GrdaWarehouse::HealthEmergency::Test.create(
            user_id: user.id,
            agency_id: user.agency&.id,
            client_id: uploaded_test.client_id,
            tested_on: uploaded_test.tested_on,
            result: uploaded_test.test_result,
            location: uploaded_test.test_location,
            emergency_type: GrdaWarehouse::Config.get(:health_emergency),
          )
          uploaded_test.update(test_id: test.id)
        end
    end

    def notify_user
      NotifyUser.report_completed(user.id, self).deliver_later
    end

    private def sheet
      upload.sheet(0)
    end

    private def upload_headers
      sheet.row(1)
    end

    private def check_header!
      upload_headers.map{ |h| h.gsub(/\s+/, "") } == self.class.headers.map{ |h| h.gsub(/\s+/, "") }
    end

    def self.headers
      header_map.values
    end

    def self.header_map
      {
        last_name: 'Last name',
        first_name: 'First name',
        dob: 'Date of birth',
        gender: 'Gender',
        tested_on: 'Test date',
        test_location: 'Test location',
        test_result: 'Test result',
        ssn: 'SSN',
      }.freeze
    end

  end
end
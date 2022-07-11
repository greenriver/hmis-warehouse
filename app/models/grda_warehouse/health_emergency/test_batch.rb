###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
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

    belongs_to :user, optional: true
    has_many :uploaded_tests, foreign_key: :batch_id, inverse_of: :batch

    scope :visible_to, ->(user) do
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
      warehouse_reports_health_emergency_uploaded_results_url(host: ENV.fetch('FQDN'), protocol: 'https')
    end

    scope :newest_first, -> do
      order(created_at: :desc)
    end

    scope :un_started, -> do
      where(started_at: nil)
    end

    scope :completed, -> do
      where.not(completed_at: nil)
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
      @upload ||= Roo::Spreadsheet.open(reconstitute_path)
    end

    def process!
      start
      reconstitute_upload
      if check_header!
        match_clients!
        add_test_results!
        notify_user
      else
        self.import_errors = "File headers do not match expected headers: #{self.class.headers.join(',')}; found: #{upload_headers.join(',')}"
      end
      self.completed_at = Time.current
      save(validate: false)
      remove_upload
    end

    private def remove_upload
      File.delete(reconstitute_path)
    end

    private def reconstitute_path
      File.join(['tmp', "test_batch_#{id}.xlsx"])
    end

    def reconstitute_upload
      Rails.logger.info "Re-constituting upload file to: #{reconstitute_path}"
      File.open(reconstitute_path, 'w+b') do |file|
        file.write(content)
      end
    end

    private def match_clients!
      self.uploaded_count = sheet.last_row - 1
      self.matched_count = 0
      sheet.each_row_streaming(offset: 1) do |row|
        row = self.class.headers.zip(row.map(&:value)).to_h
        client = GrdaWarehouse::HealthEmergency::UploadedTest.new(clean(row).merge(batch_id: id))
        matching_client_ids = []
        matching_client_ids += name_matches(client)
        matching_client_ids += ssn_matches(client)
        matching_client_ids += dob_matches(client)
        # See if any clients matched more than once
        counts = matching_client_ids.
          each_with_object(Hash.new(0)) { |id, c| c[id] += 1 }.
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
          test = GrdaWarehouse::HealthEmergency::Test.where(
            client_id: uploaded_test.client_id,
            tested_on: uploaded_test.tested_on,
            result: uploaded_test.test_result,
            location: uploaded_test.test_location,
            emergency_type: health_emergency,
          ).first_or_create do |t|
            t.assign_attributes(
              user_id: user.id,
              agency_id: user.agency&.id,
            )
          end
          uploaded_test.update(test_id: test.id)
          add_medical_restriction!(test, uploaded_test)
        end
    end

    private def add_medical_restriction!(test, uploaded_test)
      return unless test.result.to_s.downcase.include?('positive')

      restriction = GrdaWarehouse::HealthEmergency::AmaRestriction.create(
        user_id: user.id,
        client_id: test.client_id,
        agency_id: user.agency&.id,
        emergency_type: health_emergency,
        restricted: 'Yes',
        note: 'This restriction was added automatically based on a Positive test result.',
      )
      uploaded_test.update(ama_restriction_id: restriction.id)
    end

    private def health_emergency
      GrdaWarehouse::Config.get(:health_emergency)
    end

    def notify_user
      NotifyUser.report_completed(user.id, self).deliver_later(priority: -5)
    end

    private def sheet
      upload.sheet(0)
    end

    private def upload_headers
      sheet.row(1)
    end

    private def check_header!
      upload_headers.map { |h| h.gsub(/\s+/, '') } == self.class.headers.map { |h| h.gsub(/\s+/, '') }
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

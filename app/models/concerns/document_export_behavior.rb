###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module DocumentExportBehavior
  extend ActiveSupport::Concern
  include Rails.application.routes.url_helpers

  STATUS_OPTIONS = [
    PENDING_STATUS = 'pending'.freeze,
    COMPLETED_STATUS = 'completed'.freeze,
    ERROR_STATUS = 'error'.freeze,
  ].freeze

  MIME_TYPES = [
    BINARY_MIME_TYPE = 'application/octet-stream'.freeze,
    PDF_MIME_TYPE = 'application/pdf'.freeze,
  ].freeze

  EXPIRES_AFTER = 30.days
  CURRENT_VERSION = '1'.freeze # bump to invalidate exports

  included do
    belongs_to :user, optional: true
    validates :status, inclusion: { in: STATUS_OPTIONS }
    validates :mime_type, inclusion: { in: MIME_TYPES }, allow_blank: true

    after_initialize do
      self.version ||= CURRENT_VERSION if self.class.column_names.include?('version')
      self.export_version ||= CURRENT_VERSION if self.class.column_names.include?('export_version')
    end
  end

  class_methods do
    def not_expired
      where('created_at > ?', Time.now - EXPIRES_AFTER)
    end

    def expired
      where('created_at <= ?', Time.now - EXPIRES_AFTER)
    end

    def recent
      where('created_at > ?', 8.hours.ago)
    end

    def with_current_version
      where(version: CURRENT_VERSION)
    end

    def completed
      where(status: COMPLETED_STATUS)
    end

    def diet_select
      select(column_names - ['file_data'])
    end
  end

  def completed?
    status == COMPLETED_STATUS
  end

  def with_status_progression
    okay = false
    begin
      update_attributes(status: PENDING_STATUS)
      okay = yield
    ensure
      if okay
        update_attributes(status: COMPLETED_STATUS)
      else
        update_attributes(status: ERROR_STATUS)
      end
    end
    okay
  end

  def pdf_file=(file_io)
    self.filename = File.basename(file_io.path)
    self.file_data = file_io.read
    self.mime_type = PDF_MIME_TYPE
  end

  def download_title
    filename.presence || 'Report PDF'
  end

  def generator_url
    report_class.url
  rescue NoMethodError
    # ignore these
  end
end

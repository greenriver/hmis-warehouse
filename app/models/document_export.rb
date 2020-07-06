###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class DocumentExport < ApplicationRecord
  belongs_to :user
  mount_uploader :file, DocumentExportUploader

  STATUS_OPTIONS = [
    NEW_STATUS = 'new'.freeze,
    IN_PROGRESS_STATUS = 'in_progress'.freeze,
    COMPLETED_STATUS = 'completed'.freeze,
    ERROR_STATUS = 'error'.freeze,
  ].freeze

  def with_status_progression
    okay = false
    begin
      update_attributes(status: IN_PROGRESS_STATUS)
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

  CURRENT_VERSION = '1'.freeze # bump to invalidate exports

  def self.with_current_version
    where(version: CURRENT_VERSION)
  end

  before_create do
    self.version ||= CURRENT_VERSION
  end

  EXPIRES_AFTER = 12.hours
  def self.not_expired
    where('created_at > ?', Time.now - EXPIRES_AFTER)
  end

  def self.expired
    where('created_at <= ?', Time.now - EXPIRES_AFTER)
  end

  protected def render_to_pdf!(file:, assigns: {}, context: nil)
    context ||= Rails.configuration.paths['app/views']
    view = ActionView::Base.new(context, assigns)
    html = view.render(file: file)
    PdfGenerator.new.perform(html) do |io|
      self.file = io
    end
    save!
  end
end

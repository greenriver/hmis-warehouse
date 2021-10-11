###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ReportResult < ApplicationRecord
  acts_as_paranoid
  require 'csv'
  include ActionView::Helpers::DateHelper
  belongs_to :report, optional: true
  belongs_to :user, optional: true
  belongs_to :delayed_job, class_name: 'Delayed::Job', optional: true

  scope :most_recent, -> do
    where(percent_complete: 100).group(:type).maximum(:updated_at)
  end

  scope :viewable_by, -> (user) do
    if user.can_view_all_hud_reports?
      all
    elsif user.can_view_own_hud_reports?
      where(user_id: user.id)
    else
      none
    end
  end

  scope :incomplete, -> do
    where(completed_at: nil)
  end

  scope :updated_today, -> do
    where(arel_table[:updated_at].gt(24.hours.ago))
  end

  delegate :download_type, to: :report
  delegate :value_for_options, to: :report

  validate :project_required_if_report_demands
  validate :project_id_required_if_report_demands
  validate :data_source_required_if_report_demands

  # Queue a report to run
  # 1. Set a timestamp as the group,
  # 2. Set the import_id
  # 3. Mark as 0% complete

  def last_run
    created_at
  end

  def last_run_status with_complete=false
    if job_status.present?
      'Report Failed'
    elsif percent_complete == 100
      'Complete'
    elsif percent_complete == 0
      'Queued'
    elsif percent_complete == 0.01
      'Started'
    else
      stat = "#{percent_complete.round(2)}%"
      if with_complete
        stat = "#{stat} complete"
      end
      stat
    end
  end

  def completed_in
    if percent_complete == 100 && completed_at
      seconds = ((completed_at - created_at)/1.minute).round * 60
      distance_of_time_in_words(seconds)
    else
      'incomplete'
    end
  end

  def as_csv
    report.as_csv results, user
  end

  def as_xml
    report.as_xml self
  end

  def file
    GrdaWarehouse::ReportResultFile.where(id: file_id)
  end

  def support_file
    GrdaWarehouse::ReportResultFile.find_by(id: support_file_id)
  end

  def export
    ## FIXME? This model doesnt exist anymore
    GrdaWarehouse::Export.where(id: export_id)
  end

  def to_partial_path
    "report_results/#{report_type}"
  end

  private def report_type
    report.class.to_s.underscore.gsub(/^reports\//, '')
  end

  private def project_required_if_report_demands
    if report.has_project_option?
      if options['project'].blank?
        errors.add(:project, 'A project is required')
      end
    end
  end

  private def project_id_required_if_report_demands
  if report.has_project_id_option?
    if options['project_id'].blank?
      errors.add(:project_id, 'is required')
    end
  end
end

  private def data_source_required_if_report_demands
    if report.has_data_source_option?
      if options['data_source'].blank?
        errors.add(:project, 'A data source is required')
      end
    end
  end
end

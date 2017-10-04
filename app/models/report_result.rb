class ReportResult < ActiveRecord::Base
  acts_as_paranoid
  require 'csv'
  include ActionView::Helpers::DateHelper
  belongs_to :report
  belongs_to :user
  belongs_to :delayed_job, class_name: Delayed::Job.name

  scope :most_recent, -> do
    where(percent_complete: 100).group(:type).maximum(:updated_at) 
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
    if percent_complete == 100
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

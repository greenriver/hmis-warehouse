###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Filters
  class HmisExport < ::ModelForm
    include ArelHelper
    attribute :start_date, Date, default: 1.years.ago.to_date
    attribute :end_date, Date, default: Date.current
    attribute :version, String, default: '2022'
    attribute :hash_status, Integer, default: 1
    attribute :period_type, Integer, default: 3
    attribute :directive, Integer, default: 2
    attribute :include_deleted, Boolean, default: false
    attribute :project_ids, Array, default: []
    attribute :project_group_ids, Array, default: []
    attribute :organization_ids, Array, default: []
    attribute :data_source_ids, Array, default: []
    attribute :user_id, Integer, default: nil
    attribute :faked_pii, Boolean, default: false

    attribute :every_n_days, Integer, default: 0
    attribute :reporting_range, String, default: 'fixed'
    attribute :reporting_range_days, Integer, default: 0

    attribute :recurring_hmis_export_id, Integer, default: 0

    attribute :s3_access_key_id, String
    attribute :s3_secret_access_key, String
    attribute :s3_region, String
    attribute :s3_bucket, String
    attribute :s3_prefix, String

    validates_presence_of :start_date, :end_date

    validate do
      if end_date.present? && start_date.present?
        errors.add :end_date, 'must follow start date' if end_date < start_date
      end
    end

    # Add to the list of available HMIS exports
    # like so available_versions << Filters::HmisExport::Version.new('HMIS 2022', '2020', DriverNamespace::ExportJob)
    ExporterVersion = Struct.new(:label, :version_str, :job_class)
    def self.register_version(label, version_str, job_class)
      available_versions << ExporterVersion.new(label, version_str, job_class)
    end

    def self.available_versions
      # this needs to be something that is not reloaded
      Rails.application.config.hmis_exporters ||= []
    end

    def self.job_classes
      available_versions.map(&:job_class).uniq + ['HmisTwentyTwentyExportJob'] # old exporter used before ::Filters::HmisExport.available_versions
    end

    def self.options_for_version
      available_versions.map { |v| [v.label, v.version_str] }
    end

    def schedule_job(report_url:)
      table = Rails.application.config.hmis_exporters || []

      job_class = if version.present?
                    table.index_by(&:version_str)[version.to_s]
                  else
                    table.first
      end&.job_class

      raise "Unable to find an HMIS Exporter for #{job_class}. Available: #{self.class.options_for_version} " unless job_class

      job_class.constantize.perform_later(options_for_job, report_url: report_url)
    end

    private def options_for_job
      {
        version: version,
        start_date: start_date.iso8601,
        end_date: end_date.iso8601,
        projects: effective_project_ids,
        period_type: period_type,
        directive: directive,
        hash_status: hash_status,
        include_deleted: include_deleted,
        faked_pii: faked_pii,
        user_id: user_id,
        recurring_hmis_export_id: recurring_hmis_export_id,
      }
    end

    def effective_project_ids
      @effective_project_ids = effective_project_ids_from_projects
      @effective_project_ids += effective_project_ids_from_project_groups
      @effective_project_ids += effective_project_ids_from_organizations
      @effective_project_ids += effective_project_ids_from_data_sources
      @effective_project_ids = all_project_ids if @effective_project_ids.empty?
      return @effective_project_ids.uniq
    end

    def effective_project_ids_from_projects
      project_ids.reject(&:blank?).map(&:to_i)
    end

    def effective_project_ids_from_project_groups
      GrdaWarehouse::ProjectGroup.joins(:projects).
        merge(GrdaWarehouse::ProjectGroup.viewable_by(user)).
        where(id: project_group_ids.reject(&:blank?).map(&:to_i)).
        pluck(p_t[:id].as('project_id').to_sql)
    end

    def effective_project_ids_from_organizations
      GrdaWarehouse::Hud::Organization.joins(:projects).
        merge(GrdaWarehouse::Hud::Project.viewable_by(user)).
        where(id: organization_ids.reject(&:blank?).map(&:to_i)).
        pluck(p_t[:id].as('project_id').to_sql)
    end

    def effective_project_ids_from_data_sources
      GrdaWarehouse::DataSource.joins(:projects).
        merge(GrdaWarehouse::Hud::Project.viewable_by(user)).
        where(id: data_source_ids.reject(&:blank?).map(&:to_i)).
        pluck(p_t[:id].as('project_id').to_sql)
    end

    def adjust_reporting_period
      case reporting_range
      when 'fixed'
        return
      when 'n_days'
        @end_date = Date.current
        @start_date = end_date - reporting_range_days.days
      when 'month'
        last_month = Date.current.last_month
        @end_date = last_month.end_of_month
        @start_date = last_month.beginning_of_month
      when 'year'
        last_year = Date.current.last_year
        @end_date = last_year.end_of_year
        @start_date = last_year.beginning_of_year
      end
    end

    def all_project_ids
      GrdaWarehouse::Hud::Project.viewable_by(user).pluck(:id)
    end

    def user
      User.find(user_id)
    end
  end
end

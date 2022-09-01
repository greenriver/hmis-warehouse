###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Filters
  class HmisExport < FilterBase
    include ArelHelper
    attribute :start_date, Date, default: 1.years.ago.to_date
    attribute :end_date, Date, default: Date.current
    attribute :version, String, default: '2022'
    attribute :hash_status, Integer, default: 1
    attribute :period_type, Integer, default: 3
    attribute :directive, Integer, default: 2
    attribute :include_deleted, Boolean, default: false
    attribute :faked_pii, Boolean, default: false
    attribute :confidential, Boolean, default: false

    attribute :every_n_days, Integer, default: 0
    attribute :reporting_range, String, default: 'fixed'
    attribute :reporting_range_days, Integer, default: 0

    attribute :recurring_hmis_export_id, Integer, default: 0

    attribute :s3_access_key_id, String
    attribute :s3_secret_access_key, String
    attribute :s3_region, String
    attribute :s3_bucket, String
    attribute :s3_prefix, String
    attribute :zip_password, String
    attribute :encryption_type, String
    attribute :_aj_symbol_keys, String

    validates_presence_of :start_date, :end_date

    validate do
      if end_date.present? && start_date.present?
        errors.add :end_date, 'must follow start date' if end_date < start_date
      end
    end

    def update(filters)
      return self unless filters.present?

      filters = filters.to_h.with_indifferent_access

      self.start_date = filters.dig(:start_date)&.to_date || start_date
      self.end_date = filters.dig(:end_date)&.to_date || end_date
      self.version = filters.dig(:version) if self.class.available_versions&.include?(filters.dig(:version))
      self.hash_status = filters.dig(:hash_status).to_i unless filters.dig(:hash_status).nil?
      self.period_type = filters.dig(:period_type).to_i unless filters.dig(:period_type).nil?
      self.directive = filters.dig(:directive).to_i unless filters.dig(:directive).nil?
      self.include_deleted = filters.dig(:include_deleted).in?(['1', 'true', true]) unless filters.dig(:include_deleted).nil?
      self.faked_pii = filters.dig(:faked_pii).in?(['1', 'true', true]) unless filters.dig(:faked_pii).nil?
      self.confidential = filters.dig(:confidential).in?(['1', 'true', true]) unless filters.dig(:confidential).nil?
      self.every_n_days = filters.dig(:every_n_days).to_i unless filters.dig(:every_n_days).nil?
      self.reporting_range = filters.dig(:reporting_range) unless filters.dig(:reporting_range).nil?
      self.reporting_range_days = filters.dig(:reporting_range_days).to_i unless filters.dig(:reporting_range_days).nil?
      self.recurring_hmis_export_id = filters.dig(:recurring_hmis_export_id).to_i unless filters.dig(:recurring_hmis_export_id).nil?
      self.s3_access_key_id = filters.dig(:s3_access_key_id) unless filters.dig(:s3_access_key_id).nil?
      self.s3_secret_access_key = filters.dig(:s3_secret_access_key) unless filters.dig(:s3_secret_access_key).nil?
      self.s3_region = filters.dig(:s3_region) unless filters.dig(:s3_region).nil?
      self.s3_bucket = filters.dig(:s3_bucket) unless filters.dig(:s3_bucket).nil?
      self.s3_prefix = filters.dig(:s3_prefix) unless filters.dig(:s3_prefix).nil?
      self.zip_password = filters.dig(:zip_password) unless filters.dig(:zip_password).nil?
      self.encryption_type = filters.dig(:encryption_type) unless filters.dig(:encryption_type).nil?

      super(filters)
    end

    def for_params
      super.deep_merge(
        filters: {
          start_date: start_date,
          end_date: end_date,
          version: version,
          hash_status: hash_status,
          period_type: period_type,
          directive: directive,
          include_deleted: include_deleted,
          faked_pii: faked_pii,
          confidential: confidential,
          every_n_days: every_n_days,
          reporting_range: reporting_range,
          reporting_range_days: reporting_range_days,
          recurring_hmis_export_id: recurring_hmis_export_id,
          s3_access_key_id: s3_access_key_id,
          s3_secret_access_key: s3_secret_access_key,
          s3_region: s3_region,
          s3_bucket: s3_bucket,
          s3_prefix: s3_prefix,
          zip_password: zip_password,
          encryption_type: encryption_type,
        },
      )
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
        confidential: confidential,
        recurring_hmis_export_id: recurring_hmis_export_id,
        options: to_h,
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
        merge(viewable_project_scope).
        where(id: project_group_ids.reject(&:blank?).map(&:to_i)).
        pluck(p_t[:id].as('project_id').to_sql)
    end

    def effective_project_ids_from_organizations
      GrdaWarehouse::Hud::Organization.joins(:projects).
        merge(viewable_project_scope).
        where(id: organization_ids.reject(&:blank?).map(&:to_i)).
        pluck(p_t[:id].as('project_id').to_sql)
    end

    def effective_project_ids_from_data_sources
      GrdaWarehouse::DataSource.joins(:projects).
        merge(viewable_project_scope).
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

    def viewable_project_scope
      return GrdaWarehouse::Hud::Project.non_confidential.viewable_by(user) unless user.can_view_confidential_project_names?

      GrdaWarehouse::Hud::Project.viewable_by(user)
    end

    def all_project_ids
      viewable_project_scope.pluck(:id)
    end

    def user
      User.find(user_id)
    end
  end
end

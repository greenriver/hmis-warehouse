###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Shared behavior for retired LSA generator stubs. These classes exist solely for
# STI resolution, file downloads, and archival support — they cannot generate new reports.
#
# Each including class must be nested under HudLsa::Generators::FyXXXX and have a
# corresponding HudLsa::FyXXXX::SummaryResult model.
module HudLsa::Generators::RetiredLsaStub
  extend ActiveSupport::Concern

  included do
    include Rails.application.routes.url_helpers

    has_one_attached :result_file
    has_one_attached :intermediate_file
    has_one :summary_result, class_name: summary_result_class_name, foreign_key: :hud_report_instance_id
    belongs_to :export, class_name: 'GrdaWarehouse::HmisExport', optional: true

    include HudLsa::Archival
  end

  class_methods do
    def fy_slug
      module_parent.name.demodulize.downcase
    end

    def fiscal_year
      "FY #{module_parent.name.demodulize.delete_prefix('Fy')}"
    end

    def summary_result_class_name
      "HudLsa::#{module_parent.name.demodulize}::SummaryResult"
    end

    def generic_title = 'Longitudinal System Analysis'
    def short_name    = 'LSA'
    def title         = "#{generic_title} - #{fiscal_year}"
    def questions     = { 'LSA' => self }.freeze

    def table_descriptions
      { 'LSA' => 'All LSA Data' }.freeze
    end

    def describe_table(table_name)
      table_descriptions[table_name]
    end

    def allowed_options(report)
      opts = [:project_ids, :project_group_ids, :data_source_ids, :coc_code, :lsa_scope]
      opts += report.hic? ? [:on] : [:start, :end]
      opts
    end

    def archival_csv_config(report_instance)
      HudReportArchival.shared_archival_entries(report_instance, prefix: 'lsa').merge(
        lsa_summary_results_csv: {
          scope: -> { summary_result_class_name.constantize.where(hud_report_instance_id: report_instance.id) },
          filename: -> { "hud-lsa-#{fy_slug}-#{report_instance.id}-summary-results.csv" },
          delete_order: 2,
        },
      )
    end
  end

  def hic?
    options&.with_indifferent_access&.dig(:lsa_scope).to_i == HudLsa::Fy2026::Report.available_lsa_scopes['HIC']
  end

  def filter
    @filter ||= HudLsa::Filters::LsaFilter.new(user_id: user_id).update(options)
  end

  def report_filename
    "#{self.class.generic_title} #{filter&.coc_code}"
  end

  def url
    if hic?
      hud_reports_lsa_hic_url(self, { host: ENV['FQDN'], protocol: 'https' })
    else
      hud_reports_lsa_url(self, { host: ENV['FQDN'], protocol: 'https' })
    end
  end
end

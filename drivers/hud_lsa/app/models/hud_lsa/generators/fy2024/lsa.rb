###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Read-only stub: retains STI resolution, file downloads, and archival support.
# FY2024 reports can no longer be generated — only historical data is accessible.
module HudLsa::Generators::Fy2024
  class Lsa < ::HudReports::ReportInstance
    include Rails.application.routes.url_helpers

    has_one_attached :result_file
    has_one_attached :intermediate_file
    has_one :summary_result, class_name: 'HudLsa::Fy2024::SummaryResult', foreign_key: :hud_report_instance_id
    belongs_to :export, class_name: 'GrdaWarehouse::HmisExport', optional: true

    def self.fiscal_year = 'FY 2024'
    def self.generic_title = 'Longitudinal System Analysis'
    def self.short_name   = 'LSA'
    def self.title        = "#{generic_title} - #{fiscal_year}"
    def self.questions    = { 'LSA' => self }.freeze
    def self.table_descriptions = { 'LSA' => 'All LSA Data' }.freeze

    def self.archival_csv_config(report_instance)
      HudReportArchival.shared_archival_entries(report_instance, prefix: 'lsa').merge(
        lsa_summary_results_csv: {
          scope: -> { HudLsa::Fy2024::SummaryResult.where(hud_report_instance_id: report_instance.id) },
          filename: -> { "hud-lsa-fy2024-#{report_instance.id}-summary-results.csv" },
          delete_order: 2,
        },
      )
    end

    include HudLsa::Archival

    def filter
      @filter ||= HudLsa::Filters::LsaFilter.new(user_id: user_id).update(options)
    end

    def report_filename
      "#{self.class.generic_title} #{filter&.coc_code}"
    end

    def hic?
      options&.with_indifferent_access&.dig(:lsa_scope).to_i == 3
    end

    def url
      if hic?
        hud_reports_lsa_hic_url(self, { host: ENV['FQDN'], protocol: 'https' })
      else
        hud_reports_lsa_url(self, { host: ENV['FQDN'], protocol: 'https' })
      end
    end
  end
end

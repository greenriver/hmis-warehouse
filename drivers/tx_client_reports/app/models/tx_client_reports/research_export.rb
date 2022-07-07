###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module TxClientReports
  class ResearchExport < GrdaWarehouseBase
    self.table_name = :tx_research_exports
    include Filter::ControlSections
    include Filter::FilterScopes
    include ArelHelper
    include Reporting::Status
    include Rails.application.routes.url_helpers

    belongs_to :user
    belongs_to :export, class_name: 'TxClientReports::ResearchExports::Export', optional: true

    scope :viewable_by, ->(user) do
      return all if user.can_view_all_reports?
      return where(user_id: user.id) if user.can_view_assigned_reports?

      none
    end

    scope :ordered, -> do
      order(updated_at: :desc)
    end

    def filter
      @filter ||= begin
        f = ::Filters::FilterBase.new(user_id: user_id)
        f.set_from_params(options['filters'].with_indifferent_access)
        f
      end
    end

    def title
      _('Offline Research Export')
    end

    def self.url
      'tx_client_reports/warehouse_reports/research_exports'
    end

    def url
      tx_client_reports_warehouse_reports_research_export_url(host: ENV.fetch('FQDN'), id: id, protocol: 'https')
    end

    def run_and_save!
      update(started_at: Time.current)
      create_export(
        user_id: filter.user_id,
        content: excel_content,
        content_type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      )
      assign_attributes(completed_at: Time.current)
      save
    end

    def describe_filter_as_html
      filter.describe_filter_as_html(
        [
          :start,
          :end,
          :project_type_codes,
          :project_ids,
          :project_group_ids,
          :data_source_ids,
          :organization_ids,
        ],
      )
    end

    private def excel_content
      controller = TxClientReports::WarehouseReports::ResearchExportsController
      assigns = { filter: filter, format: :xlsx, report: self }
      ActionController::Renderer::RACK_KEY_TRANSLATION['warden'] ||= 'warden'
      warden_proxy = Warden::Proxy.new({}, Warden::Manager.new({})).tap do |i|
        i.set_user(user, scope: :user, store: false, run_callbacks: false)
      end
      renderer = controller.renderer.new(
        'warden' => warden_proxy,
      )
      renderer.render(
        action: :index,
        layout: false,
        assigns: assigns,
      )
    end

    def rows
      report_scope.distinct.select(*enrollment_columns)
    end

    def format_demographic_value(value, index)
      case demographic_headers[index]
      when *::HUD.races.values, *::HUD.genders.values
        ::HUD.no_yes_missing(value)
      when 'Ethnicity'
        ::HUD.ethnicity(value)
      else
        value
      end
    end

    def format_enrollment_value(value, index)
      case enrollment_headers[index]
      when 'Project Type'
        ::HUD.project_type_brief(value)
      else
        value
      end
    end

    def enrollment_headers
      @enrollment_headers ||= [
        'Warehouse ID',
        'Project Type',
        'CoC Code',
        'Entry Date',
        'Exit Date',
      ].freeze
    end

    def enrollment_rows
      report_scope.
        distinct.
        pluck(*enrollment_columns)
    end

    def enrollment_columns
      [
        :client_id,
        GrdaWarehouse::ServiceHistoryEnrollment.project_type_column,
        pc_t[:CoCCode],
        :first_date_in_program,
        :last_date_in_program,
      ]
    end

    def demographic_headers
      @demographic_headers ||= begin
        headers = [
          'Warehouse ID',
          'Reporting Age', # NOTE: this is age at the latter of report start or entry
        ]
        headers += ::HUD.genders.values
        headers += ::HUD.races.values
        headers << 'Ethnicity'
        headers
      end
    end

    def demographic_rows
      report_scope.
        distinct.
        pluck(*demographic_columns)
    end

    def demographic_columns
      [
        :client_id,
        age_calculation,
        *::HUD.gender_fields.map { |k| c_t[k] },
        *::HUD.races.keys.map { |k| c_t[k] },
        c_t[:Ethnicity],
      ]
    end

    private def report_scope
      scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.joins(:client, project: :project_cocs)
      scope = filter_for_user_access(scope)
      scope = filter_for_range(scope)
      scope = filter_for_cocs(scope)
      scope = filter_for_data_sources(scope)
      scope = filter_for_organizations(scope)
      scope = filter_for_projects(scope)
      scope = filter_for_project_type(scope)

      scope
    end
  end
end

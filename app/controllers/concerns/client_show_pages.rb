###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientShowPages
  extend ActiveSupport::Concern
  include ActionView::Helpers::TagHelper
  include ActionView::Context

  included do
    include ArelHelper

    def title_for_show
      @client.full_name
    end
    alias_method :title_for_edit, :title_for_show
    alias_method :title_for_destroy, :title_for_show
    alias_method :title_for_update, :title_for_show
    alias_method :title_for_merge, :title_for_show
    alias_method :title_for_unmerge, :title_for_show

    # ajaxy method to render a particular rollup table
    def rollup
      allowed_rollups = [
        '/clients/rollup/assessments',
        '/clients/rollup/verifications',
        '/clients/rollup/assessments_without_data',
        '/clients/rollup/case_manager',
        '/clients/rollup/chronic_days',
        '/clients/rollup/contact_information',
        '/clients/rollup/demographics',
        '/clients/rollup/disabilities',
        '/clients/rollup/disability_types',
        '/clients/rollup/entry_assessments',
        '/clients/rollup/error',
        '/clients/rollup/exit_assessments',
        '/clients/rollup/family',
        '/clients/rollup/income_benefits',
        '/clients/rollup/ongoing_residential_enrollments',
        '/clients/rollup/other_enrollments',
        '/clients/rollup/residential_enrollments',
        '/clients/rollup/services',
        '/clients/rollup/services_full',
        '/clients/rollup/services_all',
        '/clients/rollup/special_populations',
        '/clients/rollup/zip_details',
        '/clients/rollup/zip_map',
        '/clients/rollup/client_notes',
        '/clients/rollup/chronic_notes',
        '/clients/rollup/cohorts',
        '/clients/rollup/ce_assessments',
        '/clients/rollup/enrollment_cocs',
        '/clients/rollup/current_living_situations',
        '/clients/rollup/ce_events',
        '/clients/rollup/employment_education',
        '/clients/rollup/hmis_clients',
      ]
      rollup = allowed_rollups.detect do |m|
        m == '/clients/rollup/' + params.require(:partial).underscore
      end

      raise 'Rollup not in allowlist' unless rollup.present?

      render partial: rollup, layout: false if request.xhr?
    end

    def js_clients
      @js_clients ||= if can_view_confidential_enrollment_details?
        source_clients.each_with_index.map { |c, i| [c.id, [i, c.uuid, c.data_source&.short_name, c.organizations.map(&:name).to_sentence]] }.to_h
      else
        source_clients.each_with_index.map do |c, i|
          [
            c.id,
            [
              i,
              c.uuid,
              c.data_source&.short_name,
              c.organizations.map { |o| o.name unless contains_confidential_projects?(o) }.compact.to_sentence,
            ],
          ]
        end.to_h
      end
      @js_clients
    end
    helper_method :js_clients

    private def contains_confidential_projects?(organization)
      source_clients.joins(enrollments: :project).
        merge(
          GrdaWarehouse::Hud::Project.confidential.where(
            OrganizationID: organization.OrganizationID,
            data_source_id: organization.data_source_id,
          ),
        ).exists?
    end

    def source_clients
      @source_clients ||= @client.source_clients.source_visible_to(current_user, client_ids: @client.source_client_ids).preload(:data_source, :organizations)
    end
    helper_method :source_clients

    def ds_short_name_for(source_client_id)
      js_clients.dig(source_client_id, 2)
    end
    helper_method :ds_short_name_for

    private def source_client_personal_id_from(source_client_id)
      js_clients.dig(source_client_id, 1)
    end

    private def org_name_for(source_client_id)
      js_clients.dig(source_client_id, 3)
    end

    def ds_tooltip_content(source_client_id, ds_id)
      content_tag(:div) do
        content_tag(:div, org_name_for(source_client_id), class: :org) +
        content_tag(:div) do
          [
            'PersonalID: ',
            content_tag(:span, source_client_personal_id_from(source_client_id), class: :pid),
          ].join.html_safe
        end +
        content_tag(:div, "Data source: #{ds_id}", class: :data_source_id) +
        content_tag(:div, "Source Client ID: #{source_client_id}", class: :source_client_id) +
        content_tag(:span) do
          content_tag(:i) do
            'click to copy personal id'
          end
        end
      end

      # <div><div class="org"/>PersonalID: <span class="pid"/><br>Data source: <span class="data_source_id"/><br>Source Client ID: <span class="source_client_id"/><br><i>click to copy personal id</i></div>
    end
    helper_method :ds_tooltip_content
  end
end

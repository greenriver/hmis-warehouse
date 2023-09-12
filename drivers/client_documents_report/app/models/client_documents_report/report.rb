###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientDocumentsReport
  class Report
    include Filter::ControlSections
    include Filter::FilterScopes
    include ActionView::Helpers::NumberHelper
    include ArelHelper

    attr_accessor :filter

    def initialize(filter)
      @filter = filter
    end

    def self.url
      'client_documents_report/warehouse_reports/reports'
    end

    def self.default_project_type_codes
      HudUtility2024.performance_reporting.keys
    end

    # Find the most recent date from the documents of the appropriate type in the chosen group
    # for the client
    def date_for_group(group, client, type:)
      groups = groups_for_type(type)
      tags = groups[group]
      documents = documents_for_type(type, client)
      relevant_documents = documents.select do |d|
        (d.taggings.flat_map(&:tag).map(&:name) & tags).present?
      end
      relevant_documents.map { |d| d.effective_date.presence || d.created_at.to_date }.max
    end

    def date_for_tag(tag, client, type:)
      documents = documents_for_type(type, client)
      relevant_documents = documents.select do |d|
        d.taggings.flat_map(&:tag).map(&:name).include?(tag)
      end
      relevant_documents.map { |d| d.effective_date.presence || d.created_at.to_date }.max
    end

    def groups_for_type(type)
      return required_tag_names_by_group if type == :required

      optional_tag_names_by_group
    end

    def documents_for_type(type, client)
      return required_documents(client) if type == :required

      optional_documents(client)
    end

    def total_required_documents
      @total_required_documents ||= filter.required_files.select(&:present?).count
    end

    def total_required_document_groups
      required_tag_names_by_group.count
    end

    def required_documents(client)
      client.client_files&.select { |cf| (cf.taggings.map(&:tag_id) & filter.required_files).present? }
    end

    def required_tag_names_by_group
      tags(:required).map do |tag|
        group = available_tags[tag.name]
        next unless group.present?

        [
          group,
          tag.name,
        ]
      end.compact.group_by(&:shift).transform_values(&:flatten)
    end

    private def tags(type)
      ids = if type == :required
        filter.required_files
      else
        filter.optional_files
      end
      ActsAsTaggableOn::Tag.where(id: ids)
    end

    def total_optional_documents
      @total_optional_documents ||= filter.optional_files.select(&:present?).count
    end

    def total_optional_document_groups
      optional_tag_names_by_group.count
    end

    def optional_documents(client)
      client.client_files&.select { |cf| (cf.taggings.map(&:tag_id) & filter.optional_files).present? }
    end

    def optional_tag_names_by_group
      tags(:optional).map do |tag|
        group = available_tags[tag.name]
        next unless group.present?

        [
          group,
          tag.name,
        ]
      end.compact.group_by(&:shift).transform_values(&:flatten)
    end

    def total_overall_documents
      @total_overall_documents ||= overall_document_tag_ids.select(&:present?).count
    end

    def total_overall_document_groups
      overall_tag_ids_by_group.count
    end

    def overall_documents(client)
      client.client_files&.select { |cf| (cf.taggings.map(&:tag_id) & overall_document_tag_ids).present? }
    end

    private def overall_document_tag_ids
      @overall_document_tag_ids ||= (filter.required_files + filter.optional_files).uniq
    end

    private def overall_tag_ids_by_group
      available_tags.to_a.map(&:reverse).group_by(&:shift)
    end

    private def available_tags
      @available_tags ||= GrdaWarehouse::AvailableFileTag.
        where(name: tags(:required).map(&:name) + tags(:optional).map(&:name)).
        pluck(:name, :group).to_h
    end

    def include_comparison?
      false
    end

    def report_path_array
      [
        :client_documents_report,
        :warehouse_reports,
        :reports,
      ]
    end

    def self.viewable_by(user)
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url).
        viewable_by(user).exists?
    end

    def multiple_project_types?
      true
    end

    def filter_path_array
      [:filters] + report_path_array
    end

    protected def build_control_sections
      [
        build_general_control_section,
        build_coc_control_section,
        build_files_control_section,
      ]
    end

    def total_client_count
      @total_client_count ||= clients.count
    end

    def clients
      GrdaWarehouse::Hud::Client.where(id: enrollments.select(:client_id)).
        preload(client_files: { taggings: [:tag] })
    end

    def enrollments
      filter.apply(report_scope_base, report_scope_base)
    end

    def report_scope_base
      GrdaWarehouse::ServiceHistoryEnrollment.entry
    end
  end
end

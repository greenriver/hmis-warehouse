###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisUtil
  # Reports HUD data that exists in the warehouse but would not be visible in HMIS, because
  # the element carrying it is not HUD-required for the project holding it and so is absent
  # from that project's forms without an installation-specific patch.
  #
  # Comparison is against the theoretical HUD minimum -- the rules in
  # HudAssessmentFormRules2026 and the applicability config on HudUtility -- rather than
  # live Form::Instance records, so results are unaffected by patches already seeded in
  # whatever environment this runs in.
  #
  # Read-only: nothing is written, and the scan uses aggregate SQL only.
  class HudDataCollectionGapAnalyzer
    Result = Struct.new(:summary_rows, :field_gap_rows, :form_gap_rows, keyword_init: true)

    CURRENT_LIVING_SITUATION_FORM = 'Current Living Situation'
    SERVICE_FORM = 'Service'

    # Every sub-record table the summary sheet reports presence counts for: the five
    # record types with HUD-required *elements* (ElementRegistry), plus Current Living
    # Situation and Service, which only ever get accepted or rejected as a whole form
    # rather than scanned field by field.
    SUMMARY_ASSOCIATIONS = (
      ElementRegistry::RECORD_TYPE_ASSOCIATIONS.values + [:current_living_situations, :services]
    ).freeze

    attr_reader :data_source, :date_range

    # @param data_source [GrdaWarehouse::DataSource]
    # @param date_range [Range<Date>]
    def initialize(data_source:, date_range:)
      @data_source = data_source
      @date_range = date_range
    end

    # @return [Result]
    def perform
      summary_rows = []
      field_gap_rows = []
      form_gap_rows = []

      projects.find_each do |project|
        scanner = DataPresenceScanner.new(project: project, date_range: date_range)
        summary_rows << summary_row(project, scanner)
        field_gap_rows.concat(field_gaps(project, scanner))
        form_gap_rows.concat(form_gaps(project, scanner))
      end

      Result.new(
        summary_rows: summary_rows,
        field_gap_rows: field_gap_rows,
        form_gap_rows: form_gap_rows,
      )
    end

    protected

    def projects
      GrdaWarehouse::Hud::Project.
        where(data_source_id: data_source.id).
        within_range(date_range).
        preload(:funders)
    end

    def registry
      @registry ||= ElementRegistry.new
    end

    def summary_row(project, scanner)
      row = project_identity(project)
      SUMMARY_ASSOCIATIONS.each do |association_name|
        presence = scanner.table_presence(association_name)
        row[:"#{association_name}_count"] = presence.count
        row[:"#{association_name}_earliest"] = presence.earliest
        row[:"#{association_name}_latest"] = presence.latest
      end
      row
    end

    def field_gaps(project, scanner)
      required = required_link_ids(project)

      registry.assessment_elements.filter_map do |element|
        next if element.link_id.in?(required.fetch(element.role))

        presence = scanner.field_presence(element)
        next unless presence.any?

        project_identity(project).merge(
          role: element.role,
          link_id: element.link_id,
          record_type: element.record_type,
          field_name: element.field_name,
          count: presence.count,
          earliest: presence.earliest,
          latest: presence.latest,
        )
      end
    end

    def form_gaps(project, scanner)
      matcher = ApplicabilityMatcher.new(project: project, funder_codes: funder_codes(project))
      rows = []

      unless matcher.current_living_situation_required?
        presence = scanner.table_presence(:current_living_situations)
        if presence.any?
          rows << project_identity(project).merge(
            form: CURRENT_LIVING_SITUATION_FORM,
            record_type: nil,
            count: presence.count,
            earliest: presence.earliest,
            latest: presence.latest,
          )
        end
      end

      required_record_types = matcher.required_service_record_types
      scanner.service_presence_by_record_type.each do |record_type, presence|
        next if record_type.in?(required_record_types)
        next unless presence.any?

        rows << project_identity(project).merge(
          form: SERVICE_FORM,
          record_type: record_type,
          count: presence.count,
          earliest: presence.earliest,
          latest: presence.latest,
        )
      end

      rows
    end

    # Which link ids HUD requires for this project, per assessment role.
    #
    # Requiredness cannot be read off an element: HUD rules attach to ancestor groups, and
    # a group whose rule fails takes its whole subtree with it. So run the real filter over
    # the rule-annotated tree and keep whatever survives -- the same approach as
    # drivers/hmis/lib/tasks/form_definition_psde_alignment_report.rake.
    #
    # @return [Hash{Symbol => Set<String>}]
    def required_link_ids(project)
      ElementRegistry::ASSESSMENT_ROLES.index_with do |role|
        filtered = Hmis::Form::DefinitionItemFilter.perform(
          definition: registry.definition_tree(role),
          project: project,
          project_funders: project.funders.to_a,
          active_date: nil,
        )
        collect_link_ids(filtered)
      end
    end

    # @return [Set<String>]
    def collect_link_ids(node)
      return Set.new if node.blank?

      link_ids = Set.new
      walk = lambda do |item|
        link_ids << item['link_id'] if item['link_id'].present?
        item['item']&.each { |child| walk.call(child) }
      end
      walk.call(node)
      link_ids
    end

    # Sorted so two projects with the same set of funders produce identical
    # #project_identity funder strings regardless of Funder row insertion order --
    # otherwise the rollup sheet's grouping would fragment by that arbitrary order.
    def funder_codes(project)
      project.funders.filter_map { |funder| funder.Funder&.to_i }.sort
    end

    def project_identity(project)
      {
        project_id: project.id,
        project_name: project.ProjectName,
        project_type: project.project_type,
        project_type_name: HudHelper.util.project_type(project.project_type),
        funders: funder_codes(project).map { |code| HudHelper.util.funding_source(code) }.join('; '),
        funder_components: funder_codes(project).filter_map { |code| HudHelper.util.funder_component(code) }.uniq.join('; '),
      }
    end
  end
end

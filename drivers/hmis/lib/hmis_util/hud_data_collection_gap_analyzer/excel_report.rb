###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisUtil
  class HudDataCollectionGapAnalyzer
    # Renders an analyzer Result as a four-sheet workbook: a per-project summary, the two
    # gap lists, and a rollup that merges those two lists into one, sorted by funder /
    # project type / element so the projects needing the same form patch sit together.
    class ExcelReport
      IDENTITY_HEADERS = [
        [:project_id, 'Project ID'],
        [:project_name, 'Project Name'],
        [:project_type, 'Project Type'],
        [:project_type_name, 'Project Type Name'],
        [:funders, 'Funders'],
        [:funder_components, 'Funder Components'],
      ].freeze

      PRESENCE_HEADERS = [
        [:count, 'Records With Data'],
        [:earliest, 'Earliest Date'],
        [:latest, 'Latest Date'],
      ].freeze

      FIELD_GAP_HEADERS = (
        IDENTITY_HEADERS + [
          [:role, 'Assessment'],
          [:link_id, 'Link ID'],
          [:record_type, 'Record Type'],
          [:field_name, 'Field'],
        ] + PRESENCE_HEADERS
      ).freeze

      FORM_GAP_HEADERS = (
        IDENTITY_HEADERS + [
          [:form, 'Form'],
          [:record_type, 'Service Record Type'],
        ] + PRESENCE_HEADERS
      ).freeze

      ROLLUP_HEADERS = (
        IDENTITY_HEADERS + [[:element, 'Element']] + PRESENCE_HEADERS
      ).freeze

      attr_reader :result

      # @param result [HudDataCollectionGapAnalyzer::Result]
      def initialize(result:)
        @result = result
      end

      # @return [Axlsx::Package]
      def package
        Axlsx::Package.new do |package|
          workbook = package.workbook
          header_style = workbook.styles.add_style(b: true)

          add_summary_sheet(workbook, header_style)
          add_rows_sheet(workbook, header_style, 'Field-Level Gaps', FIELD_GAP_HEADERS, result.field_gap_rows)
          add_rows_sheet(workbook, header_style, 'Form-Level Gaps', FORM_GAP_HEADERS, result.form_gap_rows)
          add_rows_sheet(workbook, header_style, 'Patch Targeting Rollup', ROLLUP_HEADERS, rollup_rows)
        end
      end

      protected

      def summary_headers
        return IDENTITY_HEADERS if result.summary_rows.empty?

        presence_keys = result.summary_rows.first.keys - IDENTITY_HEADERS.map(&:first)
        IDENTITY_HEADERS + presence_keys.map { |key| [key, key.to_s.titleize] }
      end

      def add_summary_sheet(workbook, header_style)
        add_rows_sheet(workbook, header_style, 'Summary', summary_headers, result.summary_rows)
      end

      def add_rows_sheet(workbook, header_style, name, headers, rows)
        workbook.add_worksheet(name: name) do |sheet|
          sheet.add_row(headers.map(&:last), style: header_style)
          rows.each do |row|
            sheet.add_row(headers.map { |key, _| row[key] })
          end
        end
      end

      # One row per project per gap -- the same data as the Field/Form gap sheets, merged
      # and sorted so every project that needs the same patch (same funder combination,
      # project type, and element) sits together.
      def rollup_rows
        gap_rows = result.field_gap_rows.map { |row| row.merge(element: "#{row[:record_type]} / #{row[:link_id]}") } +
          result.form_gap_rows.map { |row| row.merge(element: [row[:form], row[:record_type]].compact.join(' / ')) }

        gap_rows.sort_by { |row| [row[:funders].to_s, row[:project_type_name].to_s, row[:element].to_s, row[:project_name].to_s] }
      end
    end
  end
end

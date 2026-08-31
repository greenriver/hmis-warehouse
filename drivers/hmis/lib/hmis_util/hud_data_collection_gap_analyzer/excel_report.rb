###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisUtil
  class HudDataCollectionGapAnalyzer
    # Renders an analyzer Result as a four-sheet workbook: a per-project summary, the two
    # gap lists, and a rollup that groups gaps by funder / project type / element so a
    # developer can tell whether a patch should target a funder, a project type, or a
    # handful of named projects.
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

      ROLLUP_HEADERS = [
        ['Funders', 'Project Type Name', 'Element', 'Projects Affected', 'Records With Data', 'Project Names'],
      ].freeze

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
          add_rollup_sheet(workbook, header_style)
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

      def add_rollup_sheet(workbook, header_style)
        workbook.add_worksheet(name: 'Patch Targeting Rollup') do |sheet|
          sheet.add_row(ROLLUP_HEADERS.first, style: header_style)
          rollup_rows.each { |row| sheet.add_row(row) }
        end
      end

      def rollup_rows
        gap_rows = result.field_gap_rows.map { |row| row.merge(element: "#{row[:record_type]} / #{row[:link_id]}") } +
          result.form_gap_rows.map { |row| row.merge(element: [row[:form], row[:record_type]].compact.join(' / ')) }

        gap_rows.
          group_by { |row| [row[:funders], row[:project_type_name], row[:element]] }.
          map do |(funders, project_type_name, element), rows|
            [
              funders,
              project_type_name,
              element,
              rows.map { |row| row[:project_id] }.uniq.size,
              rows.sum { |row| row[:count] },
              rows.map { |row| row[:project_name] }.uniq.sort.join('; '),
            ]
          end.
          sort_by { |row| [-row[3], row[2].to_s] }
      end
    end
  end
end

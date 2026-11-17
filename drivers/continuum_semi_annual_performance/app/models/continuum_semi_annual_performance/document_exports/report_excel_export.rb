###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ContinuumSemiAnnualPerformance::DocumentExports
  class ReportExcelExport < ::GrdaWarehouse::DocumentExport
    include ApplicationHelper

    include ExportsVisibleReport

    def perform
      with_status_progression do
        self.filename = "#{report.title} - #{report.coc_code} - #{Time.current.to_fs(:db)}.xlsx"
        self.file_data = excel_package.to_stream.read
        self.mime_type = EXCEL_MIME_TYPE
      end
    end

    private def excel_package
      Axlsx::Package.new do |package|
        styles = export_styles(package.workbook.styles)
        selected_tabs.each do |tab_key|
          package.workbook.add_worksheet(name: sheet_name(tab_key)) do |sheet|
            if tab_key == :summary
              add_summary_rows(sheet, styles)
            else
              add_tab_rows(sheet, styles, report.rows_for(tab_key))
            end
          end
        end
        add_report_info(package.workbook, styles)
      end
    end

    private def sheet_name(tab_key)
      tab_key == :summary ? 'Summary' : tab_key.to_s.upcase
    end

    private def export_styles(wb_styles)
      {
        bold: wb_styles.add_style(b: true),
        italic: wb_styles.add_style(i: true, alignment: { indent: 1 }),
        count: wb_styles.add_style(format_code: '#,##0'),
        decimal: wb_styles.add_style(format_code: '0.00'),
        percent: wb_styles.add_style(format_code: '0.00%'),
        title: wb_styles.add_style(sz: 14),
        label: wb_styles.add_style(bg_color: '81adb9', b: true, border: { style: :thin, color: 'FFFFFF', edges: [:bottom, :top] }),
      }
    end

    private def add_summary_rows(sheet, styles)
      sheet.add_row(['Project type', 'Projects', 'Persons served', 'Households served'], style: styles[:bold])
      report.summary_rows.each do |row|
        sheet.add_row(
          [
            ContinuumSemiAnnualPerformance::ReportsHelper.tab_title(row[:project_type]),
            row[:projects].to_i,
            row[:persons].to_i,
            row[:households].to_i,
          ],
          style: [nil, styles[:count], styles[:count], styles[:count]],
        )
      end
    end

    private def add_tab_rows(sheet, styles, rows)
      rows.each do |row|
        if row.header
          sheet.add_row([row.label], style: row.level.to_i == 1 ? styles[:bold] : styles[:italic])
        else
          sheet.add_row([row.label, row.value], style: [nil, styles[row.format.to_sym]])
        end
      end
    end

    private def add_report_info(workbook, styles)
      workbook.add_worksheet(name: 'Report Info') do |sheet|
        sheet.add_row([report.title], style: styles[:title])
        report.filter.describe_filter(report.known_params).each do |title, value|
          value = value.join(', ') if value.is_a?(Array)
          sheet.add_row(["#{title}:", value], style: [styles[:label], nil])
        end
      end
    end
  end
end

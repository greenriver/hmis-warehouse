# frozen_string_literal: true

module HudSpmReport
  class CellExportJob < ::BaseJob
    require 'axlsx'
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    def perform(user_id:, report_id:, measure_id:, cell_id:, table:)
      user = User.find(user_id)
      report = HudReports::ReportInstance.find(report_id)

      # Determine generator class
      generator_class = possible_generator_classes[report_version(report)]
      generator = generator_class.new(report)

      # Setup vars
      question = generator.valid_question_number(measure_id)
      cell = report.valid_cell_name(cell_id)
      name = "#{generator.file_prefix} #{question} #{cell}"
      headers = generator.column_headings(question)

      # Build scope
      scope = generator.client_scope(question).
        joins(hud_reports_universe_members: { report_cell: :report_instance }).
        merge(::HudReports::ReportCell.for_table(table).for_cell(cell)).
        merge(::HudReports::ReportInstance.where(id: report.id)).
        distinct

      # Preload
      clients = scope.preload(client: [:data_source, :source_clients])

      # Generate XLSX
      package = Axlsx::Package.new
      wb = package.workbook
      wb.add_worksheet(name: name.slice(0, 30).gsub(':', ' ')) do |sheet|
        title = sheet.styles.add_style(sz: 12, b: true, alignment: { horizontal: :center })

        # Adjust headers (stringify and remove PII if configured)
        final_headers = headers.transform_keys(&:to_s)
        unless GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)
          final_headers = final_headers.except(*generator.pii_columns)
        end

        sheet.add_row(final_headers.values, style: title)

        # Preload policies
        user.policy_context.preload_project_dependencies(clients.map(&:project_id).uniq)

        clients.each do |client|
          pii_policy = user.reporting_policy_for_project(project_id: client.project_id, mode: :download)
          row = []
          final_headers.each_key do |k|
            row << client.display_value(k, pii_policy: pii_policy, include_content_tag: false)
          end
          sheet.add_row(row)
        end
      end

      # Save to ActiveStorage
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new(package.to_stream.string),
        filename: "#{name}.xlsx",
        content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
      )

      # Send Email
      HudSpmReport::Mailer.export_ready(user, blob, name).deliver_now
    end

    private

    def possible_generator_classes
      {
        fy2020: HudSpmReport::Generators::Fy2020::Generator,
        fy2023: HudSpmReport::Generators::Fy2023::Generator,
        fy2024: HudSpmReport::Generators::Fy2024::Generator,
        fy2026: HudSpmReport::Generators::Fy2026::Generator,
      }
    end

    def report_version(report)
      (report.options['report_version'].presence || 'fy2024').to_sym
    end
  end
end

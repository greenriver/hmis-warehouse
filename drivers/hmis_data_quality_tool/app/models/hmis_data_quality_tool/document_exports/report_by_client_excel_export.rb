###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisDataQualityTool::DocumentExports
  class ReportByClientExcelExport < ::GrdaWarehouse::DocumentExport
    include ApplicationHelper
    def authorized?
      user.can_view_any_reports? && report_class.viewable_by(user) && report.present?
    end

    protected def report
      @report ||= report_class.visible_to(user).find_by(id: params['id'])
    end

    protected def pivot_details
      @pivot_details ||= report.pivot_details
    end

    protected def clients
      @clients ||= report.clients.order(:last_name, :first_name)
    end

    protected def include_names?
      GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)
    end

    protected def policy_project_ids
      @policy_project_ids ||= report.policy_project_ids_by_destination_client(user: user)
    end

    protected def preload_pii_dependencies
      policy_context = user.policy_context
      policy_context.preload_project_dependencies(policy_project_ids.values.uniq)
      policy_context.preload_client_dependencies(clients.map(&:destination_client_id_for_pii))
    end

    # Last and first name as the exporting user may download them for this client.
    # A client with no project in the report gets DenyPiiPolicy; reporting_policy_for_project would allow names for a nil project.
    protected def name_cells(client)
      project_id = policy_project_ids[client.destination_client_id]
      pii_policy = if project_id.nil?
        GrdaWarehouse::AuthPolicies::DenyPiiPolicy.instance
      else
        user.reporting_policy_for_project(
          project_id: project_id,
          mode: :download,
          client_id: client.destination_client_id_for_pii,
        )
      end
      [
        GrdaWarehouse::PiiProvider.viewable_name(client.last_name, policy: pii_policy),
        GrdaWarehouse::PiiProvider.viewable_name(client.first_name, policy: pii_policy),
      ]
    end

    def perform
      with_status_progression do
        self.filename = "#{Translation.translate('HMIS Data Quality Tool')} - By-Client - #{Time.current.to_fs(:db)}.xlsx"
        self.file_data = excel_package.to_stream.read
        self.mime_type = EXCEL_MIME_TYPE
      end
    end

    private def excel_package
      Axlsx::Package.new do |package|
        wb = package.workbook

        wb.add_worksheet(name: 'test') do |sheet|
          groups = [
            ['', '', '', ''],
          ]
          merges = [
            [0, 3],
          ]
          pivot_details.groups.each do |(title, group)|
            group = Array.new(group.size).map.with_index do |_, i|
              i == 0 ? title : ''
            end
            merge_index_start = merges.last.last + 1
            merge_index_end = merge_index_start + group.size - 1
            merges.push([merge_index_start, merge_index_end])
            groups.push(group)
          end
          sheet.add_row(groups.flatten)

          letters = ('A'..'Z').to_a
          letter_size = letters.size
          merges = merges.map do |merge|
            merge.map do |i|
              if i < letter_size
                "#{letters[i]}1"
              else
                "#{letters[(i / letter_size) - 1]}#{letters[(i % letter_size)]}1"
              end
            end
          end

          merges.each do |merge|
            sheet.merge_cells(merge.join(':'))
          end

          header = if include_names?
            [
              '',
              'Personal ID',
              'Last Name',
              'First Name',
            ]
          else
            [
              '',
              'Personal ID',
            ]
          end

          pivot_details.groups.values.map(&:keys).flatten.each do |key|
            header.push(pivot_details.lookup[key])
          end
          sheet.add_row(header)

          preload_pii_dependencies if include_names?
          clients.each do |client|
            row = []
            if pivot_details.clients_with_flags.include?([client.personal_id, client.data_source_id])
              row.push('⚠')
            else
              row.push('')
            end
            row.push(client.personal_id)
            row += name_cells(client) if include_names?
            pivot_details.groups.values.map(&:keys).flatten.each do |key|
              marked = pivot_details.flags[pivot_details.lookup[key]].include?([client.personal_id, client.data_source_id])
              if marked
                row.push('✕')
              else
                row.push('')
              end
            end
            sheet.add_row(row)
          end
        end
      end
    end

    protected def report_class
      HmisDataQualityTool::Report
    end
  end
end

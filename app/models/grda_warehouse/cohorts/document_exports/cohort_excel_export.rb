# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::Cohorts::DocumentExports
  # Handles export of cohort data to Excel files (.xlsx) format
  #
  # This class is responsible for:
  # - Validating user authorization for cohort downloads
  # - Collecting cohort data based on specified population parameters
  # - Rendering an Excel workbook using the axlsx template engine
  # - Creating a downloadable file with proper naming and MIME type
  class CohortExcelExport < ::GrdaWarehouse::DocumentExport
    include ApplicationHelper
    def authorized?
      user.can_download_cohorts?
    end

    protected def cohort
      @cohort ||= cohort_class.viewable_by(user).find(params['id'])
    end

    protected def cohort_clients
      cohort.search_clients(population: population, user: user)
    end

    protected def population
      params['population'] ||= 'Active Clients'
    end

    protected def cohort_names
      @cohort_names ||= cohort_class.pluck(:id, :name, :short_name).
        map do |id, name, short_name|
        [id, short_name.presence || name]
      end.to_h
    end

    def perform
      with_status_progression do
        self.filename = "Cohort - #{cohort.name} - #{params['population']} - #{Time.current.to_fs(:db)}.xlsx"
        self.file_data = excel_package.to_stream.read
        self.mime_type = EXCEL_MIME_TYPE
      end
    end

    private def excel_package
      Axlsx::Package.new do |package|
        wb = package.workbook
        wb.add_worksheet(name: cohort.sanitized_name.slice(0, 30)) do |sheet|
          title = sheet.styles.add_style(sz: 12, b: true, alignment: { horizontal: :center })
          sheet.add_row(['Warehouse Client ID', 'Alerts'] + cohort.visible_columns(user: user).map(&:title), style: title)
          cohort_clients.each do |cohort_client|
            row = [cohort_client.client_id]
            row += ([CohortColumns::Meta.new] + cohort.visible_columns(user: user)).map do |column|
              column.cohort = cohort
              column.cohort_names = cohort_names
              column.cohort_client = cohort_client
              if column.renderer == 'html'
                column.text_value(cohort_client)
              elsif column.input_type == 'read_only'
                if column.value_requires_user?
                  column.value(cohort_client, user)
                else
                  column.value(cohort_client)
                end
              elsif column.input_type == 'notes'
              elsif column.input_type == 'enrollment_tag'
                column.value(cohort_client)&.map(&:last)&.join('; ')
              else
                cohort_client.public_send(column.column)
              end
            end
            sheet.add_row(row)
          end
        end
      end
    end

    protected def cohort_class
      GrdaWarehouse::Cohort
    end

    def generator_url
      cohort_path(cohort)
    end
  end
end

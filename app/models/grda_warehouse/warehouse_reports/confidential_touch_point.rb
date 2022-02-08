###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::WarehouseReports
  class ConfidentialTouchPoint < TouchPoint

    def title
      'Confidential Touch Point Export'
    end

    def url
      warehouse_reports_confidential_touch_point_exports_url(host: ENV.fetch('FQDN'), protocol: 'https')
    end

    # Convert the complex data structure to an array of arrays
    # for easier storage and Excel export
    def clean_data(dirty)
      @cleaned_data ||= begin
        clean = {
          summary: [],
          headers: [],
          data: [],
        }
        section_columns = sections(dirty).map do |title, questions|
          column_count = questions.size - 1
          column_count = 0 if column_count < 0
          [title] + [nil]*(column_count)
        end
        clean[:summary] = ['Selected Range:', start_date, end_date] + section_columns.flatten
        clean[:headers] = ["Client ID", 'Medicaid ID', "Client Name", "Collected On", "Location", 'SDH Enroll Date', "Staff"] + all_questions(dirty)
        # NOTE: this is still a second query, but should not bring back the big answers blob a second time
        limited_responses.find_each do |response|
          row = []
          client_id = response.client.destination_client.id
          client_name = response.client.destination_client.name
          enroll_date = patients[client_id]&.careplans&.sorted&.first&.sdh_enroll_date
          medicaid_id = patients[client_id]&.medicaid_id

          row << client_id
          row << medicaid_id
          row << client_name
          row << response.collected_at
          row << response.hmis_assessment.site_name
          row << enroll_date
          row << response.staff
          sections(dirty).each do |title, questions|
            questions.each do |question|
              row << dirty.dig(:sections, title, question, client_id, response.id)
            end
          end
          clean[:data] << row
        end
        clean
      end
    end

    def touch_point_source
      GrdaWarehouse::HmisForm.health_touch_points
    end

    def patients
      @patients ||= ::Health::Patient.where(client_id: client_ids.to_a).
        joins(:careplans).
        index_by(&:client_id)
    end
  end
end

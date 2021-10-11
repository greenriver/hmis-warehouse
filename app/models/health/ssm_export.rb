###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: None - contains no PHI
module Health
  class SsmExport < HealthBase
    include Rails.application.routes.url_helpers
    acts_as_paranoid

    belongs_to :user, optional: true

    def filter
      @filter ||= ::Filters::DateRange.new(options)
    end

    def title
      'SSM Export'
    end

    def url
      warehouse_reports_health_ssm_exports_url(host: ENV.fetch('FQDN'), protocol: 'https')
    end

    def status
      if started_at.blank?
        "Queued at #{started_at}"
      elsif started_at.present? && completed_at.blank?
        if started_at < 24.hours.ago
          'Failed'
        else
          "Running since #{started_at}"
        end
      elsif completed?
        "Complete"
      end
    end

    def run_and_save!
      update(started_at: Time.current)
      update(
        headers: headers_for_report,
        rows: rows_for_export,
        completed_at: Time.current,
      )
    end

    def completed?
      completed_at.present?
    end

    def hmis_touch_point_scope
      GrdaWarehouse::HmisForm.health.self_sufficiency.within_range(filter.range)
    end

    def touch_point_scope
      GrdaWarehouse::HMIS::Assessment.confidential
    end

    def headers_for_report
      {
        "SSM from Care Hub" => [
          range_headers,
          carehub_headers,
        ],
        "SSM from EPIC" => [
          range_headers,
          epic_headers,
        ],
        "SSM from HMIS" => [
          range_headers,
          hmis_headers,
        ],
      }
    end

    def rows_for_export
      {
        "SSM from Care Hub" => carehub_rows,
        "SSM from EPIC" => epic_rows,
        "SSM from HMIS" => hmis_rows,
      }
    end

    private def range_headers
      ['Selected Range:', filter.start, filter.end]
    end

    private def carehub_headers
      ssm = Health::SelfSufficiencyMatrixForm.new
      questions = Health::SelfSufficiencyMatrixForm::SECTIONS.keys.map do |key|
        ssm.ssm_question_title("#{key}_score")
      end
      ["Client ID", 'Medicaid ID', "Patient Name", "Completed On", "Location", 'SDH Enroll Date', "Staff"] + questions
    end

    private def epic_headers
      ["Client ID", 'Medicaid ID', "Patient Name", "Updated On", "Location", 'SDH Enroll Date', "Staff", 'Part 1', 'Part 2', 'Part 3']
    end

    private def hmis_headers
      ["Client ID", 'Medicaid ID', "Client Name", "Collected On", "Location", 'SDH Enroll Date', "Staff"] + hmis_data[:questions].to_a
    end

    private def carehub_rows
      @carehub_rows ||= ssms.map do |ssm|
        row = []
        client_id = ssm.patient.client.id
        client_name = ssm.patient.client.name
        enroll_date = patients[client_id]&.careplans&.sorted&.first&.sdh_enroll_date
        medicaid_id = patients[client_id]&.medicaid_id
        row << client_id
        row << medicaid_id
        row << client_name
        row << ssm.completed_at.to_date
        row << 'Care Hub'
        row << enroll_date
        row << ssm.user&.name
        Health::SelfSufficiencyMatrixForm::SECTIONS.keys.each do |key|
          row << ssm["#{key}_score"]
        end
        row
      end
    end

    private def epic_rows
      epic_ssms.map do |ssm|
        row = []
        client_id = ssm.patient.client.id
        client_name = ssm.patient.client.name
        enroll_date = patients[client_id]&.careplans&.sorted&.first&.sdh_enroll_date
        medicaid_id = patients[client_id]&.medicaid_id

        row << client_id
        row << medicaid_id
        row << client_name
        row << ssm.ssm_updated_at.to_date
        row << 'EPIC'
        row << enroll_date
        row << ssm.staff
        row << ssm.part_1
        row << ssm.part_2
        row << ssm.part_3
        row
      end
    end

    private def hmis_rows
      hmis_ssms.map do |ssm|
        row = []
        client_id = ssm.client.destination_client.id
        client_name = ssm.client.destination_client.name
        enroll_date = patients[client_id]&.careplans&.sorted&.first&.sdh_enroll_date
        medicaid_id = patients[client_id]&.medicaid_id

        row << client_id
        row << medicaid_id
        row << client_name
        row << ssm.collected_at
        row << ssm.hmis_assessment.site_name
        row << enroll_date
        row << ssm.staff
        hmis_data[:sections].each do |title, questions|
          questions.each do |question, _|
            row << hmis_data.dig(:sections, title, question, client_id, ssm.id)
          end
        end
        row
      end
    end

    private def ssms
      @ssms ||= Health::SelfSufficiencyMatrixForm.joins(:patient).
        completed_within_range(filter.range).
        preload(patient: :client)
    end

    private def epic_ssms
      @epic_ssms ||= Health::EpicSsm.joins(:patient).
        updated_within_range(filter.range).
        preload(patient: :client)
    end

    def hmis_ssms
      @hmis_ssms ||= hmis_touch_point_scope.select(
        hmis_form_t[:id].to_sql,
        hmis_form_t[:client_id].to_sql,
        hmis_form_t[:answers].to_sql,
        hmis_form_t[:collected_at].to_sql,
        hmis_form_t[:data_source_id].to_sql,
        hmis_form_t[:assessment_id].to_sql,
        hmis_form_t[:site_id].to_sql,
        hmis_form_t[:staff].to_sql,
      ).
        joins(:hmis_assessment, client: :destination_client).
        order(:client_id, :collected_at)
    end

    private def patients
      @patients ||= begin
        # from HMIS
        client_ids = hmis_data[:client_ids].to_a
        # from care-hub
        client_ids += ::Health::Patient.where(
          id: ssms.select(:patient_id)
        ).pluck(:client_id)
        # from epic
        client_ids += ::Health::Patient.joins(:epic_ssms).
          merge(Health::EpicSsm.where(id: epic_ssms.select(:id))).
          pluck(:client_id)
        ::Health::Patient.where(client_id: client_ids.to_a).
          joins(:careplans).
          index_by(&:client_id)
      end
    end

    def hmis_data
      @hmis_data ||= begin
        hmis_data = { sections: {}, questions: Set.new, client_ids: Set.new }
        hmis_ssms.preload(client: :destination_client).each do |response|
          answers = response.answers
          client_id = response.client.destination_client.id
          hmis_data[:client_ids] << client_id
          response_id = response.id
          answers[:sections].each do |section|
            title = section[:section_title]
            hmis_data[:sections][title] ||= {}
            section[:questions].each do |question|
              question_text = question[:question]
              hmis_data[:questions] << question_text
              hmis_data[:sections][title][question_text] ||= {}
              hmis_data[:sections][title][question_text][client_id] ||= {}
              hmis_data[:sections][title][question_text][client_id][response_id] = question[:answer]
            end
          end
        end
        hmis_data
      end
    end
  end
end

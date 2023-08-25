###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis
  class ProgramInvolvement
    include ::Hmis::Concerns::HmisArelHelper

    attr_accessor :end_date
    attr_accessor :program_ids
    attr_accessor :projects
    attr_accessor :start_date
    attr_accessor :status_message

    def initialize(params)
      self.end_date = params[:end_date]
      self.program_ids = params[:program_ids]
      self.start_date = params[:start_date]
    end

    def validate_request!
      message = []

      message << 'program_ids not provided.' if program_ids.blank?
      message << 'start_date not provided.' if start_date.blank?
      message << 'end_date not provided.' if end_date.blank?

      begin
        self.start_date = Date.strptime(start_date, '%Y-%m-%d') if start_date.present?
      rescue Date::Error
        message << 'start_date was not formatted correctly.'
      end

      begin
        self.end_date = Date.strptime(end_date, '%Y-%m-%d') if end_date.present?
      rescue Date::Error
        message << 'end_date was not formatted correctly.'
      end

      unless program_ids.blank?
        self.projects = Hmis::Hud::Project.where(project_id: program_ids, data_source_id: data_source.id)
        if projects.size != program_ids.size
          not_found_ids = program_ids - projects.pluck(:project_id)
          message << "programs not found: #{not_found_ids}"
        end
      end

      if message.present?
        self.status_message = message.join(' ')
      else
        self.status_message = 'success'
      end
    end

    def ok?
      status_message == 'success'
    end

    def to_json(_ = nil)
      {
        involvements: involvements,
        status_message: status_message,
      }.to_json
    end

    private

    def data_source
      @data_source ||= HmisExternalApis::AcHmis.data_source
    end

    def involvements
      raise 'check validity first' if status_message.nil?

      return [] unless ok?

      enrollments = Hmis::Hud::Enrollment.in_project(projects.pluck(:id))
        .open_during_range(start_date..end_date)

      personal_ids = enrollments.map(&:personal_id)

      mci_lookup = HmisExternalApis::ExternalId
        .joins(:client)
        .where(c_t[:data_source_id].eq(data_source.id))
        .where(namespace: 'ac_hmis_mci')
        .where(c_t[:PersonalID].in(personal_ids))
        .pluck(:source_id, :value) # i.e. client ID and mci ID
        .to_h

      # Enrollment ID => Unit type ID
      unit_type_lookup = Hmis::UnitOccupancy.where(enrollment: enrollments).joins(:unit).pluck(:enrollment_id, u_t[:unit_type_id]).to_h

      # Unit type ID => MPER Unit Type ID
      eid_t = HmisExternalApis::ExternalId.arel_table
      unit_type_id_lookup = Hmis::UnitType.joins(:mper_id).pluck(ut_t[:id], eid_t[:value]).to_h

      enrollments.map do |en|
        {
          entry_date: en.entry_date,
          exit_date: en.exit_date,
          first_name: en.client.first_name,
          last_name: en.client.last_name,
          mci_id: mci_lookup[en.client.id],
          personal_id: en.client.personal_id,
          household_id: en.household_id,
          enrollment_id: en.enrollment_id,
          relationship_to_hoh: en.relationship_to_hoh,
          program_id: en.project_id,
          unit_type_id: unit_type_id_lookup[unit_type_lookup[en.id]],
        }
      end
    end
  end
end

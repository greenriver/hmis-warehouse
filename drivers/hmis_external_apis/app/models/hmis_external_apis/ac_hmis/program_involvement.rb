###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis
  class ProgramInvolvement
    attr_accessor :end_date
    attr_accessor :program_id
    attr_accessor :project
    attr_accessor :start_date
    attr_accessor :status_message

    def initialize(params)
      self.end_date = params[:end_date]
      self.program_id = params[:program_id]
      self.start_date = params[:start_date]
    end

    def validate_request!
      message = []

      message << 'program_id not provided.' if program_id.blank?
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

      self.project = Hmis::Hud::Project.find_by(project_id: program_id)
      message << 'program not found.' if project.blank?

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

    def involvements
      raise 'check validity first' if status_message.nil?

      return [] unless ok?

      enrollments = Hmis::Hud::Enrollment.in_project([project.id]).open_during_range(start_date..end_date)
      # FIXME: Need to preload/join/include external id for MCI ID and add below

      enrollments.map do |en|
        {
          entry_date: en.entry_date,
          exit_date: en.exit_date,
          first_name: en.client.first_name,
          household_id: en.household_id,
          last_name: en.client.last_name,
          mci_id: -999,
          # mci_id: en.client.external_id_for_mci_wip,
          personal_id: en.client.personal_id,
          relationship_to_hoh: en.relationship_to_hoh,
        }
      end
    end
  end
end

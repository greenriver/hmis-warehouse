###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaYyaReport::Synthetic
  class YouthEducationStatus < ::GrdaWarehouse::Synthetic::YouthEducationStatus
    include ArelHelper

    validates_presence_of :source

    def information_date
      Date.strptime(source.api_response['ResponseCreatedDateAsString'], '%m/%d/%Y')
    end

    def data_collection_stage
      # TODO: How loose do these need to be?
      return 1 if information_date == enrollment.EntryDate
      return 3 if information_date == enrollment.exit.ExitDate

      # TODO: do we need annual assessments?
      2
    end

    delegate :current_school_attendance, to: :source
    delegate :most_recent_educational_status, to: :source
    delegate :current_educational_status, to: :source

    def data_source
      'Youth Education Status'
    end

    def self.sync
      remove_orphans
      add_new
    end

    def self.remove_orphans
      orphan_ids = pluck(:source_id) - GrdaWarehouse::HmisForm.where(name: 'Education Status').pluck(:id)
      return unless orphan_ids.present?

      where(source_id: orphan_ids).delete_all
    end

    def self.add_new
      new_statuses = GrdaWarehouse::HmisForm.
        where(name: 'Education Status').
        where.not(id: pluck(:source_id))

      new_statuses.find_each do |status|
        next unless status.client.present?

        enrollment = find_enrollment(status)
        create(enrollment: enrollment, client: status.client, source: status) if enrollment.present?
      end
    end

    def self.find_enrollment(status)
      date = Date.strptime(status.api_response['ResponseCreatedDateAsString'], '%m/%d/%Y')
      scope = status.client.source_enrollments.
        where(ProjectID: status.api_response['ProgramID']).
        open_on_date(date).
        order(EntryDate: :desc)

      scope.first
    end
  end
end

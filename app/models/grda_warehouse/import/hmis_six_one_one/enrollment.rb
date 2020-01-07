###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Import::HMISSixOneOne
  class Enrollment < GrdaWarehouse::Hud::Enrollment
    include ::Import::HMISSixOneOne::Shared
    include TsqlImport
    self.hud_key = :EnrollmentID
    setup_hud_column_access( GrdaWarehouse::Hud::Enrollment.hud_csv_headers(version: '6.11') )
    self.hud_key = :EnrollmentID

    def self.file_name
      'Enrollment.csv'
    end

    def self.unique_constraint
      [self.hud_key, :data_source_id, :PersonalID]
    end

    def self.involved_enrollments(projects:, range:, data_source_id:)
      ids = []
      projects.each do |project|
        ids += self.joins(:project).
          open_during_range(range).
          where(Project: {ProjectID: project.ProjectID}, data_source_id: data_source_id).
          pluck(:id)
      end
      ids
    end

    def self.should_log?
      true
    end

    def self.to_log
      @to_log ||= {
        hud_key: self.hud_key,
        personal_id: :PersonalID,
        effective_date: :EntryDate,
        data_source_id: :data_source_id,
      }
    end
  end
end
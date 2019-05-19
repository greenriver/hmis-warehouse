# A reporting table to power the enrollment related answers for project data quality reports.

module Reporting::DataQualityReports
  class Enrollment < ReportingBase
    include ArelHelper

    self.table_name = :warehouse_data_quality_report_enrollments

    scope :enrolled, -> do
      where enrolled: true
    end

    scope :stayer, -> do
      where exited: false
    end

    scope :leaver, -> do
      where exited: true
    end

    scope :entered, -> do
      where entered: true
    end

    scope :adult, -> do
      where adult: true
    end

    scope :head_of_household, -> do
      where head_of_household: true
    end


    def is_adult? date
      set_age date
      age.present? && age > 18
    end

    def set_age date
      age = GrdaWarehouse::Hud::Client.age date: date, dob: dob
    end

    def is_stayer? report_end:, exit_date:
      return true if exit_date.blank?
      exit_date > report_end
    end

    def is_leaver? report_end:, exit_date:
      exit_date.present? && exit_date <= report_end
    end

    # Blanks should not be allowed according to the spec
    def is_head_of_household? enrollment
      enrollment.RelationshipToHoH.blank? || enrollment.RelationshipToHoH.to_s == '1'
    end

    def set_days_to_add_entry_date enrollment
      enrollment.DateCreated - enrollment.EntryDate
    end

    def days_to_add_exit_date exit_record
      return nil unless exit_record.present? && exit_record.ExitDate.present?
      exit_record.DateCreated - enrollment.ExitDate
    end

    def set_dob_after_entry_date
      dob.present? && dob > entry_date
    end

    def is_active? project:, service_dates:, report_start:, report_end:
      return true if project.TrackingMethod.to_s != '3'
      ((report_start..report_end).to_a & service_dates).any?
    end


  end
end
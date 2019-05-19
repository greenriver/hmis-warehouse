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
      days_to_add_entry_date = enrollment.DateCreated - enrollment.EntryDate
    end

    def set_days_to_add_exit_date exit_record
      if exit_record.blank? || exit_record.ExitDate.blank?
        days_to_add_exit_date = nil
      else
        days_to_add_exit_date = exit_record.DateCreated - enrollment.ExitDate
      end
    end

    def set_dob_after_entry_date
      dob_after_entry_date = dob.present? && dob > entry_date
    end

    def is_active? project:, service_dates:, report_start:, report_end:
      return true if project.TrackingMethod.to_s != '3'
      ((report_start..report_end).to_a & service_dates).any?
    end

    def set_household_type household_ids:
      if household_ids.count(household_id) > 1
         household_type = :family
       else
        household_type = :individual
      end
    end

    def set_most_recent_service_within_range project:, service_dates:, report_start:, report_end:, exit_date:
      if project.TrackingMethod.to_s != '3'
        most_recent_service_within_range = [report_end, exit_date].min
      else
        most_recent_service_within_range = ((report_start..report_end).to_a & service_dates).max
      end
    end

    def set_service_witin_last_30_days project:, service_dates:, exit_date:, report_end:
      if project.TrackingMethod.to_s != '3'
        service_witin_last_30_days = true
      else
        if exit_date.present?
          range = ((exit_date - 30.days)..exit_date)
        else
          range = ((report_end - 30.days)..report_end)
        end
        service_witin_last_30_days = (range.to_a & service_dates).any?
      end
    end

    def set_service_after_exit project:, service_dates:, exit_date:
      if project.TrackingMethod.to_s != '3' || exit_date.blank?
        service_after_exit = false
      else
        service_after_exit = service_dates.max > exit_date
      end
    end

    def set_days_of_service project:, service_dates:, entry_date:, exit_date:, report_start:, report_end:

    end
  end
end
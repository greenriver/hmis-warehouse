###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSpmReport::Fy2023
  class Return < GrdaWarehouseBase
    self.table_name = 'hud_report_spm_returns'

    belongs_to :report_instance, class_name: 'HudReports::ReportInstance'
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    belongs_to :exit_enrollment, class_name: 'HudSpmReport::Fy2023::SpmEnrollment'
    belongs_to :return_enrollment, class_name: 'HudSpmReport::Fy2023::SpmEnrollment'

    def self.client_ids_with_permanent_exits(report)
      filter = ::Filters::HudFilterBase.new(user_id: User.system_user.id).update(report.options)
      report.spm_enrollments.where(exit_date: filter.start - 730.days .. filter.end - 730.days).
        where(destination: HudUtility2024.permanent_destinations).
        pluck(:client_id)
    end

    def self.compute_returns(report)
      client_ids_with_permanent_exits(report).each_slice(500) do |slice|
        returns = [].tap do |a|
          slice.each do |client_id|
            computed_return = new(report_instance_id: report.id, client_id: client_id).compute_return
            a << computed_return if computed_return.present?
          end
        end
        import!(returns)
      end

      where(report_instance_id: report.id)
    end

    def compute_return
      self.exit_enrollment = report_instance.spm_enrollments.where(exit_date: report_start_date - 730.days .. report_end_date - 730.days).
        where(client_id: client_id).
        where(destination: HudUtility2024.permanent_destinations).
        order(exit_date: :asc).
        first
      return unless exit_enrollment.present? # If no exit, no return

      self.exit_date = exit_enrollment.exit_date
      self.exit_destination = exit_enrollment.destination
      self.project_type = exit_enrollment.project_type

      candidate_returns = report_instance.spm_enrollments.where(entry_date: exit_date..).order(entry_date: :asc)
      self.return_enrollment = candidate_returns.detect do |enrollment|
        enrollment.project_type.in?(HudUtility2024.homeless_project_type_numbers) ||
          (enrollment.project_type.in?(HudUtility2024.project_type_number_from_code(:ph)) &&
            enrollment.entry_date > exit_date + 14.days &&
            ! other_ph?(enrollment))
      end

      if return_enrollment.present?
        self.return_date = return_enrollment.entry_date
        self.days_to_return = (return_date - exit_date).to_i
      end

      self
    end

    private def other_ph?(ph_enrollment)
      report_instance.spm_enrollments.map do |enrollment|
        next if enrollment == ph_enrollment # Don't compare to ourselves

        end_date = if enrollment.exit_date.present?
          [enrollment.exit_date + 14.days, report_end_date].min
        else
          report_end_date
        end
        enrollment.project_type.in?(HudUtility2024.project_type_number_from_code(:ph)) &&
          ph_enrollment.entry_date.between?(enrollment.entry_date + 1.day, end_date)
      end.any?
    end

    private def report_start_date
      filter.start
    end

    private def lookback_date
      report_start_date - 7.years
    end

    private def report_end_date
      filter.end
    end

    private def filter
      @filter ||= ::Filters::HudFilterBase.new(user_id: User.system_user.id).update(report_instance.options)
    end
  end
end

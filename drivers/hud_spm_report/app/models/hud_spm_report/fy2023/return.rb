###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSpmReport::Fy2023
  class Return < GrdaWarehouseBase
    self.table_name = 'hud_report_spm_returns'
    include Detail

    belongs_to :report_instance, class_name: 'HudReports::ReportInstance'
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    belongs_to :exit_enrollment, class_name: 'HudSpmReport::Fy2023::SpmEnrollment'
    belongs_to :return_enrollment, class_name: 'HudSpmReport::Fy2023::SpmEnrollment', optional: true

    has_many :hud_reports_universe_members, inverse_of: :universe_membership, class_name: 'HudReports::UniverseMember', foreign_key: :universe_membership_id

    def self.client_ids_with_permanent_exits(report, enrollments)
      filter = ::Filters::HudFilterBase.new(user_id: report.user.id).update(report.options)
      enrollments.where(exit_date: filter.start - 730.days .. filter.end - 730.days).
        where(destination: HudUtility2024.permanent_destinations).
        pluck(:client_id).
        uniq
    end

    def self.compute_returns(report, enrollments)
      client_ids_with_permanent_exits(report, enrollments).each_slice(500) do |slice|
        returns = [].tap do |a|
          slice.each do |client_id|
            computed_return = new(report_instance_id: report.id, client_id: client_id).compute_return(enrollments)
            a << computed_return if computed_return.present?
          end
        end
        import!(returns)
      end

      where(report_instance_id: report.id)
    end

    def self.detail_headers
      client_columns = ['client_id', 'exit_enrollment.first_name', 'exit_enrollment.last_name', 'exit_enrollment.personal_id']
      hidden_columns = ['id', 'report_instance_id'] + client_columns
      join_columns = ['exit_enrollment.enrollment.project.project_name', 'return_enrollment.enrollment.project.project_name']
      columns = client_columns + (column_names + join_columns - hidden_columns)
      columns.map do |col|
        [col, header_label(col)]
      end.to_h
    end

    def compute_return(enrollments)
      client_enrollments = enrollments.where(client_id: client_id)
      self.exit_enrollment = client_enrollments.where(exit_date: report_start_date - 730.days .. report_end_date - 730.days).
        where(destination: HudUtility2024.permanent_destinations).
        order(exit_date: :asc, entry_date: :asc).
        first
      return unless exit_enrollment.present? # If no exit, no return

      self.exit_date = exit_enrollment.exit_date
      self.exit_destination = exit_enrollment.destination
      self.project_type = exit_enrollment.project_type

      candidate_returns = client_enrollments.where(entry_date: exit_date..).order(entry_date: :asc)
      self.return_enrollment = candidate_returns.detect do |enrollment|
        # Can't match yourself
        next false if enrollment.id == exit_enrollment.id

        enrollment.project_type.in?(HudUtility2024.homeless_project_type_numbers) ||
          (enrollment.project_type.in?(HudUtility2024.project_type_number_from_code(:ph)) &&
            enrollment.entry_date > exit_date + 14.days &&
            ! other_ph?(enrollment, candidate_returns))
      end

      if return_enrollment.present?
        self.return_date = return_enrollment.entry_date
        self.days_to_return = (return_date - exit_date).to_i
      end

      self
    end

    private def other_ph?(ph_enrollment, other_enrollments)
      other_enrollments.map do |enrollment|
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
      @filter ||= ::Filters::HudFilterBase.new(user_id: report_instance.user.id).update(report_instance.options)
    end
  end
end

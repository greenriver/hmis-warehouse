###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class EnrollmentDisenrollment
    def initialize(start_date:, end_date:, effective_date:, aco_ids:, enrollment_reasons:)
      @start_date = start_date
      @end_date = end_date
      @effective_date = effective_date
      @acos = Health::AccountableCareOrganization.find(aco_ids)
      @enrollment_reasons = enrollment_reasons
      @cp = Health::Cp.first
    end

    def zip_file_name
      "#{@acos.first.e_d_file_prefix}_#{timestamp}.zip"
    end

    def report_file_name
      "#{@acos.first.e_d_file_prefix}_ENROLLDISENROLL_CHG_#{timestamp}.xlsx"
    end

    def summary_file_name
      "#{@acos.first.e_d_file_prefix}_SUMMARY_ENROLLDISENROLL_CHG_#{timestamp}.xlsx"
    end

    def enrollment_summary
      [
        @cp.short_name,
        0,
        19,
        timestamp,
        receiver_text,
        '',
        '',
        '',
      ].freeze
    end

    def disenrollments
      @disenrollments ||= begin
        referrals = Health::PatientReferral.where(
          disenrollment_date: (@start_date..@end_date),
          accountable_care_organization_id: @acos.map(&:id),
          current: true,
          removal_acknowledged: false,
        )
        referrals.map do |referral|
          disenrollment_date = referral.pending_disenrollment_date || referral.disenrollment_date || @end_date
          [
            referral.medicaid_id,
            referral.last_name,
            referral.first_name,
            referral.middle_initial,
            referral.suffix,
            format_date(referral.birthdate),
            referral.gender,
            referral.aco.name,
            referral.aco.mco_pid,
            referral.aco.mco_sl,
            @cp.cp_assignment_plan,
            @cp.cp_name_official,
            @cp.pid,
            @cp.sl,
            format_date(referral.enrollment_start_date),
            @enrollment_reasons[referral.medicaid_id] || '',
            format_date(disenrollment_date.end_of_month),
            referral.rejected_reason&.tr('_', ' '),
            'D',
            format_date(referral.updated_at),
            timestamp,
          ].freeze
        end
      end
    end

    def disenrollment_summary
      [
        @cp.short_name,
        disenrollments.count,
        21,
        timestamp,
        receiver_text,
        '',
        '',
        '',
      ].freeze
    end

    private def timestamp
      @timestamp ||= format_date(@effective_date)
    end

    private def receiver_text
      @acos.first.e_d_receiver_text
    end

    private def format_date(date)
      date.strftime('%Y%m%d')
    end
  end
end

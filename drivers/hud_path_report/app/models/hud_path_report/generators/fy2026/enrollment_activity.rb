###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudPathReport::Generators::Fy2026
  # One enrollment's Current Living Situations, PATH services and PATH referrals in the report
  # range, read once. Every value the report derives from those records comes from this one read,
  # so the values on a client's row can't disagree with each other if an import runs mid-report.
  class EnrollmentActivity
    ServiceRow = Struct.new(:record_type, :date_provided, :type_provided, :referral_outcome, keyword_init: true)

    attr_reader :cls_dates

    def self.load(enrollment, report_range:)
      cls_dates = enrollment.current_living_situations.
        between(start_date: report_range.begin, end_date: report_range.end).
        pluck(:InformationDate)

      path_records = enrollment.services.path_service.
        or(enrollment.services.path_referral).
        between(start_date: report_range.begin, end_date: report_range.end)
      service_rows = path_records.
        pluck(:RecordType, :DateProvided, :TypeProvided, :ReferralOutcome).
        map do |record_type, date_provided, type_provided, referral_outcome|
          ServiceRow.new(
            record_type: record_type,
            date_provided: date_provided,
            type_provided: type_provided,
            referral_outcome: referral_outcome,
          )
        end

      new(cls_dates: cls_dates, service_rows: service_rows)
    end

    def initialize(cls_dates:, service_rows:)
      @cls_dates = cls_dates
      @service_rows = service_rows
    end

    # Same record type the Service.path_service scope selects
    def path_services
      path_service_type = HudHelper.util.record_type('PATH Service', true)
      @path_services ||= @service_rows.select { |row| row.record_type == path_service_type }
    end

    # Same record type the Service.path_referral scope selects
    def path_referrals
      path_referral_type = HudHelper.util.record_type('PATH Referral', true)
      @path_referrals ||= @service_rows.select { |row| row.record_type == path_referral_type }
    end

    def cls_dates_between(date_range)
      cls_dates.select { |date| date_range.cover?(date) }
    end

    def path_service_dates_between(date_range)
      path_services.map(&:date_provided).select { |date| date_range.cover?(date) }
    end
  end
end

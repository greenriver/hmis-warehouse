###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Health
  class ScheduledDocuments::EnrollmentDisenrollment < Health::ScheduledDocuments::Base
    validates :acos, presence: true

    def deliver(_user)
      start_date = Date.current.beginning_of_month
      end_date = Date.current.end_of_month
      effective_date = Date.current

      ed = Health::EnrollmentDisenrollment.new(
        start_date: start_date,
        end_date: end_date,
        effective_date: effective_date,
        aco_ids: acos.reject(&:blank?),
        enrollment_reasons: Health::EnrollmentReasons.last || Health::EnrollmentReasons.new,
      )
      summary = ApplicationController.render(
        template: 'warehouse_reports/health/enrollments_disenrollments/summary.xlsx',
        assigns: {
          report: ed,
        },
      )
      report =
        ApplicationController.render(
          template: 'warehouse_reports/health/enrollments_disenrollments/report.xlsx',
          assigns: {
            report: ed,
          },
        )
      stringio = Zip::OutputStream.write_buffer do |zio|
        zio.put_next_entry(ed.summary_file_name)
        zio.write(summary)

        zio.put_next_entry(ed.report_file_name)
        zio.write(report)
      end

      send_file(file_name: ed.zip_file_name, data: stringio.string)
    end

    SUNDAY = 0
    SATURDAY = 6

    def should_be_delivered?
      # Determine when this document should be scheduled for this month
      delivery_date = Date.new(Date.current.year, Date.current.month, scheduled_day)
      delivery_date = delivery_date.yesterday if delivery_date.wday == SATURDAY
      delivery_date = delivery_date.tomorrow if delivery_date.wday == SUNDAY

      # See if today is the delivery date, and it hasn't already been run
      Date.current == delivery_date && (last_run_at.blank? || last_run_at.to_date < Date.current)
    end

    def params
      [
        :scheduled_day,
        acos: [],
      ]
    end
  end
end

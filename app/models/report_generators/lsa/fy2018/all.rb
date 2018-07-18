module ReportGenerators::Lsa::Fy2018
  class All < Base
    LOOKBACK_STOP_DATE = '2012-10-01'


    def run!
      # Disable logging so we don't fill the disk
      ActiveRecord::Base.logger.silence do
        calculate()
        Rails.logger.info "Done"
      end # End silence ActiveRecord Log
    end

    private

    def calculate
      if start_report(Reports::Lsa::Fy2018::All.first)
        @report_start ||= @report.options['report_start'].to_date
        @report_end ||= @report.options['report_end'].to_date
        Rails.logger.info "Starting report #{@report.report.name}"
        create_hmis_csv_export()


        finish_report()
      else
        Rails.logger.info 'No Report Queued'
      end
    end


    def create_hmis_csv_export

    end

  end
end

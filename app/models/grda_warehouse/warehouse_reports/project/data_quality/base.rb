module GrdaWarehouse::WarehouseReports::Project::DataQuality
  class Base < GrdaWarehouseBase
    self.table_name = :project_data_quality
    belongs_to :project, class_name: GrdaWarehouse::Hud::Project.name
    has_many :project_contacts, through: :project
    has_many :report_tokens, -> { where(report_id: id)}, class_name: GrdaWarehouse::ReportToken.name

    def display

    end

    def print

    end

    def run!
      raise 'Define in Sub-class'
    end

    def clients
      @clients ||= begin
        client_scope.select(*columns.values).
          distinct.
          pluck(*columns.values).
          map do |row|
            Hash[columns.keys.zip(row)]
          end        
      end
    end

    def columns
      c_t = client_source.arel_table
      {
        id: c_t[:id].as('id').to_sql,
        first_name: c_t[:FirstName].as('first_name').to_sql,
        last_name: c_t[:LastName].as('last_name').to_sql,
        name_data_quality: c_t[:NameDataQuality].as('name_data_quality').to_sql,
        ssn: c_t[:SSN].as('ssn').to_sql,
        ssn_data_quality: c_t[:SSNDataQuality].as('ssn_data_quality').to_sql,
        dob: c_t[:DOB].as('dob').to_sql,
        dob_data_quality: c_t[:DOBDataQuality].as('dob_data_quality').to_sql,
        veteran_status: c_t[:VeteranStatus].as('veteran_status').to_sql, 
        ethnicity: c_t[:Ethnicity].as('ethnicity').to_sql,
        gender: c_t[:Gender].as('gender').to_sql,
        race_none: c_t[:RaceNone].as('race_none').to_sql,
      }
    end

    def start_report
      started_at = Time.now
      self.report = {}
    end

    def finish_report
      completed_at = Time.now
      save()
    end

    def add_answers(answers)
      self.update(report: self.report.merge(answers))
    end

    def send_notifications
      ProjectDataQualityReportMailer.report_complete(project, self).deliver_later
    end

    def notifications_sent
      self.update(sent_at: Time.now)
    end

    def refused?(value)
      [8,9].include?(value.to_i)
    end

    def missing?(value)
      return true if value.blank?
      [99].include?(value.to_i)
    end

    def client_source
      GrdaWarehouse::Hud::Client.source
    end

    def client_scope
      GrdaWarehouse::ServiceHistory.entry.
        open_between(start_date: self.start,
          end_date: self.end).
        joins(:project, enrollment: :client).
        where(Project: {id: self.project_id})
    end
  end
end
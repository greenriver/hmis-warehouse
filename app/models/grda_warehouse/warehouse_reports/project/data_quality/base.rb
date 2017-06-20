module GrdaWarehouse::WarehouseReports::Project::DataQuality
  class Base < GrdaWarehouseBase
    include ApplicationHelper
    self.table_name = :project_data_quality
    belongs_to :project, class_name: GrdaWarehouse::Hud::Project.name
    belongs_to :project_group, class_name: GrdaWarehouse::ProjectGroup.name
    has_many :project_contacts, through: :project, source: :contacts
    has_many :organization_contacts, through: :project
    has_many :project_group_contacts, through: :project_group, source: :contacts
    has_many :report_tokens, -> { where(report_id: id)}, class_name: GrdaWarehouse::ReportToken.name

    scope :complete, -> do
      where.not(completed_at: nil).
      where(processing_errors: nil).
      order(created_at: :asc)
    end

    scope :incomplete, -> do
      where(completed_at: nil, processing_errors: nil)
    end

    def display

    end

    def print

    end

    def run!
      raise 'Define in Sub-class'
    end

    def clients
      @clients ||= begin
        client_scope.select(*client_columns.values).
          distinct.
          pluck(*client_columns.values).
          map do |row|
            Hash[client_columns.keys.zip(row)]
          end        
      end
    end

    def enrollments
      @enrollments ||= begin
        client_scope.pluck(*enrollment_columns.values).
        map do |row|
          Hash[enrollment_columns.keys.zip(row)]
        end.
        group_by{|m| m[:id]}
      end
    end

    def incomes
      @incomes ||= begin
        incomes = {}
        enrollments.each do |client_id, enrollments|
          ds_id = enrollments.last[:data_source_id]
          personal_id = enrollments.last[:personal_id]
          enrollment_group_id =enrollments.last[:enrollment_group_id]
          assessments = income_source.where(data_source_id: ds_id).
            where(PersonalID: personal_id).
            where(ProjectEntryID: enrollment_group_id).
            where(i_t[:InformationDate].lteq(self.end)).
            where(DataCollectionStage: [3, 1]).
            order(InformationDate: :asc).
          pluck(*income_columns).map do |row|
            Hash[income_columns.zip(row)]
          end
          incomes[client_id] = assessments
        end
        incomes
      end
    end

    def leavers
      @leavers ||= begin 
        leavers = Set.new
        enrollments.each do |client_id, enrollments|
          leaver = true
          enrollments.each do |enrollment|
            leaver = false if enrollment[:last_date_in_program].blank? || enrollment[:last_date_in_program] < self.end
          end
          leavers << client_id if leaver
        end
        leavers
      end
      @leavers
    end

    def beds 
      @beds ||= projects.flat_map(&:inventories).map(&:BedInventory).reduce(:+) || 0
    end

    def hmis_beds
      @hmis_beds ||= projects.flat_map(&:inventories).map(&:HMISParticipatingBeds).reduce(:+) || 0
    end

    def income_columns
      [
        :TotalMonthlyIncome, 
        :IncomeFromAnySource, 
        :InformationDate, 
        :DataCollectionStage
      ] + amount_columns
    end

    def amount_columns
      [
        :EarnedAmount, 
        :UnemploymentAmount, 
        :SSIAmount, 
        :SSDIAmount, 
        :VADisabilityServiceAmount, 
        :VADisabilityNonServiceAmount, 
        :PrivateDisabilityAmount, 
        :WorkersCompAmount, 
        :TANFAmount, 
        :GAAmount, 
        :SocSecRetirementAmount, 
        :PensionAmount, 
        :ChildSupportAmount, 
        :AlimonyAmount, 
        :OtherIncomeAmount
      ]
    end

    def enrollment_columns
      {
        id: c_t[:id].as('id').to_sql,
        project_id: sh_t[:project_id].as('project_id').to_sql,
        enrollment_group_id: sh_t[:enrollment_group_id].as('enrollment_group_id').to_sql,
        first_date_in_program: sh_t[:first_date_in_program].as('first_date_in_program').to_sql,
        last_date_in_program: sh_t[:last_date_in_program].as('last_date_in_program').to_sql,
        destination: sh_t[:destination].as('destination').to_sql,
        personal_id: c_t[:PersonalID].as('personal_id').to_sql,
        data_source_id: c_t[:data_source_id].as('data_source_id').to_sql,
        residence_prior: e_t[:ResidencePrior].as('residence_prior').to_sql,
        disabling_condition: e_t[:DisablingCondition].as('disabling_condition').to_sql,
      }
    end

    def client_columns
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
        am_ind_ak_native: c_t[:AmIndAKNative].as('am_ind_ak_native').to_sql,
        asian: c_t[:Asian].as('asian').to_sql,
        black_af_american: c_t[:BlackAfAmerican].as('black_af_american').to_sql,
        native_hi_other_pacific: c_t[:NativeHIOtherPacific].as('native_hi_other_pacific').to_sql,
        white: c_t[:White].as('white').to_sql,
      }
    end

    def start_report
      self.started_at = Time.now
      self.report = {}
    end

    def finish_report
      self.completed_at = Time.now
      save()
    end

    def status
      return 'Error' if self.processing_errors.present?
      return 'Incomplete' if self.completed_at.blank?
      return "#{self.start} - #{self.end}" if self.completed_at.present?
    end

    def add_answers(answers)
      self.update(report: self.report.merge(answers))
    end

    def send_notifications
      (project_contacts + organization_contacts + project_group_contacts).each do |contact|
        ProjectDataQualityReportMailer.report_complete(projects, self, contact).deliver
      end
      notifications_sent()
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

    # Display methods
    def percent(value)
      "#{value}%"
    end

    def boolean(value)
      value ? 'Yes': 'No'
    end

    def client_source
      GrdaWarehouse::Hud::Client.source
    end

    def client_scope
      GrdaWarehouse::ServiceHistory.entry.
        open_between(start_date: self.start,
          end_date: self.end).
        joins(:project, :enrollment, enrollment: :client).
        where(Project: {id: projects.map(&:id)})
    end

    def service_scope
      GrdaWarehouse::ServiceHistory.service.
        open_between(start_date: self.start,
          end_date: self.end).
        joins(:project, enrollment: :client).
        where(Project: {id: projects.map(&:id)})
    end

    def projects
      return project_group.projects if self.project_group_id.present?
      return [project]
    end

    def c_t
      client_source.arel_table
    end

    def sh_t
      GrdaWarehouse::ServiceHistory.arel_table
    end

    def e_t
      GrdaWarehouse::Hud::Enrollment.arel_table
    end

    def i_t
      income_source.arel_table
    end

    def income_source
      GrdaWarehouse::Hud::IncomeBenefit
    end
  end
end
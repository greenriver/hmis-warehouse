module GrdaWarehouse::WarehouseReports::Project::DataQuality
  class Base < GrdaWarehouseBase
    include ApplicationHelper
    self.table_name = :project_data_quality
    belongs_to :project, class_name: GrdaWarehouse::Hud::Project.name
    belongs_to :project_group, class_name: GrdaWarehouse::ProjectGroup.name
    has_many :project_contacts, through: :project, source: :contacts
    has_many :organization_contacts, through: :project
    has_many :project_group_contacts, through: :project_group, source: :contacts
    has_many :organization_project_group_contacts, through: :project_group, source: :organization_contacts
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

    def clients_for_project project_id
      client_scope.where(Project: {id: project_id}).
        select(*client_columns.values).
        distinct.
        pluck(*client_columns.values).
        map do |row|
          Hash[client_columns.keys.zip(row)]
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

    def enrollments_for_project project_id, data_source_id
      enrollments_in_project = {}
      enrollments.each do |client_id, involved_enrollment|
        enrollments_in_project[client_id] = involved_enrollment.select do |en| 
          en[:project_id] == project_id && en[:data_source_id] == data_source_id
        end
      end
      enrollments_in_project
    end

    def incomes
      @incomes ||= begin
        incomes = {}
        enrollments.each do |client_id, enrollments|
          # Use last enrollment within window for the client, per HUD Data Quality Spec
          ds_id = enrollments.last[:data_source_id]
          personal_id = enrollments.last[:personal_id]
          enrollment_group_id = enrollments.last[:enrollment_group_id]
          assessments = income_source.where(data_source_id: ds_id).
            where(PersonalID: personal_id).
            where(ProjectEntryID: enrollment_group_id).
            where(i_t[:InformationDate].lteq(self.end)).
            where(DataCollectionStage: [3, 1, 2]).
            order(InformationDate: :asc).
          pluck(*income_columns).map do |row|
            Hash[income_columns.zip(row)]
          end
          incomes[client_id] = assessments
        end
        incomes
      end
    end

    def leavers_for_project project_id, data_source_id
      leavers = Set.new
      enrollments_in_project = enrollments_for_project(project_id, data_source_id)
      if enrollments_in_project.any?
        enrollments_in_project.each do |client_id, enrollments|
          leaver = true
          if enrollments.present?
            enrollments.each do |enrollment|
              leaver = false if enrollment[:last_date_in_program].blank? || enrollment[:last_date_in_program] > self.end
            end
          end
          leavers << client_id if leaver
        end
      end
      leavers
    end

    def leavers
      @leavers ||= begin 
        leavers = Set.new
        enrollments.each do |client_id, enrollments|
          leaver = true
          enrollments.each do |enrollment|
            leaver = false if enrollment[:last_date_in_program].blank? || enrollment[:last_date_in_program] > self.end
          end
          leavers << client_id if leaver
        end
        leavers
      end
      @leavers
    end

    def beds 
      @beds ||= projects.flat_map(&:inventories).map{|i| i[:BedInventory] || 0}.reduce(:+) || 0
    end

    def hmis_beds
      @hmis_beds ||= projects.flat_map(&:inventories).map{|i| i[:HMISParticipatingBeds] || 0}.reduce(:+) || 0
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
        :Earned,
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
        project_name: sh_t[:project_name].as('project_name').to_sql,
        enrollment_group_id: sh_t[:enrollment_group_id].as('enrollment_group_id').to_sql,
        first_date_in_program: sh_t[:first_date_in_program].as('first_date_in_program').to_sql,
        last_date_in_program: sh_t[:last_date_in_program].as('last_date_in_program').to_sql,
        destination: sh_t[:destination].as('destination').to_sql,
        personal_id: c_t[:PersonalID].as('personal_id').to_sql,
        data_source_id: c_t[:data_source_id].as('data_source_id').to_sql,
        residence_prior: e_t[:ResidencePrior].as('residence_prior').to_sql,
        disabling_condition: e_t[:DisablingCondition].as('disabling_condition').to_sql,
        last_permanent_zip: e_t[:LastPermanentZIP].as('last_permanent_zip').to_sql,
        first_name: c_t[:FirstName].as('first_name').to_sql,
        last_name: c_t[:LastName].as('last_name').to_sql,
        name_data_quality: c_t[:NameDataQuality].as('name_data_quality').to_sql,
        ssn: c_t[:SSN].as('ssn').to_sql,
        ssn_data_quality: c_t[:SSNDataQuality].as('ssn_data_quality').to_sql,
        dob: c_t[:DOB].as('dob').to_sql,
        dob_data_quality: c_t[:DOBDataQuality].as('dob_data_quality').to_sql,
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

    def service_columns
      {
        id: c_t[:id].as('client_id').to_sql,
        first_name: c_t[:FirstName].as('first_name').to_sql,
        last_name: c_t[:LastName].as('last_name').to_sql,
        project_name: sh_t[:project_name].as('project_name').to_sql,
        # date: sh_t[:date].as('date').to_sql,
        first_date_in_program: sh_t[:first_date_in_program].as('first_date_in_program').to_sql,
        last_date_in_program: sh_t[:last_date_in_program].as('last_date_in_program').to_sql,
      }
    end

    def start_report
      self.started_at = Time.now
      self.report = {}
      self.support = {}
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

    def add_answers(answers, support={})
      self.assign_attributes(report: self.report.merge(answers))
      self.assign_attributes(support: self.support.merge(support)) if support.present?
      self.save
    end

    def send_notifications
      (project_contacts + organization_contacts + project_group_contacts + organization_project_group_contacts).uniq.each do |contact|
        ProjectDataQualityReportMailer.report_complete(projects, self, contact).deliver
      end
      notifications_sent()
    end

    def notifications_sent
      self.update(sent_at: Time.now)
    end

    def refused?(value)
      value.to_i == 9
    end

    def unknown?(value)
      value.to_i == 8
    end

    def missing?(value)
      return true if value.blank?
      [99].include?(value.to_i)
    end

    def in_percentage numerator, denominator
      ((numerator.to_f/denominator) * 100).round(2) rescue 0
    end

    # Display methods
    def percent(value)
      "#{value}%"
    end

    def boolean(value)
      value ? 'Yes': 'No'
    end

    def days(value)
      "#{value} days"
    end

    def destination_id_for_client source_id
      @destination_ids ||= begin
        GrdaWarehouse::WarehouseClient.where(source_id: client_scope.select(c_t[:id])).
          pluck(:source_id, :destination_id).
          to_h
      end
      @destination_ids[source_id]
    end

    def client_source
      GrdaWarehouse::Hud::Client.source
    end

    def client_scope
      GrdaWarehouse::ServiceHistory.entry.
        open_between(start_date: self.start.to_date - 1.day,
          end_date: self.end).
        joins(:project, :enrollment, enrollment: :client).
        where(Project: {id: projects.map(&:id)})
    end

    def service_scope
      GrdaWarehouse::ServiceHistory.service.
        open_between(start_date: self.start.to_date - 1.day,
          end_date: self.end).
        where(date: self.start..self.end).
        joins(:project, enrollment: :client).
        where(Project: {id: projects.map(&:id)})
    end

    def projects
      return project_group.projects if self.project_group_id.present?
      return [project]
    end

    def self.length_of_stay_buckets
      {
        '0 days' => (0..0),
        '1 - 90 days'  => (1..90),
        '91 - 364 days' => (91..364),
        '1 - 2 years' => (365..729),
        '2 - 3 years' => (730..1094),
        '3 years or more' => (1095..1.0/0),
      }
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
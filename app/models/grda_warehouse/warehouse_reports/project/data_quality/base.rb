###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'memoist'
module GrdaWarehouse::WarehouseReports::Project::DataQuality
  class Base < GrdaWarehouseBase
    include ApplicationHelper
    include ArelHelper
    include NotifierConfig
    extend Memoist
    self.table_name = :project_data_quality

    belongs_to :project, class_name: 'GrdaWarehouse::Hud::Project'
    belongs_to :project_group, class_name: 'GrdaWarehouse::ProjectGroup'
    has_many :project_contacts, through: :project, source: :contacts
    has_many :organization_contacts, through: :project
    has_many :project_group_contacts, through: :project_group, source: :contacts
    has_many :organization_project_group_contacts, through: :project_group, source: :organization_contacts
    has_many :report_tokens, foreign_key: :report_id, class_name: 'GrdaWarehouse::ReportToken'

    scope :complete, -> do
      where.not(completed_at: nil).
        where(processing_errors: nil).
        order(created_at: :asc)
    end

    scope :incomplete, -> do
      where(completed_at: nil, processing_errors: nil)
    end

    def self.process!
      advisory_lock_key = 'project_data_quality_reports'
      if advisory_lock_exists?(advisory_lock_key)
        Rails.logger.info 'Exiting, project data quality reports already running'
        exit
      end
      @notifier = new
      @notifier.setup_notifier('Project Data Quality Report Runner')
      with_advisory_lock(advisory_lock_key) do
        where(completed_at: nil).each do |r|
          r.run!
        rescue Exception => e
          Rails.logger.error e.message
          @notifier.ping(e) if @notifier.instance_variable_get(:@send_notifications)
        end
      end
    end

    def display
    end

    def print
    end

    def title
      if projects.count == 1
        "#{project.ProjectName} at #{project.organization.OrganizationName}"
      else
        project_group.name
      end
    end

    def run!
      raise 'Define in Sub-class'
    end

    def clients
      @clients ||= begin
        Rails.logger.debug 'Loading Clients'
        clients = client_scope.entry.select(*client_columns.values).
          distinct.
          pluck(*client_columns.values.map { |column| Arel.sql(column) }).
          map do |row|
            Hash[client_columns.keys.zip(row)]
          end

        enrollment_ids = clients.map do |client|
          client[:enrollment_id]
        end

        # min_enrollment_date = clients.map{|c| c[:first_date_in_program]}.min
        max_exit_date = (clients.map { |c| c[:last_date_in_program]}.compact + [Date.current]).max
        max_dates = max_dates_served(enrollment_ids, range: (start..max_exit_date))
        clients.each do |client|
          client[:most_recent_service] = max_dates[client[:enrollment_id]] || 'Before report start'
        end
      end
    end

    def max_dates_served(enrollment_ids, range:)
      GrdaWarehouse::ServiceHistoryService.where(
        date: range,
        service_history_enrollment_id: enrollment_ids,
      ).group(:service_history_enrollment_id).maximum(:date)
    end

    def source_clients_for_source_client(source_client_id:, data_source_id:)
      @source_clients ||= begin
        destination_ids = client_scope.entry.select(:client_id)
        client_source.joins(:warehouse_client_source).
          merge(GrdaWarehouse::WarehouseClient.where(destination_id: destination_ids)).
          distinct.
          pluck(*source_client_columns.values).
          map do |row|
            Hash[source_client_columns.keys.zip(row)]
          end.group_by do |row|
            [
              row[:data_source_id],
              row[:destination_id],
            ]
          end
      end
      key = [data_source_id, source_client_id]
      @source_clients[key]
    end

    def clients_for_project project_id
      client_scope.entry.where(Project: { id: project_id }).
        select(*client_columns.values).
        distinct.
        pluck(*client_columns.values.map { |column| Arel.sql(column) }).
        map do |row|
          Hash[client_columns.keys.zip(row)]
        end
    end
    memoize :clients_for_project

    def enrollments
      @enrollments ||= begin
        Rails.logger.debug 'Loading Enrollments'
        client_scope.entry.pluck(*enrollment_columns.values.map { |column| Arel.sql(column) }).
          map do |row|
          Hash[enrollment_columns.keys.zip(row)]
        end.
          group_by { |m| m[:id]}
      end
    end

    def enrollments_for_project project_id, data_source_id
      @enrollments_for_project ||= begin
        indexed ||= {}
        enrollments.each do |client_id, involved_enrollments|
          involved_enrollments.each do |en|
            indexed[[en[:project_id], en[:data_source_id]]] ||= {}
            indexed[[en[:project_id], en[:data_source_id]]][client_id] ||= []
            indexed[[en[:project_id], en[:data_source_id]]][client_id] << en
          end
        end
        indexed
      end
      @enrollments_for_project[[project_id, data_source_id]]
    end

    def incomes
      @incomes ||= begin
        incomes = {}
        # enrollments is keyed on source client id
        enrollments.each do |client_id, client_enrollments|
          # Use last enrollment within window for the client, per HUD Data Quality Spec
          enrollment_id = client_enrollments.last[:enrollment_id]
          assessments = income_assessment_for(source_client_id: client_id, enrollment_id: enrollment_id) || []
          incomes[client_id] = assessments
        end
        incomes
      end
    end

    def income_assessment_for source_client_id:, enrollment_id:
      @all_incomes_by_client_id_enrollment_id ||= all_incomes.group_by do |m|
        [
          m[:client_id],
          m[:enrollment_id],
        ]
      end
      @all_incomes_by_client_id_enrollment_id[[source_client_id, enrollment_id]]
    end

    def income_assessment_at_stage_for source_client_id:, enrollment_id:, data_collection_stage:
      @all_incomes_by_client_id_enrollment_id_and_stage ||= all_incomes.group_by do |m|
        [
          m[:client_id],
          m[:enrollment_id],
          m[:DataCollectionStage],
        ]
      end
      @all_incomes_by_client_id_enrollment_id_and_stage[[source_client_id, enrollment_id, data_collection_stage]]
    end

    def disabilities
      project_entry_ids = enrollments.values.flatten.map { |en| en[:project_entry_id]}.uniq
      @disabilities ||= disability_source.joins(enrollment: :client).
        where(d_t[:InformationDate].lteq(self.end)).
        where(EnrollmentID: project_entry_ids).
        order(InformationDate: :asc).
        pluck(*disability_columns.values).map do |row|
          Hash[disability_columns.keys.zip(row)]
        end.group_by do |row|
          [row[:client_id], row[:project_id], row[:project_entry_id], row[:data_source_id]]
        end
    end

    def disabilities_for_enrollment enrollment
      key = [
        enrollment[:id],
        enrollment[:project_id],
        enrollment[:project_entry_id],
        enrollment[:data_source_id],
      ]
      disabilities.try(:[], key)
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
    memoize :leavers_for_project

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
      @beds ||= projects.flat_map(&:inventories).map { |i| i[:BedInventory] || 0}.reduce(:+) || 0
    end

    def hmis_beds
      @hmis_beds ||= projects.flat_map(&:inventories).map { |i| i[:HMISParticipatingBeds] || 0}.reduce(:+) || 0
    end

    def income_columns
      @income_columns ||= {
        enrollment_id: she_t[:id].to_sql,
        destination_id: she_t[:client_id].to_sql,
        client_id: c_t[:id].to_sql, # source client_id
        enrollment_group_id: she_t[:enrollment_group_id].to_sql,
        personal_id: c_t[:PersonalID].to_sql,
        data_source_id: e_t[:data_source_id].to_sql,
        TotalMonthlyIncome: ib_t[:TotalMonthlyIncome].to_sql,
        IncomeFromAnySource: ib_t[:IncomeFromAnySource].to_sql,
        InformationDate: ib_t[:InformationDate].to_sql,
        DataCollectionStage: ib_t[:DataCollectionStage].to_sql,
      }.merge(amount_columns)
    end

    def disability_columns
      @disability_columns ||= {
        client_id: c_t[:id].to_sql,
        project_id: e_t[:ProjectID].to_sql,
        project_entry_id: d_t[:EnrollmentID].to_sql,
        data_source_id: d_t[:data_source_id].to_sql,
        disability_type: d_t[:DisabilityType].to_sql,
        disability_response: d_t[:DisabilityResponse].to_sql,
        information_date: d_t[:InformationDate].to_sql,
      }
    end

    def amount_columns
      @amount_columns ||= {
        Earned: ib_t[:Earned].to_sql,
        EarnedAmount: ib_t[:EarnedAmount].to_sql,
        UnemploymentAmount: ib_t[:UnemploymentAmount].to_sql,
        SSIAmount: ib_t[:SSIAmount].to_sql,
        SSDIAmount: ib_t[:SSDIAmount].to_sql,
        VADisabilityServiceAmount: ib_t[:VADisabilityServiceAmount].to_sql,
        VADisabilityNonServiceAmount: ib_t[:VADisabilityNonServiceAmount].to_sql,
        PrivateDisabilityAmount: ib_t[:PrivateDisabilityAmount].to_sql,
        WorkersCompAmount: ib_t[:WorkersCompAmount].to_sql,
        TANFAmount: ib_t[:TANFAmount].to_sql,
        GAAmount: ib_t[:GAAmount].to_sql,
        SocSecRetirementAmount: ib_t[:SocSecRetirementAmount].to_sql,
        PensionAmount: ib_t[:PensionAmount].to_sql,
        ChildSupportAmount: ib_t[:ChildSupportAmount].to_sql,
        AlimonyAmount: ib_t[:AlimonyAmount].to_sql,
        OtherIncomeAmount: ib_t[:OtherIncomeAmount].to_sql,
      }
    end

    def enrollment_columns
      @enrollment_columns ||= {
        id: c_t[:id].to_sql,
        project_id: she_t[:project_id].to_sql,
        project_name: she_t[:project_name].to_sql,
        enrollment_id: she_t[:id].to_sql,
        enrollment_group_id: she_t[:enrollment_group_id].to_sql,
        first_date_in_program: she_t[:first_date_in_program].to_sql,
        last_date_in_program: she_t[:last_date_in_program].to_sql,
        destination: she_t[:destination].to_sql,
        household_id: she_t[:household_id].to_sql,
        personal_id: c_t[:PersonalID].to_sql,
        data_source_id: e_t[:data_source_id].to_sql,
        residence_prior: e_t[:LivingSituation].to_sql,
        disabling_condition: e_t[:DisablingCondition].to_sql,
        last_permanent_zip: e_t[:LastPermanentZIP].to_sql,
        project_entry_id: e_t[:EnrollmentID].to_sql,
        first_name: c_t[:FirstName].to_sql,
        last_name: c_t[:LastName].to_sql,
        name_data_quality: c_t[:NameDataQuality].to_sql,
        ssn: c_t[:SSN].to_sql,
        ssn_data_quality: c_t[:SSNDataQuality].to_sql,
        dob: c_t[:DOB].to_sql,
        dob_data_quality: c_t[:DOBDataQuality].to_sql,
        destination_id: she_t[:client_id].to_sql,
        age: she_t[:age].to_sql,
        head_of_household: she_t[:head_of_household].to_sql,
        enrollment_created: e_t[:DateCreated].as('enrollment_created').to_sql,
        exit_created: ex_t[:DateCreated].as('exit_created').to_sql,
      }
    end

    def common_client_columns
      @common_client_columns ||= {
        id: c_t[:id].to_sql,
        first_name: c_t[:FirstName].to_sql,
        last_name: c_t[:LastName].to_sql,
        name_data_quality: c_t[:NameDataQuality].to_sql,
        ssn: c_t[:SSN].to_sql,
        ssn_data_quality: c_t[:SSNDataQuality].to_sql,
        dob: c_t[:DOB].to_sql,
        dob_data_quality: c_t[:DOBDataQuality].to_sql,
        veteran_status: c_t[:VeteranStatus].to_sql,
        ethnicity: c_t[:Ethnicity].to_sql,
        gender: c_t[:Gender].to_sql,
        race_none: c_t[:RaceNone].to_sql,
        am_ind_ak_native: c_t[:AmIndAKNative].to_sql,
        asian: c_t[:Asian].to_sql,
        black_af_american: c_t[:BlackAfAmerican].to_sql,
        native_hi_other_pacific: c_t[:NativeHIPacific].to_sql,
        white: c_t[:White].to_sql,
        data_source_id: c_t[:data_source_id].to_sql,
      }
    end

    def client_columns
      @client_columns ||= {
        enrollment_id: she_t[:id].to_sql,
        destination_id: she_t[:client_id].to_sql,
        first_date_in_program: she_t[:first_date_in_program].to_sql,
        last_date_in_program: she_t[:last_date_in_program].to_sql,
        destination: she_t[:destination].to_sql,
      }.merge(common_client_columns)
    end

    def source_client_columns
      @source_client_columns ||= {
        destination_id: wc_t[:destination_id].to_sql,
      }.merge(common_client_columns)
    end

    def service_columns
      @service_columns ||= {
        id: c_t[:id].to_sql,
        client_id: she_t[:client_id].to_sql,
        first_name: c_t[:FirstName].to_sql,
        last_name: c_t[:LastName].to_sql,
        project_name: she_t[:project_name].to_sql,
        enrollment_group_id: she_t[:enrollment_group_id].to_sql,
        # date: shs_t[:date].as('date').to_sql,
        first_date_in_program: she_t[:first_date_in_program].to_sql,
        last_date_in_program: she_t[:last_date_in_program].to_sql,
      }
    end

    def start_report
      self.started_at = Time.now
      self.report = {}
      self.support = {}
    end

    def finish_report
      self.completed_at = Time.now
      save
      notify_requestor
    end

    def report_type
      if projects.count == 1
        :project
      else
        :project_group
      end
    end

    def status
      return 'Error' if processing_errors.present?
      return 'Incomplete' if completed_at.blank?
      return "#{start} - #{self.end}" if completed_at.present?
    end

    def add_answers(answers, support = {})
      assign_attributes(report: report.merge(answers))
      assign_attributes(support: self.support.merge(support)) if support.present?
      save
    end

    def send_notifications
      contacts = project_contacts + organization_contacts + project_group_contacts + organization_project_group_contacts
      contacts.index_by(&:email).values.each do |contact|
        ProjectDataQualityReportMailer.report_complete(projects, self, contact).deliver
      end
      notifications_sent
    end

    def notify_requestor
      return unless requestor.present?

      ProjectDataQualityReportMailer.report_complete(projects, self, requestor).deliver
    end

    def requestor
      return nil unless requestor_id.present?

      @requestor ||= User.active.find_by(id: requestor_id)
    end

    def notifications_sent
      update(sent_at: Time.now)
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

    def missing_race?(value)
      return true if value.blank?

      [0, 99].include?(value.to_i)
    end

    def adult?(age)
      return true if age.blank?

      age >= 18
    end

    def age dob
      GrdaWarehouse::Hud::Client.age date: start, dob: dob
    end

    def missing_disability? disabilities
      return true if disabilities.blank?

      max_information_date = disabilities.map { |dis| dis[:information_date]}.max
      disabilities.select do |dis|
        dis[:information_date] == max_information_date
      end.map do |dis|
        dis[:disability_response]
      end.include? 99
    end

    def refused_diability? disabilities
      return false if disabilities.blank?

      max_information_date = disabilities.map { |dis| dis[:information_date]}.max
      disabilities.select do |dis|
        dis[:information_date] == max_information_date
      end.map do |dis|
        dis[:disability_response]
      end.include? 9
    end

    def unknown_disability? disabilities
      return false if disabilities.blank?

      max_information_date = disabilities.map { |dis| dis[:information_date]}.max
      disabilities.select do |dis|
        dis[:information_date] == max_information_date
      end.map do |dis|
        dis[:disability_response]
      end.include? 8
    end

    def in_percentage numerator, denominator
      percentage = ((numerator.to_f / denominator) * 100)
      if percentage.finite?
        percentage.round(2)
      else
        0
      end
    end

    # Display methods
    def percent(value)
      "#{value}%"
    end

    def boolean(value)
      value ? 'Yes' : 'No'
    end

    def days(value)
      "#{value} days"
    end

    def destination_id_for_client(source_id)
      @destination_ids ||= begin
        GrdaWarehouse::WarehouseClient.where(source_id: client_scope.entry.select(c_t[:id])).
          pluck(:source_id, :destination_id).
          to_h
      end
      @destination_ids[source_id]
    end

    def client_source
      GrdaWarehouse::Hud::Client.source
    end

    def service_source
      GrdaWarehouse::ServiceHistoryEnrollment.entry
    end

    def service_history_enrollment_scope
      service_source.
        joins(:project, :enrollment, enrollment: :client).
        includes(enrollment: :exit).
        references(enrollment: :exit)
    end

    def client_scope
      service_source.
        open_between(start_date: start.to_date - 1.day,
                     end_date: self.end).
        joins(:project, :enrollment, enrollment: :client).
        includes(enrollment: :exit).
        references(enrollment: :exit).
        where(Project: { id: projects.map(&:id) })
    end

    def service_scope
      service_source.includes(:service_history_services).
        references(:service_history_services).
        open_between(start_date: start.to_date - 1.day,
                     end_date: self.end).
        joins(:project, enrollment: :client).
        includes(enrollment: :exit).
        references(enrollment: :exit).
        where(Project: { id: projects.map(&:id) })
    end

    def projects
      @projects ||= begin
        if project_group_id.present?
          project_group.projects
        else
          [project]
        end
      end
    end

    def self.length_of_stay_buckets
      {
        '0 days' => (0..0),
        '1 - 90 days' => (1..90),
        '91 - 364 days' => (91..364),
        '1 - 2 years' => (365..729),
        '2 - 3 years' => (730..1094),
        '3 years or more' => (1095..1.0 / 0),
      }
    end

    def income_source
      GrdaWarehouse::Hud::IncomeBenefit
    end

    def all_incomes
      @all_incomes ||= service_history_enrollment_scope.
        joins(enrollment: :income_benefits).
        pluck(*income_columns.values.map { |column| Arel.sql(column) }).map do |row|
          Hash[income_columns.keys.zip(row)]
        end
    end

    def disability_source
      GrdaWarehouse::Hud::Disability
    end
  end
end

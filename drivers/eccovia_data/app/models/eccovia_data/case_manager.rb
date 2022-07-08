###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module EccoviaData
  class CaseManager < GrdaWarehouseBase
    include Shared
    self.table_name = :eccovia_case_managers
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    acts_as_paranoid

    # NOTE: this is how you get assigned case manager for a client:
    # Enrollment.ClntCaseID - cmCaseAssign.ClntCaseID : cmCaseAssign.UserID - osUsers.UserID

    # EccoviaData::Fetch.last.credentials.fields('cmCaseAssign')
    # ["ClntCaseID", "ClientID", "UserID", "ProgID", "CaseMgrID", "usrPgmMgrId", "ClientName", "CaseMgrName", "EnrollID", "Status", "BeginDate", "EndDate", "language", "dsiSerNo", "RegionID", "caseMgrLang", "ProviderID", "RestrictOrg", "OrgID", "CreatedBy", "CreatedDate", "UpdatedBy", "UpdatedDate", "ActiveStatus", "RoleID"]

    # EccoviaData::Fetch.last.credentials.fields('Enrollment')
    # ["EnrollID", "ClientID", "CaseID", "ApplicationID", "EnrollDate", "EnrollAssessmentID", "ExitAssessmentID", "ExitDate", "ExitReason", "ExitReasonOther", "ExitDestination", "ExitDestinationOther", "ExitTenure", "ExitSubsidyType", "ExitNotes", "Relationship", "BudgetAmount", "BudgetDate", "Comments", "ClntCaseID", "HoldOpen", "RestrictOrg", "OrgID", "CreatedBy", "CreatedDate", "UpdatedBy", "UpdatedDate", "ActiveStatus", "EngagementDate", "PlannedExitDate", "PrimaryHousingID", "RegionID", "ParentEnrollID", "AutoExit1DateAdded"]

    # NOTE: for now, we only want to fetch data related to enrollments in CE projects
    def self.fetch_updated(data_source_id:, credentials:)
      since = max_fetch_time(data_source_id) || default_lookback
      fetch_time = Time.current
      ids = warehouse_enrollment_ids(data_source_id: data_source_id, credentials: credentials, since: since)
      ids.each_slice(EccoviaData::Credential::PAGE_SIZE) do |id_batch|
        query = "crql?q=select ClientID, EnrollID, ClntCaseID from Enrollment where EnrollID in (#{quote(id_batch)}) and UpdatedDate > '#{since.to_s(:db)}'"
        credentials.get_all_in_batches(query) do |enrollments|
          break unless enrollments.present?

          assignment_objects = assignments(enrollments.map { |a| a['ClntCaseID'] }.uniq, credentials: credentials).index_by { |u| u['ClntCaseID'] }
          user_objects = users(assignment_objects.values.map { |a| a['UserID'] }.uniq, credentials: credentials).index_by { |u| u['UserID'] }

          added = Set.new
          batch = enrollments.map do |enrollment|
            assignment = assignment_objects[enrollment['ClntCaseID']]
            next if assignment.blank?

            user = user_objects[assignment['UserID']]
            next if user.blank?
            next if added.include?([data_source_id, enrollment['ClientID'], enrollment['ClntCaseID'], assignment['UserID']])

            added << [data_source_id, enrollment['ClientID'], enrollment['ClntCaseID'], assignment['UserID']]
            new(
              data_source_id: data_source_id,
              client_id: enrollment['ClientID'],
              case_manager_id: enrollment['ClntCaseID'],
              user_id: assignment['UserID'],
              start_date: assignment['BeginDate'],
              end_date: assignment['EndDate'],
              first_name: user['UserName']&.split(' ')&.first,
              last_name: user['UserName']&.split(' ')&.last,
              email: user['Email'],
              phone: user['OfficePhone'],
              cell: user['CellPhone'],
              last_fetched_at: fetch_time,
            )
          end

          import(
            batch.compact,
            on_duplicate_key_update: {
              conflict_target: [:client_id, :data_source_id, :case_manager_id, :user_id],
              columns: [
                :start_date,
                :end_date,
                :first_name,
                :last_name,
                :email,
                :phone,
                :cell,
                :last_fetched_at,
              ],
            },
            validate: false,
          )
        end
      end
      remove_deleted(data_source_id: data_source_id, credentials: credentials)
    end

    def self.remove_deleted(data_source_id:, credentials:)
      where(data_source_id: data_source_id).where.not(case_manager_id: all_assignment_ids(credentials: credentials)).destroy_all
    end

    def self.warehouse_enrollment_ids(data_source_id:, credentials:, since:)
      # For development, since our EnrollmentIDs won't line up, we'll just fetch everything from the staging environment
      if Rails.env.development?
        query = 'crql?q=select EnrollID from Enrollment'
        credentials.get_all(query)&.map { |a| a['EnrollID'] }
      else
        GrdaWarehouse::Hud::Enrollment.where(data_source_id: data_source_id).
          with_project_type(14).
          where(DateUpdated: since.to_date..Date.current).
          pluck(:EnrollmentID)
      end
    end

    def self.assignments(ids, credentials:)
      query = "crql?q=SELECT ClntCaseID, UserID FROM cmCaseAssign where ClntCaseID in (#{quote(ids)})"
      credentials.get_all(query)
    end

    def self.all_assignment_ids(credentials:)
      query = 'crql?q=select ClntCaseID from cmCaseAssign'
      credentials.get_all(query)&.map { |a| a['ClntCaseID'] }
    end

    def name
      "#{first_name} #{last_name}"
    end
  end
end

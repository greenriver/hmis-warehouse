# require 'newrelic_rpm'
module GrdaWarehouse::Tasks::ServiceHistory
  class Enrollment < GrdaWarehouse::Hud::Enrollment
    include TsqlImport
    include ActiveSupport::Benchmarkable
    
    after_commit :force_validity_calculation

    def service_history_valid?
      processed_hash == calculate_hash
    end
    def source_data_changed?
      ! service_history_valid?
    end

    def should_rebuild?
      source_data_changed?
    end

    def should_patch?
      return true if entry_exit_tracking? && exit.blank?
      build_for_dates.keys.sort != service_dates_from_service_history_for_enrollment().sort
    end

    # One method to rule them all.  This makes the determination if it
    # should patch or rebuild, or do nothing.  If you need more fine grained control
    # use patch_service_history! or create_service_history! directly
    def rebuild_service_history!
      action = false
      if should_rebuild?
        action = :update if create_service_history!
      elsif should_patch?
        action = :patch if patch_service_history!
      end
      return action
    end

    def patch_service_history!
      days = []
      build_for_dates.except(
        *service_dates_from_service_history_for_enrollment()
      ).each do |date, type_provided|
        days << service_record(date, type_provided)
      end
      if days.any?
        insert_batch(service_history_source, days.first.keys, days.map(&:values), transaction: false)
        update(processed_hash: calculate_hash)
      end
      return true
    end

    def create_service_history! force=false
      # Rails.logger.debug '===RebuildEnrollmentsJob=== Initiating create_service_history'
      # Rails.logger.debug ::NewRelic::Agent::Samplers::MemorySampler.new.sampler.get_sample
      return false unless force || source_data_changed?
      # Rails.logger.debug '===RebuildEnrollmentsJob=== Checked for changes'
      # Rails.logger.debug ::NewRelic::Agent::Samplers::MemorySampler.new.sampler.get_sample
      self.class.transaction do 
        remove_existing_service_history_for_enrollment()
        # sometimes we have enrollments for projects that no longer exist
        return false unless project.present?
        days = []
        date = self.EntryDate
        type_provided = project.computed_project_type
        days << entry_record(date, type_provided)
        # Rails.logger.debug '===RebuildEnrollmentsJob=== Building days'
        # Rails.logger.debug ::NewRelic::Agent::Samplers::MemorySampler.new.sampler.get_sample
        build_for_dates.each do |date, type_provided|
          days << service_record(date, type_provided)
        end
        # Rails.logger.debug '===RebuildEnrollmentsJob=== Days built'
        # Rails.logger.debug ::NewRelic::Agent::Samplers::MemorySampler.new.sampler.get_sample
        if exit.present?
          date = exit.ExitDate
          type_provided = build_for_dates.values.last
          days << exit_record(date, type_provided)
        end
        insert_batch(service_history_source, days.first.keys, days.map(&:values), transaction: false)
      end
      update(processed_hash: calculate_hash)
      return true
    end

    def entry_record date, type_provided
      default_day.merge({
        date: date,
        age: client_age_at(date),
        service_type: type_provided,
        record_type: :entry,
      })
    end

    def exit_record date, type_provided
      default_day.merge({
        date: date,
        age: client_age_at(date),
        service_type: type_provided,
        record_type: :exit,
      })
    end

    def service_record date, type_provided
      default_day.merge({
        date: date,
        age: client_age_at(date),
        service_type: type_provided,
        record_type: :service,
      })
    end

    def client_age_at date
      return unless destination_client.DOB.present? && date.present?
      dob = destination_client.DOB.to_date
      age = date.to_date.year - dob.year
      age -= 1 if dob > date.to_date.years_ago( age )
      # You have to be explicit here -= does not return age
      return age
    end

    def calculate_hash
      @calculate_hash ||= self.class.calculate_hash_for(id)
    end

    def service_dates_from_service_history_for_enrollment
      return [] unless destination_client.present?
      service_history_source.where(
        client_id: destination_client.id, 
        enrollment_group_id: self.ProjectEntryID, 
        data_source_id: data_source_id, 
        project_id: self.ProjectID,
        record_type: :service
      ).order(date: :asc).
      pluck(:date)
    end

    def remove_existing_service_history_for_enrollment
      return unless destination_client.present?
      service_history_source.where(
        client_id: destination_client.id, 
        enrollment_group_id: self.ProjectEntryID, 
        data_source_id: data_source_id, 
        project_id: self.ProjectID,
        record_type: [:entry, :exit, :service],
      ).delete_all
    end

    def self.calculate_hash_for(id)
      # Rails.logger.debug '===RebuildEnrollmentsJob=== Calculating Hash'
      # Rails.logger.debug ::NewRelic::Agent::Samplers::MemorySampler.new.sampler.get_sample

      # Break this into two queries to speed it up and keep RAM usage in check
      rows = source_rows(id) + service_history_rows(id)
      Digest::SHA256.hexdigest(rows.to_s)
    end

    def self.source_rows(id)
      # This must be explicitly ordered since the database doesn't always
      # return data in the same order
      where(id: id).
        includes(:exit, :services, :destination_client).
        references(:exit, :services, :destination_client).
        order(
          e_t[:EntryDate].asc, 
          ex_t[:ExitDate].asc, 
          s_t[:DateProvided].asc,
          e_t[:ProjectID].asc,
          e_t[:DateDeleted].asc,
          s_t[:DateDeleted].asc,
          ex_t[:DateDeleted].asc,
          e_t[:HouseholdID].asc,
          ex_t[:Destination].asc
        ).
        pluck(*hash_columns)
    end

    def self.service_history_rows(id)
      # setup a somewhat compliacated join with service history
      join_sh_t_sql = e_t.join(sh_t).
      on(e_t[:ProjectID].eq(sh_t[:project_id]).
        and(e_t[:data_source_id].eq(sh_t[:data_source_id])).
        and(e_t[:ProjectEntryID].eq(sh_t[:enrollment_group_id]))
      ).to_sql.gsub('SELECT FROM "Enrollment"', '')

      # This must be explicitly ordered since the database doesn't always
      # return data in the same order
      where(id: id).
        joins(:destination_client).
        where(Client: {id: sh_t[:client_id]}).
        joins(join_sh_t_sql).
        where(warehouse_client_service_history: {record_type: [:entry, :exit, :service]}).
        order(sh_t[:date].asc, sh_t[:record_type].asc).
        pluck(*service_history_hash_columns)
    end

    def default_day
      {
        client_id: destination_client.id,
        date: nil,
        first_date_in_program: self.EntryDate,
        last_date_in_program: exit&.ExitDate,
        enrollment_group_id: self.ProjectEntryID,
        service_type: nil,
        project_type: project.ProjectType,
        computed_project_type: project.computed_project_type,
        project_id: self.ProjectID,
        data_source_id: data_source_id,
        age: nil,
        destination: exit&.Destination,
        head_of_household_id: head_of_household_id,
        household_id: self.HouseholdID,
        project_name: project.ProjectName,
        organization_id: project.OrganizationID,
        project_tracking_method: project.TrackingMethod,
        record_type: nil,
        housing_status_at_entry: self.HousingStatus,
        housing_status_at_exit: exit&.HousingAssessment,
      }
    end

    def service_type_from_project_type project_type
      # ProjectType
      # 1 Emergency Shelter
      # 2 Transitional Housing
      # 3 PH - Permanent Supportive Housing
      # 4 Street Outreach
      # 6 Services Only
      # 7 Other
      # 8 Safe Haven
      # 9 PH – Housing Only
      # 10  PH – Housing with Services (no disability required for entry)
      # 11  Day Shelter
      # 12  Homelessness Prevention
      # 13  PH - Rapid Re-Housing
      # 14  Coordinated Assessment

      # RecordType
      # 12  Contact   4.12
      # 141 PATH service  4.14 A
      # 142 RHY service   4.14 B
      # 143 HOPWA service   4.14 C
      # 144 SSVF service    4.14 D
      # 151 HOPWA financial assistance  4.15 A
      # 152 SSVF financial assistance   4.15 B
      # 161 Path referral     4.16 A
      # 162 RHY referral  4.16 B
      # 200 Bed night   (none)

      # We will infer a bed night if the project type is housing related, everything else is nil for now
      housing_related = [1,2,3,4,8,9,10,13]
      return 200 if housing_related.include?(project_type)
      nil
    end

    def head_of_household_id
      @head_of_household_id ||= if is_head_of_household?
        self.PersonalID
      else
        self.class.where(
          ProjectEntryID: self.ProjectEntryID, 
          data_source_id: data_source_id,
          RelationshipToHoH: [nil, 1]
        ).pluck(:PersonalID)&.first || self.PersonalID
      end
    end

    def head_of_household
      GrdaWarehouse::Hud::Client.where(PersonalID: head_of_household_id)
    end

    def is_head_of_household?
      self.RelationshipToHoH.blank? || self.RelationshipToHoH == 1 # 1 = Self
    end

    def entry_exit_tracking?
      # This project isn't listed as a bed-night project AND isn't an SO project that behaves as a bed-night project
      @entry_exit_tracking ||= project.TrackingMethod != 3 && ! street_outreach_acts_as_bednight?
    end

    def street_outreach_acts_as_bednight?
      @street_outreach_acts_as_bednight ||= services.joins(:project).where(
        Services: {RecordType: 12}, 
        Project: {ProjectType: GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:so]}
      ).exists?
    end

    def build_for_dates
      if entry_exit_tracking?
        (self.EntryDate..build_until).map do |date|
          [date, service_type_from_project_type(project.computed_project_type)]
        end.to_h
      else
        # Fetch all services provided between the start of the enrollment and the end of the build period
        services.where(DateProvided: (self.EntryDate..build_until)).
        order(DateProvided: :asc).
        pluck(:DateProvided, :TypeProvided).to_h
      end
    end

    # Build until the exit if we have one, or the lesser of the various coverage options
    def build_until
      @build_until ||= if exit&.ExitDate.present?
        # no bed night should be given on the exit date per System Performance Measures programming spec: The [project exit date] itself is not included because it does not represent a night spent in the project.
        # We will count the stay as one day if the entry and exit are on the same day
        if entry_exit_tracking? && self.EntryDate != exit.ExitDate
          exit.ExitDate - 1.day
        else
          exit.ExitDate # Trust the data for night-by-night
        end
      else
        [
          export.effective_export_end_date,
          export.ExportEndDate,
          Date.today,
        ].compact.min.to_date
      end
    end

    # FIXME: We can't use this because out-of order exports only have access to part of their 
    # data after import (some remains attached to other exports, and the max updated dates get off)
    def export_max_coverage
      # Attempt to determine the max useful range for this export.
      # We look to the actual data instead of relying on ExportDate since that 
      # has proven unreliable
      # @export_max_coverage ||= [
      #   export.enrollments.maximum(:DateUpdated), 
      #   export.exits.maximum(:DateUpdated),
      #   export.services.maximum(:DateUpdated),
      # ].compact.max
    end

    # Our hash needs to be different if any of the source data has changed,
    # if any of the destination data has changed
    # or if the enrollment has been connected to a new destination client
    def self.hash_columns
      @hash_columns ||= begin
        client_hash_columns = {
          destination_client_id: :id,
        }
        enrollment_hash_columns = {
          id: :id,
          data_source_id: :data_source_id,
          entry_date: :EntryDate,
          project_id: :ProjectID,
          deleted_at: :DateDeleted,
          household_id: :HouseholdID,
        }
        
        exit_hash_columns = {
          exit_date: :ExitDate,
          deleted_at: :DateDeleted,
          data_source_id: :data_source_id,
          destination: :Destination,
        }
        
        service_hash_columns = {
          date_provided: :DateProvided,
          deleted_at: :DateDeleted,
          data_source_id: :data_source_id,
        }
        
        columns = enrollment_hash_columns.values.map do |col|
          e_t[col].as(col.to_s).to_sql
        end
        columns += exit_hash_columns.values.map do |col|
          ex_t[col].as(col.to_s).to_sql
        end
        columns += service_hash_columns.values.map do |col|
          s_t[col].as(col.to_s).to_sql
        end
        columns += client_hash_columns.values.map do |col|
          c_t[col].as(col.to_s).to_sql
        end
        columns
      end
    end

    def self.service_history_hash_columns
      @service_history_hash_columns ||= begin
        service_history_columns = {
          client_id: :client_id,
          date: :date,
          record_type: :record_type,
        }
        columns = service_history_columns.values.map do |col|
          sh_t[col].as(col.to_s).to_sql
        end
        columns
      end
    end

    def service_history_source
      GrdaWarehouse::ServiceHistory
    end

    def force_validity_calculation
      @calculate_hash = nil
    end
  end # end Enrollment class
end
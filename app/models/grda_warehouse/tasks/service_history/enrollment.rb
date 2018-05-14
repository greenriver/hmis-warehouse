# require 'newrelic_rpm'
module GrdaWarehouse::Tasks::ServiceHistory
  class Enrollment < GrdaWarehouse::Hud::Enrollment
    include TsqlImport
    include ArelHelper
    include ActiveSupport::Benchmarkable
    
    after_commit :force_validity_calculation

    scope :unprocessed, -> do
      where(processed_as: nil)
    end

    def service_history_valid?
      processed_as.present? && processed_as == calculate_hash
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
      return false if destination_client.blank? || project.blank?
      if should_rebuild?
        action = :update if create_service_history!
      elsif should_patch?
        action = :patch if patch_service_history!
      end
      return action
    end

    def patch_service_history!
      days = []
      # load the associated service history enrollment to get the id
      build_for_dates.except(
        *service_dates_from_service_history_for_enrollment()
      ).each do |date, type_provided|
        days << service_record(date, type_provided)
      end
      if days.any?
        insert_batch(service_history_service_source, days.first.keys, days.map(&:values), transaction: false)
        update(processed_as: calculate_hash)
      end
      return true
    end

    def create_service_history! force=false
      # Rails.logger.debug '===RebuildEnrollmentsJob=== Initiating create_service_history'
      # Rails.logger.debug ::NewRelic::Agent::Samplers::MemorySampler.new.sampler.get_sample
      return false unless force || source_data_changed?
      # Rails.logger.debug '===RebuildEnrollmentsJob=== Checked for changes'
      # Rails.logger.debug ::NewRelic::Agent::Samplers::MemorySampler.new.sampler.get_sample
      days = []
      if project.present?
        date = self.EntryDate
        self.class.transaction do
          remove_existing_service_history_for_enrollment()
          entry_day = entry_record(date)
          insert = build_service_history_enrollment_insert(entry_day)
          @entry_record_id = service_history_enrollment_source.connection.insert(insert.to_sql)
          # Rails.logger.debug '===RebuildEnrollmentsJob=== Building days'
          # Rails.logger.debug ::NewRelic::Agent::Samplers::MemorySampler.new.sampler.get_sample
          build_for_dates.each do |date, type_provided|
            days << service_record(date, type_provided)
          end
          if street_outreach_acts_as_bednight? && GrdaWarehouse::Config.get(:so_day_as_month)
            type_provided = build_for_dates.values.last
            days += add_extrapolated_days(build_for_dates.keys, type_provided)
          end
          # Rails.logger.debug '===RebuildEnrollmentsJob=== Days built'
          # Rails.logger.debug ::NewRelic::Agent::Samplers::MemorySampler.new.sampler.get_sample
          if exit.present?
            date = exit.ExitDate
            insert = build_service_history_enrollment_insert(exit_record(date))
            service_history_enrollment_source.connection.insert(insert.to_sql)
          end
        end
      
        # sometimes we have enrollments for projects that no longer exist
        return false unless project.present?
        if days.any?
          insert_batch(service_history_service_source, days.first.keys, days.map(&:values), transaction: false, batch_size: 1000)
        end
      end
      update(processed_as: calculate_hash)
      return true
    end

    def set_entry_record_id
      @entry_record_id ||= service_history_enrollment.id
    end

    def build_service_history_enrollment_insert day
      insert = Arel::Nodes::InsertStatement.new
      insert.relation = she_t
      insert.columns = day.keys.map{|k| she_t[k]}
      insert.values = Arel::Nodes::Values.new(day.values, insert.columns)
      return insert
    end

    def entry_record date
      default_day.merge({
        date: date,
        age: client_age_at(date),
        record_type: :entry,
      })
    end

    def exit_record date
      default_day.merge({
        date: date,
        age: client_age_at(date),
        record_type: :exit,
      })
    end

    def service_record date, type_provided
      default_service_day.merge({
        date: date,
        age: client_age_at(date),
        service_type: type_provided,
        record_type: :service,
      })
    end

    def extrapolated_record date, type_provided
      default_service_day.merge({
        date: date,
        age: client_age_at(date),
        service_type: type_provided,
        record_type: :extrapolated,
      })
    end

    # build out all days within the month
    # don't build for any dates we already have
    def add_extrapolated_days dates, type_provided
      extrapolated_dates = dates.map do |date|
        (date.beginning_of_month .. date.end_of_month).to_a
      end.flatten(1).uniq
      # Don't build extrapolations for any day we already have
      extrapolated_dates -= dates
      extrapolated_dates -= extrapolated_dates_from_service_history_for_enrollment
      extrapolated_dates -= service_dates_from_service_history_for_enrollment

      extrapolated_dates.map do |date|
        extrapolated_record(date, type_provided)
      end
    end

    def client_age_at date
      destination_client.age_on(date)
    end

    def client_age_at_entry
      @client_age_at_entry ||= destination_client.age_on(self.EntryDate)
    end

    def calculate_hash
      @calculate_hash ||= self.class.calculate_hash_for(id)
    end

    # limit the date range so we can speed up partitioning searches
    def date_range
      beginning_of_range = service_history_enrollment.first_date_in_program
      @date_range ||= if service_history_enrollment.last_date_in_program.present?
        end_of_range = service_history_enrollment.last_date_in_program
        shs_t[:date].between(beginning_of_range..end_of_range)
      else
        shs_t[:date].gteq(beginning_of_range)
      end
    end

    def service_dates_from_service_history_for_enrollment
      return [] unless destination_client.present?
      set_entry_record_id()
      
      @service_dates_from_service_history_for_enrollment ||= service_history_service_source.
        where(
          record_type: :service,
          service_history_enrollment_id: @entry_record_id
        ).where(date_range).
        order(date: :asc).
        pluck(:date)
    end

    def extrapolated_dates_from_service_history_for_enrollment
      return [] unless destination_client.present?
      set_entry_record_id()
      @extrapolated_dates_from_service_history_for_enrollment ||= service_history_service_source.
        extrapolated.where(
          service_history_enrollment_id: @entry_record_id
        ).where(date_range).
        order(date: :asc).
        pluck(:date)
    end

    def remove_existing_service_history_for_enrollment
      return unless destination_client.present?
      service_history_enrollment_source.where(
        client_id: destination_client.id, 
        enrollment_group_id: self.ProjectEntryID, 
        data_source_id: data_source_id, 
        project_id: self.ProjectID,
        record_type: [:entry, :exit],
      ).delete_all
      reset_instance_variables()
    end

    def reset_instance_variables
      @extrapolated_dates_from_service_history_for_enrollment = nil
      @service_dates_from_service_history_for_enrollment = nil
      @calculate_hash = nil
      @head_of_household_id = nil
      @household_birthdates = nil
      @other_clients_over_25 = nil
      @other_clients_under_18 = nil
      @other_clients_between_18_and_25 = nil
      @client_age_at_entry = nil
      @unaccompanied_youth = nil
      @parenting_youth = nil
      @parenting_juvenile = nil
      @children_only = nil
      @individual_adult = nil
      @individual_elder = nil
      @presented_as_individual = nil
      @default_day = nil
      @entry_record_id = nil
      @street_outreach_acts_as_bednight = nil
      @entry_exit_tracking = nil
      @build_until = nil
      @build_for_dates = nil
      @default_service_day = nil
      @date_range = nil
    end

    def self.calculate_hash_for(id)
      # Rails.logger.debug '===RebuildEnrollmentsJob=== Calculating Hash'
      # Rails.logger.debug ::NewRelic::Agent::Samplers::MemorySampler.new.sampler.get_sample

      # Break this into two queries to speed it up and keep RAM usage in check
      # 
      # Ignore service history side, these should always be invalidated if clients are merged
      #rows = source_rows(id) + service_history_rows(id) 
      # rows = source_rows(id)
      # Digest::SHA256.hexdigest(rows.to_s)

      rows = source_rows(id)
      Digest::SHA256.hexdigest rows.join('|')
    end

    def self.source_rows(id)
      # This must be explicitly ordered since the database doesn't always
      # return data in the same order
      where(id: id).
        includes(:exit, :services, :destination_client).
        references(:exit, :services, :destination_client).
        order(*enrollment_column_order.map(&:to_sql).join(', ') + ' NULLS FIRST').
        pluck(nf('CONCAT', hash_columns).to_sql)
    end

    # def self.service_history_rows(id)
    #   # setup a somewhat complicated join with service history
    #   join_sh_t_sql = e_t.join(sh_t).
    #   on(e_t[:ProjectID].eq(sh_t[:project_id]).
    #     and(e_t[:data_source_id].eq(sh_t[:data_source_id])).
    #     and(e_t[:ProjectEntryID].eq(sh_t[:enrollment_group_id]))
    #   ).to_sql.gsub('SELECT FROM "Enrollment"', '')

    #   # This must be explicitly ordered since the database doesn't always
    #   # return data in the same order
    #   where(id: id).
    #     joins(:destination_client).
    #     where(Client: {id: sh_t[:client_id]}).
    #     joins(join_sh_t_sql).
    #     where(service_history_source.table_name => {record_type: [:entry, :exit, :service]}).
    #     order(*service_history_hash_columns_order).
    #     pluck(*service_history_hash_columns)
    # end

    # even with the load of the enrollment via active record, this is *way* faster
    # def self.service_history_rows(id)
    #   en = self.find(id)
    #   service_history_source.
    #     where(
    #       service_history_source.table_name => {record_type: [:entry, :exit, :service]},
    #       client_id: en.destination_client.id, 
    #       enrollment_group_id: en.ProjectEntryID, 
    #       data_source_id: en.data_source_id, 
    #       project_id: en.ProjectID,
    #     ).order(*service_history_hash_columns_order).
    #     pluck(*service_history_hash_columns)
    # end

    def default_day
      @default_day ||= {
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
        other_clients_over_25: other_clients_over_25,
        other_clients_under_18: other_clients_under_18,
        other_clients_between_18_and_25: other_clients_between_18_and_25,
        unaccompanied_youth: unaccompanied_youth?,
        parenting_youth: parenting_youth?,
        parenting_juvenile: parenting_juvenile?,
        head_of_household: head_of_household?,
        children_only: children_only?,
        individual_adult: individual_adult?,
        individual_elder: individual_elder?,
        presented_as_individual: presented_as_individual?,
      }
    end

    def default_service_day
      set_entry_record_id()
      @default_service_day ||= {
        service_history_enrollment_id: @entry_record_id,
        date: nil,
        service_type: nil,
        age: nil,
        record_type: nil,
        client_id: destination_client.id,
        project_type: project.computed_project_type,
      }
    end

    def household_birthdates
      @household_birthdates ||= begin
        self.class.joins(:destination_client).
          where(
            HouseholdID: self.HouseholdID,
            ProjectID: self.ProjectID,
            data_source_id: self.data_source_id
          ).where.not(
            PersonalID: self.PersonalID
          ).pluck(c_t[:DOB].as('dob').to_sql)
      end
    end

    def household_ages_at_entry
      household_birthdates.map do |dob|
        GrdaWarehouse::Hud::Client.age(date: self.EntryDate, dob: dob)
      end
    end

    def other_clients_over_25
      @other_clients_over_25 ||= if self.HouseholdID.blank?
         0
      else
        household_ages_at_entry.count do |age|
          age.present? && age > 24
        end
      end
    end

    def other_clients_under_18
      @other_clients_under_18 ||= if self.HouseholdID.blank?
        0
      else
        household_ages_at_entry.count do |age|
          age.present? && age < 18
        end
      end
    end

    def other_clients_between_18_and_25
      @other_clients_between_18_and_25 ||= if self.HouseholdID.blank?
        0
      else
        household_ages_at_entry.count do |age|
          youth?(age)
        end
      end
    end

    def child?(age)
      age.present? && age < 18
    end

    def youth?(age)
      age.present? && age < 25 && age > 17
    end

    def adult?(age)
      age.present? && age > 17
    end

    def elder?(age)
      age.present? && age > 64
    end

    # only 18-24 aged clients in the enrollment
    def unaccompanied_youth?
      @unaccompanied_youth ||= begin
        youth?(client_age_at_entry) && other_clients_over_25 == 0 && other_clients_under_18 == 0
      end
    end

    # client is a youth and presents with someone under 18, no other adults over 25 present
    def parenting_youth?
      @parenting_youth ||= begin
        youth?(client_age_at_entry) && other_clients_over_25 == 0 && other_clients_under_18 > 0 
      end
    end

    # client is under 18 and head of household and has at least one other client under 18 in enrollment
    def parenting_juvenile?
      @parenting_juvenile ||= begin
        child?(client_age_at_entry) && head_of_household? && other_clients_over_25 == 0 && other_clients_between_18_and_25 == 0 && other_clients_under_18 > 0 
      end
    end

    # everyone involved is under 18
    def children_only?
      @children_only ||= begin
        child?(client_age_at_entry) && other_clients_over_25 == 0 && other_clients_between_18_and_25 == 0
      end
    end

    # Everyone is over 18
    def individual_adult?
      @individual_adult ||= begin
        adult?(client_age_at_entry) && other_clients_under_18 == 0
      end
    end

    # This is a proxy for if the project served individuals or families
    # True = individuals
    def presented_as_individual?
      if @presented_as_individual.blank?
        @presented_as_individual = project.serves_only_individuals?
      else
        @presented_as_individual
      end
    end

    # Client is over 65 and everyone else is an adult
    def individual_elder?
      @individual_elder ||= begin
        elder?(client_age_at_entry) && other_clients_under_18 == 0
      end
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
      @head_of_household_id ||= if head_of_household?
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
 
    def head_of_household?
      self.RelationshipToHoH.blank? || self.RelationshipToHoH == 1 # 1 = Self
    end

    def entry_exit_tracking?
      # This project isn't listed as a bed-night project AND isn't an SO project that behaves as a bed-night project
      @entry_exit_tracking ||= project.TrackingMethod != 3 && ! street_outreach_acts_as_bednight?
    end

    def street_outreach_acts_as_bednight?
      @street_outreach_acts_as_bednight ||= if project.so?
          project.services.where(
          Services: {RecordType: 12},
        ).exists?
        else
          false
        end
    end

    def build_for_dates
      @build_for_dates ||= begin
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
        columns = enrollment_hash_columns.values.map do |col|
          [e_t[col], '_']
        end
        columns += exit_hash_columns.values.map do |col|
          [ex_t[col], '_']
        end
        columns += service_hash_columns.values.map do |col|
          [s_t[col], '_']
        end
        columns += client_hash_columns.values.map do |col|
          [c_t[col], '_']
        end
        columns.flatten
      end
    end

    def self.enrollment_column_order
      @enrollment_column_order ||= begin
        columns = enrollment_hash_columns.values.map do |col|
          e_t[col].asc
        end
        columns += exit_hash_columns.values.map do |col|
          ex_t[col].asc
        end
        columns += service_hash_columns.values.map do |col|
          s_t[col].asc
        end
        columns += client_hash_columns.values.map do |col|
          c_t[col].asc
        end
        columns    
      end
    end

    def self.client_hash_columns 
       @client_hash_columns ||= {
          destination_client_id: :id,
       }
    end
    def self.enrollment_hash_columns 
      @enrollment_hash_columns ||= {
        id: :id,
        data_source_id: :data_source_id,
        entry_date: :EntryDate,
        project_id: :ProjectID,
        deleted_at: :DateDeleted,
        household_id: :HouseholdID,
      }
    end
        
    def self.exit_hash_columns 
      @exit_hash_columns ||= {
        exit_date: :ExitDate,
        deleted_at: :DateDeleted,
        data_source_id: :data_source_id,
        destination: :Destination,
      }
    end
        
    def self.service_hash_columns 
      @service_hash_columns = {
        date_provided: :DateProvided,
        deleted_at: :DateDeleted,
        data_source_id: :data_source_id,
      }
    end

    # def self.service_history_hash_columns
    #   @service_history_hash_columns ||= begin
    #     columns = service_history_columns.values.map do |col|
    #       sh_t[col].as(col.to_s).to_sql
    #     end
    #     columns
    #   end
    # end

    # def self.service_history_hash_columns_order
    #   @service_history_hash_columns_order ||= begin
    #     columns = service_history_columns.values.map do |col|
    #       sh_t[col].asc
    #     end
    #     columns
    #   end
    # end

    # def self.service_history_columns 
    #   @service_history_columns ||= {
    #     client_id: :client_id,
    #     date: :date,
    #     record_type: :record_type,
    #   }
    # end


    def self.service_history_enrollment_source
      GrdaWarehouse::ServiceHistoryEnrollment
    end
    def service_history_enrollment_source
      self.class.service_history_enrollment_source
    end

    def self.service_history_service_source
      GrdaWarehouse::ServiceHistoryService
    end
    def service_history_service_source
      self.class.service_history_service_source
    end

    def force_validity_calculation
      @calculate_hash = nil
    end
  end # end Enrollment class
end
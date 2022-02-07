###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# require 'newrelic_rpm'
module GrdaWarehouse::Tasks::ServiceHistory
  class Enrollment < GrdaWarehouse::Hud::Enrollment
    # include TsqlImport
    include ArelHelper
    include ActiveSupport::Benchmarkable
    include ::ServiceHistory::Builder

    after_commit :force_validity_calculation

    SO = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:so]

    def self.batch_job_ids
      builder_batch_job_scope.pluck(:id)
    end

    def self.batch_process_unprocessed!(max_wait_seconds: DEFAULT_MAX_WAIT_SECONDS)
      queue_batch_process_unprocessed!
      wait_for_processing(max_wait_seconds: max_wait_seconds)
    end

    def self.queue_batch_process_unprocessed!
      queue_enrollments(unprocessed)
    end

    def self.batch_process_date_range!(date_range)
      queue_enrollments(open_during_range(date_range))
    end

    def self.ensure_there_are_no_extra_enrollments_in_service_history(client_ids)
      wait_for_clients(client_ids: client_ids)

      sh_enrollments = service_history_enrollment_source.
        entry.
        where(client_id: client_ids).
        joins(:client).
        distinct.
        pluck(:enrollment_group_id, :project_id, :data_source_id)

      source_enrollments = GrdaWarehouse::Hud::Client.joins(:source_enrollments).
        distinct.
        where(id: client_ids).
        pluck(e_t[:EnrollmentID], e_t[:ProjectID], e_t[:data_source_id])

      extra_enrollments = sh_enrollments - source_enrollments
      extra_enrollments.each do |enrollment_group_id, project_id, data_source_id|
        service_history_enrollment_source.where(
          # client_id: client_id, # We are doing this in batches, so, we have to trust the enrollment/datasource id pair
          enrollment_group_id: enrollment_group_id,
          project_id: project_id,
          data_source_id: data_source_id,
        ).delete_all
      end
    end

    def invalidate_source_data!
      update(processed_as: nil)
    end

    def service_history_valid?
      # Extrapolating SO is implemented in create_service_history!, just force rebuild
      return false if street_outreach_acts_as_bednight? && GrdaWarehouse::Config.get(:so_day_as_month) || project_extrapolates_contacts?

      processed_as.present? && processed_as == calculate_hash && service_history_enrollment.present?
    end

    def source_data_changed?
      ! service_history_valid?
    end

    def should_rebuild?
      source_data_changed?
    end

    def already_processed?
      return false if processed_as.blank?
      return false if history_generated_on.blank?
      return false if self.exit&.ExitDate.blank?
      return false unless entry_exit_tracking?

      self.exit.ExitDate > history_generated_on
    end

    def should_patch?
      # enrollment is still open
      return true if entry_exit_tracking? && self.exit&.ExitDate.blank?

      history_matches = build_for_dates.keys.sort == service_dates_from_service_history_for_enrollment.sort
      return false if history_matches

      if self.exit&.ExitDate.present? || build_for_dates.count < service_dates_from_service_history_for_enrollment.count
        # Something is wrong, force a full rebuild, we probably got here
        # because an enrollment was merged in the ETL process
        create_service_history!(true)
        return false
      end

      true
    end

    # One method to rule them all.  This makes the determination if it
    # should patch or rebuild, or do nothing.  If you need more fine grained control
    # use patch_service_history! or create_service_history! directly
    def rebuild_service_history!
      return false if self.EntryDate < '1970-01-01'.to_date
      return false if destination_client.blank? || project.blank?
      return false if already_processed?

      self.history_generated_on = Date.current
      action = if should_rebuild?
        create_service_history!
      elsif should_patch?
        patch_service_history!
      end

      action
    end

    def patch_service_history!
      days = []
      # load the associated service history enrollment to get the id
      build_for_dates.except(
        *service_dates_from_service_history_for_enrollment,
      ).each do |date, record_type|
        days << service_record(date, record_type)
      end
      return false unless days.any?

      begin
        service_history_service_source.import(
          days.first.keys,
          days.map(&:values),
          validate: false,
          batch_size: 1_000,
          # Because this is a partitioned table, this doesn't work currently
          # on_duplicate_key_update: {
          #   conflict_target: shs_conflict_target,
          #   columns: shs_update_columns,
          # },
        )
      rescue ActiveRecord::RecordNotUnique
        # Don't do anything, we can't on_duplicate_key_update
      end
      update(processed_as: calculate_hash)

      :patch
    end

    private def shs_conflict_target
      [
        :date,
        :service_history_enrollment_id,
      ]
    end

    private def shs_update_columns
      [
        :service_type,
        :age,
        :record_type,
        :client_id,
        :project_type,
        :homeless,
        :literally_homeless,
      ]
    end

    def create_service_history! force = false
      # Rails.logger.debug '===RebuildEnrollmentsJob=== Initiating create_service_history'
      # Rails.logger.debug ::NewRelic::Agent::Samplers::MemorySampler.new.sampler.get_sample
      return false unless force || source_data_changed?

      # Rails.logger.debug '===RebuildEnrollmentsJob=== Checked for changes'
      # Rails.logger.debug ::NewRelic::Agent::Samplers::MemorySampler.new.sampler.get_sample
      days = []
      if project.present?
        date = self.EntryDate
        self.class.transaction do
          remove_existing_service_history_for_enrollment
          entry_day = entry_record(date)
          insert = build_service_history_enrollment_insert(entry_day)
          @entry_record_id = service_history_enrollment_source.connection.insert(insert.to_sql)
          # Rails.logger.debug '===RebuildEnrollmentsJob=== Building days'
          # Rails.logger.debug ::NewRelic::Agent::Samplers::MemorySampler.new.sampler.get_sample
          build_for_dates.each do |d, record_type|
            days << service_record(d, record_type)
          end
          if street_outreach_acts_as_bednight? && GrdaWarehouse::Config.get(:so_day_as_month) || project_extrapolates_contacts?
            record_type = build_for_dates.values.last
            days += add_extrapolated_days(build_for_dates.keys, record_type)
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
          begin
            service_history_service_source.import(
              days.first.keys,
              days.map(&:values),
              validate: false,
              batch_size: 1_000,
              # Because this is a partitioned table, this doesn't work currently
              # on_duplicate_key_update: {
              #   conflict_target: shs_conflict_target,
              #   columns: shs_update_columns,
              # },
            )
          rescue ActiveRecord::InvalidForeignKey
            # sometimes we end up processing an enrollment when it's being rebuilt by a different task
            # ignore the error if the enrollment record has been removed
          end
        end
      end
      update(processed_as: calculate_hash)

      :update
    end

    def entry_record_id
      @entry_record_id ||= service_history_enrollment.id
    end

    def build_service_history_enrollment_insert day
      insert = Arel::Nodes::InsertStatement.new
      insert.relation = she_t
      insert.columns = day.keys.map { |k| she_t[k] }
      insert.values = Arel::Nodes::ValuesList.new([day.values])
      insert
    end

    def entry_record(date)
      default_day.merge(
        date: date,
        age: client_age_at(date),
        record_type: :entry,
      )
    end

    def exit_record(date)
      default_day.merge(
        date: date,
        age: client_age_at(date),
        record_type: :exit,
      )
    end

    def service_record(date, record_type)
      default_service_day.merge(
        date: date,
        age: client_age_at(date),
        service_type: record_type,
        record_type: :service,
        homeless: homeless?(date),
        literally_homeless: literally_homeless?(date),
      )
    end

    def extrapolated_record(date, record_type)
      default_service_day.merge(
        date: date,
        age: client_age_at(date),
        service_type: record_type,
        record_type: :extrapolated,
        homeless: homeless?(date),
        literally_homeless: literally_homeless?(date),
      )
    end

    # build out all days within the month
    # don't build for any dates we already have
    # never build past today, it makes counts and display very odd
    def add_extrapolated_days(dates, record_type)
      extrapolated_dates = dates.map do |date|
        stop_on = [date.end_of_month, Date.current].min
        (date.beginning_of_month .. stop_on).to_a
      end.flatten(1).uniq
      # Don't build extrapolations for any day we already have
      extrapolated_dates -= dates
      extrapolated_dates -= extrapolated_dates_from_service_history_for_enrollment
      extrapolated_dates -= service_dates_from_service_history_for_enrollment

      extrapolated_dates.map do |date|
        extrapolated_record(date, record_type)
      end
    end

    def client_age_at(date)
      destination_client.age_on(date)
    end

    def client_age_at_entry
      @client_age_at_entry ||= destination_client.age_on(self.EntryDate)
    end

    def calculate_hash
      # Use ProjectType to ignore overrides
      @calculate_hash ||= self.class.calculate_hash_for(id, project.ProjectType)
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
      return [] unless destination_client.present? && service_history_enrollment.present?

      @service_dates_from_service_history_for_enrollment ||= service_history_service_source.
        where(
          record_type: :service,
          service_history_enrollment_id: entry_record_id,
        ).where(shs_t[:date].gteq(self.EntryDate)).
        order(date: :asc).
        pluck(:date)
    end

    def extrapolated_dates_from_service_history_for_enrollment
      return [] unless destination_client.present? && service_history_enrollment.present?

      @extrapolated_dates_from_service_history_for_enrollment ||= service_history_service_source.
        extrapolated.where(
          service_history_enrollment_id: entry_record_id,
        ).where(shs_t[:date].gteq(self.EntryDate)).
        order(date: :asc).
        pluck(:date)
    end

    def remove_existing_service_history_for_enrollment
      return unless destination_client.present?

      service_history_enrollment_source.where(
        client_id: destination_client.id,
        enrollment_group_id: self.EnrollmentID,
        data_source_id: data_source_id,
        project_id: self.ProjectID,
        record_type: [:entry, :exit, :first],
      ).delete_all
      reset_instance_variables
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
      @unaccompanied_minor = nil
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

    def self.calculate_hash_for(id, project_type)
      # Rails.logger.debug '===RebuildEnrollmentsJob=== Calculating Hash'
      # Rails.logger.debug ::NewRelic::Agent::Samplers::MemorySampler.new.sampler.get_sample

      # Break this into two queries to speed it up and keep RAM usage in check
      #
      # Ignore service history side, these should always be invalidated if clients are merged
      # rows = source_rows(id) + service_history_rows(id)
      # rows = source_rows(id)
      # Digest::SHA256.hexdigest(rows.to_s)

      rows = source_rows(id, project_type)
      Digest::SHA256.hexdigest rows.join('|')
    end

    def self.source_rows(id, project_type)
      # This must be explicitly ordered since the database doesn't always
      # return data in the same order
      where(id: id).
        includes(:exit, :services, :current_living_situations, :destination_client).
        references(:exit, :services, :current_living_situations, :destination_client).
        order(*enrollment_column_order).
        pluck(Arel.sql(nf('CONCAT', hash_columns(project_type)).to_sql))
    end

    def default_day
      @default_day ||= {
        client_id: destination_client.id,
        date: nil,
        first_date_in_program: self.EntryDate,
        last_date_in_program: exit&.ExitDate,
        enrollment_group_id: self.EnrollmentID,
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
        housing_status_at_entry: self.LivingSituation,
        housing_status_at_exit: exit&.HousingAssessment,
        other_clients_over_25: other_clients_over_25,
        other_clients_under_18: other_clients_under_18,
        other_clients_between_18_and_25: other_clients_between_18_and_25,
        unaccompanied_youth: unaccompanied_youth?,
        parenting_youth: parenting_youth?,
        parenting_juvenile: parenting_juvenile?,
        unaccompanied_minor: unaccompanied_minor?,
        head_of_household: head_of_household?,
        children_only: children_only?,
        individual_adult: individual_adult?,
        individual_elder: individual_elder?,
        presented_as_individual: presented_as_individual?,
        move_in_date: move_in_date,
      }
    end

    def default_service_day
      @default_service_day ||= {
        service_history_enrollment_id: entry_record_id,
        date: nil,
        service_type: nil,
        age: nil,
        record_type: nil,
        client_id: destination_client.id,
        project_type: project.computed_project_type,
        homeless: false,
        literally_homeless: false,
      }
    end

    # Service is considered a homeless service if it is in ES, SO, SH or TH.
    # Service is explicitly NOT homeless if it is in PH after the move-in date.
    # All other service, Services Only, Other, Days Shelter, Coordinated Assessment, and PH pre-move-in date is
    # neither homeless nor not homeless and receives a nil value and will neither show up in homeless,
    # or non_homeless scopes"?
    def homeless?(date)
      return true if GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES.include?(project.computed_project_type)
      return false if GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph].include?(project.computed_project_type) &&
        (self.MoveInDate.present? && date > self.MoveInDate)

      nil
    end

    # The day only counts as literally homeless if it's in ES, SO, SH.
    # TH or PH after move-in date negates literally homeless
    # Others don't negate it, but don't count as such
    def literally_homeless? date
      return true if GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES.include?(project.computed_project_type)
      return false if GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph].include?(project.computed_project_type) &&
        (self.MoveInDate.present? && date > self.MoveInDate)
      return false if GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:th].include?(project.computed_project_type)

      nil
    end

    def household_birthdates
      @household_birthdates ||= begin
        self.class.joins(:destination_client).
          where(
            HouseholdID: self.HouseholdID,
            ProjectID: self.ProjectID,
            data_source_id: data_source_id,
          ).where.not(
            PersonalID: self.PersonalID,
          ).pluck(Arel.sql(c_t[:DOB].as('dob').to_sql))
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

    def minor?(age)
      age.present? && age > 12 && child?(age)
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
        youth?(client_age_at_entry) && other_clients_over_25.zero? && other_clients_under_18.zero?
      end
    end

    # client is a youth and presents with someone under 18, no other adults over 25 present
    def parenting_youth?
      @parenting_youth ||= begin
        youth?(client_age_at_entry) && head_of_household? && other_clients_over_25.zero? && other_clients_under_18.positive?
      end
    end

    # client is under 18 and head of household and has at least one other client under 18 in enrollment
    def parenting_juvenile?
      @parenting_juvenile ||= begin
        child?(client_age_at_entry) && head_of_household? && other_clients_over_25.zero? && other_clients_between_18_and_25.zero? && other_clients_under_18.positive?
      end
    end

    # client is 13 - 17 and there are no adults in the household
    def unaccompanied_minor?
      @unaccompanied_minor ||= begin
        minor?(client_age_at_entry) && other_clients_over_25.zero? && other_clients_between_18_and_25.zero?
      end
    end

    # everyone involved is under 18
    def children_only?
      @children_only ||= begin
        child?(client_age_at_entry) && other_clients_over_25.zero? && other_clients_between_18_and_25.zero?
      end
    end

    # Everyone is over 18
    def individual_adult?
      @individual_adult ||= begin
        adult?(client_age_at_entry) && other_clients_under_18.zero?
      end
    end

    # This is a proxy for if the project served individuals or families
    # True = individuals
    def presented_as_individual?
      @presented_as_individual ||= begin
        if GrdaWarehouse::Config.get(:infer_family_from_household_id)
          @presented_as_individual = ! part_of_a_family?
        else
          @presented_as_individual = project.serves_only_individuals?
        end
      end
    end

    def self.family_households
      Rails.cache.fetch('family-households', expires_in: 2.hours) do
        where.not(HouseholdID: nil).
          group(:HouseholdID, :ProjectID, :data_source_id).
          having('COUNT(DISTINCT("PersonalID")) > 1').count
      end
    end

    def part_of_a_family?
      @families ||= self.class.family_households
      @families.key? [self.HouseholdID, self.ProjectID, data_source_id]
    end

    # Client is over 65 and everyone else is an adult
    def individual_elder?
      @individual_elder ||= begin
        elder?(client_age_at_entry) && other_clients_under_18.zero?
      end
    end

    def service_type_from_project_type(project_type)
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
      housing_related = [1, 2, 3, 4, 8, 9, 10, 13]
      return 200 if housing_related.include?(project_type)

      nil
    end

    def head_of_household_id
      @head_of_household_id ||= if head_of_household?
        self.PersonalID
      else
        self.class.where(
          data_source_id: data_source_id,
          HouseholdID: self.HouseholdID,
          ProjectID: self.ProjectID,
          RelationshipToHoH: 1,
        ).
          where.not(HouseholdID: nil).
          order(Arel.sql(e_t[:RelationshipToHoH].asc.to_sql + ' NULLS LAST')).
          pluck(:PersonalID)&.first || self.PersonalID
      end
    end

    def move_in_date
      @move_in_date ||= if head_of_household? || self.MoveInDate.present?
        self.MoveInDate
      else
        hoh_move_in_date = self.class.where(
          data_source_id: data_source_id,
          HouseholdID: self.HouseholdID,
          ProjectID: self.ProjectID,
          RelationshipToHoH: 1,
        ).
          where.not(HouseholdID: nil).
          order(Arel.sql(e_t[:RelationshipToHoH].asc.to_sql + ' NULLS LAST')).
          pluck(:MoveInDate)&.first
        if hoh_move_in_date.present?
          [
            hoh_move_in_date,
            self.EntryDate,
          ].max
        end
        # No HoH move-in-date, don't add a move-in-date
      end
    end

    def head_of_household
      GrdaWarehouse::Hud::Client.where(PersonalID: head_of_household_id)
    end

    def head_of_household?
      @head_of_household ||= (self.RelationshipToHoH.blank? || self.RelationshipToHoH == 1) # 1 = Self
    end

    def entry_exit_tracking?
      # This project isn't listed as a bed-night project AND isn't an SO project that behaves as a bed-night project
      @entry_exit_tracking ||= project.TrackingMethod != 3 && ! street_outreach_acts_as_bednight?
    end

    def street_outreach_acts_as_bednight?
      @street_outreach_acts_as_bednight ||= project.so? && project.enrollments.joins(:current_living_situations).exists?
    end

    def project_extrapolates_contacts?
      project.extrapolate_contacts
    end

    def build_for_dates
      @build_for_dates ||= if entry_exit_tracking?
        (self.EntryDate..build_until).map do |date|
          [date, service_type_from_project_type(project.computed_project_type)]
        end.to_h
      else
        # Fetch all services provided between the start of the enrollment and the end of the build period
        service_records = services.where(DateProvided: (self.EntryDate..build_until), RecordType: 200).
          order(DateProvided: :asc).
          pluck(:DateProvided, :RecordType).to_h
        if project.so?
          # Find all contacts for SO.  Pretend like they are bed-nights
          living_situations = current_living_situations.where(InformationDate: (self.EntryDate..build_until)).
            order(InformationDate: :asc).
            pluck(:InformationDate).map { |d| [d, 200] }.to_h
          service_records.merge!(living_situations)
        end
        service_records
      end
    end

    # Build until the exit if we have one, or the lesser of the various coverage options
    def build_until
      @build_until ||= if exit&.ExitDate.present?
        # no bed night should be given on the exit date per System Performance Measures programming spec: The [project exit date] itself is not included because it does not represent a night spent in the project.
        # We will count the stay as one day if the entry and exit are on the same day
        exit_date = if entry_exit_tracking? && self.EntryDate != exit.ExitDate
          exit.ExitDate - 1.day
        else
          exit.ExitDate # Trust the data for night-by-night
        end
        # NOTE: this is limited to the end of next year, sometimes we get exit dates that are *very* far in the future.  This will preserve the ability to set future end dates and prevent extra rebuilds, but will continue extending the days into the future.
        [
          exit_date,
          (Date.current + 1.year).end_of_year,
        ].min
      else
        [
          export.effective_export_end_date,
          export.ExportEndDate,
          Date.current,
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
    def self.hash_columns(project_type)
      @hash_columns = begin
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
        # Only include living situations in SO, to avoid rebuilding everything
        if SO.include?(project_type)
          columns += living_situation_hash_columns.values.map do |col|
            [cls_t[col], '_']
          end
        end
        columns.flatten
      end
    end

    def self.enrollment_column_order
      columns = enrollment_hash_columns.values.map do |col|
        Arel.sql(e_t[col].asc.to_sql + ' NULLS FIRST')
      end
      columns += exit_hash_columns.values.map do |col|
        Arel.sql(ex_t[col].asc.to_sql + ' NULLS FIRST')
      end
      columns += service_hash_columns.values.map do |col|
        Arel.sql(s_t[col].asc.to_sql + ' NULLS FIRST')
      end
      columns += client_hash_columns.values.map do |col|
        Arel.sql(c_t[col].asc.to_sql + ' NULLS FIRST')
      end
      columns += living_situation_hash_columns.values.map do |col|
        Arel.sql(cls_t[col].asc.to_sql + ' NULLS FIRST')
      end
      columns
    end

    def self.living_situation_hash_columns
      {
        information_date: :InformationDate,
        deleted_at: :DateDeleted,
        data_source_id: :data_source_id,
        updated_at: :DateUpdated,
      }.freeze
    end

    def self.client_hash_columns
      {
        destination_client_id: :id,
      }.freeze
    end

    def self.enrollment_hash_columns
      {
        id: :id,
        data_source_id: :data_source_id,
        entry_date: :EntryDate,
        project_id: :ProjectID,
        deleted_at: :DateDeleted,
        household_id: :HouseholdID,
        head_of_household: :RelationshipToHoH,
        move_in_date: :MoveInDate,
        updated_at: :DateUpdated,
      }.freeze
    end

    def self.exit_hash_columns
      {
        exit_date: :ExitDate,
        deleted_at: :DateDeleted,
        data_source_id: :data_source_id,
        destination: :Destination,
        updated_at: :DateUpdated,
      }.freeze
    end

    def self.service_hash_columns
      {
        date_provided: :DateProvided,
        deleted_at: :DateDeleted,
        data_source_id: :data_source_id,
        updated_at: :DateUpdated,
      }.freeze
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

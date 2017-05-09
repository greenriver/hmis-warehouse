module GrdaWarehouse::Hud
  class Client < Base
    include RandomScope
    include ArelHelper   # also included by RandomScope, but this makes dependencies clear

    self.table_name = 'Client'
    self.hud_key = 'PersonalID'
    acts_as_paranoid(column: :DateDeleted)

    def self.hud_csv_headers(version: nil)
      [
        "PersonalID",
        "FirstName",
        "MiddleName",
        "LastName",
        "NameSuffix",
        "NameDataQuality",
        "SSN",
        "SSNDataQuality",
        "DOB",
        "DOBDataQuality",
        "AmIndAKNative",
        "Asian",
        "BlackAfAmerican",
        "NativeHIOtherPacific",
        "White",
        "RaceNone",
        "Ethnicity",
        "Gender",
        "VeteranStatus",
        "YearEnteredService",
        "YearSeparated",
        "WorldWarII",
        "KoreanWar",
        "VietnamWar",
        "DesertStorm",
        "AfghanistanOEF",
        "IraqOIF",
        "IraqOND",
        "OtherTheater",
        "MilitaryBranch",
        "DischargeStatus",
        "DateCreated",
        "DateUpdated",
        "UserID",
        "DateDeleted",
        "ExportID"
      ].freeze
    end

    has_paper_trail    
    include ArelHelper

    belongs_to :data_source, inverse_of: :clients
    belongs_to :export, **hud_belongs(Export), inverse_of: :clients

    has_one :warehouse_client_source, class_name: GrdaWarehouse::WarehouseClient.name, foreign_key: :source_id, inverse_of: :source
    has_many :warehouse_client_destination, class_name: GrdaWarehouse::WarehouseClient.name, foreign_key: :destination_id, inverse_of: :destination
    has_one :destination_client, through: :warehouse_client_source, source: :destination, inverse_of: :source_clients
    has_many :source_clients, through: :warehouse_client_destination, source: :source, inverse_of: :destination_client

    has_one :processed_service_history, -> { where(routine: 'service_history')}, class_name: 'GrdaWarehouse::WarehouseClientsProcessed'
    has_one :first_service_history, -> { where record_type: 'first' }, class_name: 'GrdaWarehouse::ServiceHistory'

    has_one :api_id, class_name: GrdaWarehouse::ApiClientDataSourceId.name
    has_one :hmis_client, class_name: GrdaWarehouse::HmisClient.name

    has_many :service_history, class_name: 'GrdaWarehouse::ServiceHistory', inverse_of: :client
    has_many :service_history_entry, -> { entry }, class_name: 'GrdaWarehouse::ServiceHistory'
    has_many :service_history_entry_in_last_three_years, -> {
      entry_in_last_three_years
    }, class_name: 'GrdaWarehouse::ServiceHistory'

    has_many :exits, class_name: 'GrdaWarehouse::Hud::Exit', foreign_key: ['PersonalID', 'data_source_id'], primary_key: ['PersonalID', 'data_source_id']
    has_many :enrollments, class_name: 'GrdaWarehouse::Hud::Enrollment', foreign_key: ['PersonalID', 'data_source_id'], primary_key: ['PersonalID', 'data_source_id'], inverse_of: :client
    has_many :enrollment_cocs, **hud_many(EnrollmentCoc), inverse_of: :client
    has_many :services, class_name: 'GrdaWarehouse::Hud::Service', foreign_key: ['PersonalID', 'data_source_id'], primary_key: ['PersonalID', 'data_source_id'], inverse_of: :client
    has_many :disabilities, class_name: 'GrdaWarehouse::Hud::Disability', foreign_key: ['PersonalID', 'data_source_id'], primary_key: ['PersonalID', 'data_source_id'], inverse_of: :client
    has_many :health_and_dvs, class_name: 'GrdaWarehouse::Hud::HealthAndDv', foreign_key: ['PersonalID', 'data_source_id'], primary_key: ['PersonalID', 'data_source_id'], inverse_of: :client
    has_many :income_benefits, class_name: 'GrdaWarehouse::Hud::IncomeBenefit', foreign_key: ['PersonalID', 'data_source_id'], primary_key: ['PersonalID', 'data_source_id'], inverse_of: :client
    has_many :client_attributes_defined_text, class_name: GrdaWarehouse::HMIS::ClientAttributeDefinedText.name, inverse_of: :client
    has_many :employment_educations, **hud_many(EmploymentEducation), inverse_of: :client
    has_many :hmis_forms, class_name: GrdaWarehouse::HmisForm.name

    has_many :source_services, through: :source_clients, source: :services
    has_many :source_enrollments, through: :source_clients, source: :enrollments
    has_many :source_enrollment_cocs, through: :source_clients, source: :enrollment_cocs
    has_many :source_disabilities, through: :source_clients, source: :disabilities
    has_many :source_enrollment_disabilities, through: :source_enrollments, source: :disabilities
    has_many :source_exits, through: :source_enrollments, source: :exit
    has_many :source_health_and_dvs, through: :source_clients, source: :health_and_dvs
    has_many :source_enrollment_health_and_dvs, through: :source_enrollments, source: :health_and_dvs
    has_many :source_income_benefits, through: :source_clients, source: :income_benefits
    has_many :source_enrollment_income_benefits, through: :source_enrollments, source: :income_benefits
    has_many :source_enrollment_services, through: :source_enrollments, source: :services
    has_many :source_client_attributes_defined_text, through: :source_clients, source: :client_attributes_defined_text
    has_many :entry_assessments, class_name: GrdaWarehouse::HMIS::EntryAssessment.name
    has_many :exit_assessments, class_name: GrdaWarehouse::HMIS::ExitAssessment.name
    has_many :staff_x_clients, class_name: GrdaWarehouse::HMIS::StaffXClient.name, inverse_of: :client
    has_many :staff, class_name: GrdaWarehouse::HMIS::Staff.name, through: :staff_x_clients
    has_many :source_api_ids, through: :source_clients, source: :api_id
    has_many :source_hmis_clients, through: :source_clients, source: :hmis_client
    has_many :source_hmis_forms, through: :source_clients, source: :hmis_forms

    has_many :chronics, class_name: GrdaWarehouse::Chronic.name, inverse_of: :client

    scope :destination, -> do
      where(data_source: GrdaWarehouse::DataSource.destination)
    end
    scope :source, -> do
      where(data_source: GrdaWarehouse::DataSource.importable)
    end
    scope :unmatched, -> do
      source.where.not(id: GrdaWarehouse::WarehouseClient.select(:source_id))
    end
    scope :veteran, -> do
      where VeteranStatus: 1 
    end
    scope :currently_homeless, -> do
      # this is somewhat involved in order to make it composable and somewhat efficient
      # more efficient is a join + distinct, but the distinct makes it less composable
      # clearer and composable but less efficient would be to use an exists subquery
      sh  = GrdaWarehouse::ServiceHistory
      at  = arel_table
      sht = sh.arel_table
      inner_table = sht.
        project(sht[:client_id]).
        group(sht[:client_id]).
        where( sht[:record_type].eq 'entry' ).
        where( sht[:project_type].in GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES ).
        where( sht[:last_date_in_program].eq nil ).
        as('sht')
      joins "INNER JOIN #{inner_table.to_sql} ON #{at[:id].eq(inner_table[:client_id]).to_sql}"
    end
    scope :disabled, -> do
      at = arel_table
      dt = Disability.arel_table
      where Disability.where( dt[:data_source_id].eq at[:data_source_id] ).where( dt[:PersonalID].eq at[:PersonalID] ).exists
    end
    # clients whose first residential service record is within the given date range
    scope :entered_in_range, -> (range) do
      s, e, exclude = range.first, range.last, range.exclude_end?   # the exclusion bit's a little pedantic...
      sh  = GrdaWarehouse::ServiceHistory
      sht = sh.arel_table
      joins(:first_service_history).
        where( sht[:date].gteq s ).
        where( exclude ? sht[:date].lt(e) : sht[:date].lteq(e) )
    end
    scope :in_data_source, -> (data_source_id) do
      where(data_source_id: data_source_id)
    end
    scope :cas_active, -> do
      where(sync_with_cas: true)
    end
    scope :full_housing_release_on_file, -> do
      where(housing_release_status: 'Full HAN Release')
    end
    scope :limited_cas_release_on_file, -> do
      where(housing_release_status: 'Limited CAS Release')
    end
    scope :verified_disability, -> do
      where.not(disability_verified_on: nil)
    end

    scope :dmh_eligible, -> do
      where.not(dmh_eligible: false)
    end
    scope :va_eligible, -> do
      where.not(va_eligible: false)
    end
    scope :hues_eligible, -> do
      where.not(hues_eligible: false)
    end
    scope :hiv_positive, -> do
      where.not(hiv_positive: false)
    end

    attr_accessor :merge
    attr_accessor :unmerge

    alias_attribute :last_name, :LastName
    alias_attribute :first_name, :FirstName

    # Define a bunch of disability methods we can use to get the response needed 
    # for CAS integration
    # This generates methods like: substance_response()
    GrdaWarehouse::Hud::Disability.disability_types.each do |hud_key, disability_type|
      define_method "#{disability_type}_response".to_sym do
        disability_check = "#{disability_type}?".to_sym
        source_disabilities.detect(&disability_check).try(:response)
      end
    end

    GrdaWarehouse::Hud::Disability.disability_types.each do |hud_key, disability_type|
      define_method "#{disability_type}_response?".to_sym do
        self.send("#{disability_type}_response".to_sym) == 'Yes'
      end
    end

    # cas needs a simplified version of this
    def cas_substance_response
      response = source_disabilities.detect(&:substance?).try(:response)
      nos = [
        'No',
        'Client doesn’t know',
        'Client refused',
        'Data not collected',
      ]
      return nil unless response.present?
      return 'Yes' unless nos.include?(response)
      response
    end

    def cas_substance_response?
      cas_substance_response == 'Yes'
    end

    def disabling_condition?
      [
        cas_substance_response,
        physical_response,
        developmental_response,
        chronic_response,
        hiv_response,
        mental_response,
      ].include?('Yes')
    end

    def domestic_violence?
      source_health_and_dvs.where(DomesticViolenceVictim: 1).exists?
    end

    def chronic?(on: nil)
      on ||= GrdaWarehouse::Chronic.most_recent_day
      chronics.where(date: on).present?
    end

    def ever_chronic?
      chronics.any?
    end
    # family members, if any, as found by matching household_id in service history entries
    # individuals returned are sorted oldest to youngest
    # NOTE: This is incorrect, it needs to take data_source_id into account
    # def family_members
    #   @family_members ||= begin
    #     hids = service_history_entry.pluck(:household_id).map(&:presence).uniq.compact
    #     if hids.any?
    #       ht = GrdaWarehouse::ServiceHistory.arel_table
    #       GrdaWarehouse::Hud::Client.joins(:service_history_entry).
    #         merge(GrdaWarehouse::ServiceHistory.entry).
    #         where( ht[:household_id].in hids ).
    #         where.not( id: id )
    #         .uniq.sort_by(&:age).reverse
    #       else
    #         []
    #       end
    #   end
    # end

    def households
      @households ||= begin
        hids = service_history_entry.where.not(household_id: [nil, '']).pluck(:household_id, :data_source_id).uniq
        if hids.any?
          service_table = GrdaWarehouse::ServiceHistory.arel_table
          client_table = GrdaWarehouse::Hud::Client.arel_table
          columns = {
            household_id: service_table[:household_id].as('household_id').to_sql, 
            date: service_table[:date].as('date').to_sql, 
            client_id: service_table[:client_id].as('client_id').to_sql, 
            age: service_table[:age].as('age').to_sql, 
            enrollment_group_id: service_table[:enrollment_group_id].as('enrollment_group_id').to_sql, 
            FirstName: client_table[:FirstName].as('FirstName').to_sql, 
            LastName: client_table[:LastName].as('LastName').to_sql, 
            last_date_in_program: service_table[:last_date_in_program].as('last_date_in_program').to_sql,
          }
          hh_where = hids.map{|hh_id, ds_id| "(household_id = '#{hh_id}' and #{GrdaWarehouse::ServiceHistory.quoted_table_name}.data_source_id = #{ds_id})"}.join(' or ')
          entries = GrdaWarehouse::ServiceHistory.entry
            .joins(:client)
            .where(hh_where)
            .where.not(client_id: id )
            .pluck(*columns.values).map do |row|
              Hash[columns.keys.zip(row)]
            end.uniq
          entries = entries.group_by{|m| [m['household_id'], m['date']]}
        end
      end
    end

    def household household_id, date
      households[[household_id, date]] if households.present?
    end

    # after and before take dates, or something like 3.years.ago
    def presented_with_family?(after: nil, before: nil)
      return false unless households.present?
      raise 'After required if before specified.' if before.present? && ! after.present?
      hh = if before.present? && after.present?
        recent_households = households.select do |_, entries|
          # all entries will have the same date and last_date_in_program
          entry = entries.first
          (entry_date, exit_date) = entry.values_at('date', 'last_date_in_program') 
          # If we entered the program between the two dates
          # or we entered the program before the later date and haven't exited
          started_within_no_exit = entry_date < before && exit_date.blank?
          # or we entered before the first date and exited after the first date
          entry_date.between?(before, after) || started_within_no_exit || after < exit_date && entry_date < before rescue true
        end
      elsif after.present? 
        recent_households = households.select do |_, entries|
          # all entries will have the same date and last_date_in_program
          entry = entries.first
          (entry_date, exit_date) = entry.values_at('date', 'last_date_in_program') 
          # If we entered the program after the date in question
          # or we exited the program after the date in question
          # or we haven't exited the program
          entry_date > after || exit_date.blank? || exit_date > after
        end
      else
        households
      end
      child = false
      adult = false
      hh.each do |k, h|
        _, date = k
        # client life stage
        child = self.DOB.present? && age_on(date) < 18
        adult = self.DOB.blank? || age_on(date) >= 18
        h.map{|m| m['age']}.uniq.each do |a|
          adult = true if a.present? && a >= 18
          child = true if a.blank? || a < 18
        end
        return true if child && adult
      end
      child && adult
    end

    def name
      "#{self.FirstName} #{self.LastName}"
    end

    def names
      source_clients.map{ |n| "#{n.data_source.short_name} #{n.full_name}" }
    end

    def hmis_client_response
      @hmis_client_response ||= JSON.parse(hmis_client.response) if hmis_client.present?
    end

    def email
      return unless hmis_client_response.present?
      hmis_client_response['Email']
    end

    def home_phone
      return unless hmis_client_response.present?
      hmis_client_response['HomePhone']
    end

    def cell_phone
      return unless hmis_client_response.present?
      hmis_client_response['CellPhone']
    end

    def work_phone
      return unless hmis_client_response.present?
      work_phone = hmis_client_response['WorkPhone']
      work_phone += " x #{hmis_client_response['WorkPhoneExtension']}" if hmis_client_response['WorkPhoneExtension'].present?
      work_phone
    end

    def self.no_image_on_file_image
      return File.read(Rails.root.join("public", "no_photo_on_file.jpg"))
    end

    # finds an image for the client. there may be more then one availabe but this
    # method will select one more or less at random. returns no_image_on_file_image
    # if none is found. returns that actual image bytes
    # FIXME: invalidate the cached image if any aspect of the client changes
    def image(cache_for=10.minutes)
      ActiveSupport::Cache::FileStore.new(Rails.root.join('tmp/client_images')).fetch(self.cache_key, expires_in: cache_for) do
        logger.debug "Client#image id:#{self.id} cache_for:#{cache_for} fetching via api"
        image_data = nil
        source_api_ids.detect do |api_id|
          api ||= EtoApi::Base.new.tap{|api| api.connect}
          image_data = api.client_image(client_id: api_id.id_in_data_source, site_id: api_id.site_id_in_data_source) rescue nil
          (image_data && image_data.length > 0)
        end
        image_data || self.class.no_image_on_file_image
      end
    end

    # If we have source_api_ids, but are lacking hmis_clients
    # or our hmis_clients are out of date
    def requires_api_update?
      api_ids = source_api_ids.count
      return false if api_ids == 0
      return true if api_ids > source_hmis_clients.count
      last_updated = source_hmis_clients.pluck(:updated_at).max
      if last_updated.present?
        return last_updated < 1.week.ago
      end
      true
    end

    def update_via_api
      client_ids = source_api_ids.pluck(:client_id)
      if client_ids.any?
        EtoApi::Tasks::UpdateClientDemographics.new(client_ids: client_ids, run_time: 15.minutes, one_off: true).run!
      end
    end

    # A useful array of hashes from API data
    def caseworkers
      @caseworkers ||= [].tap do |m|
        source_hmis_clients.each do |c|
          staff_types.each do |staff_type|
            staff_name = c["#{staff_type}_name"]
            staff_attributes = c["#{staff_type}_attributes"]

            if staff_name.present?
              m << {
                title: staff_type.to_s.titleize,
                name: staff_name,
                phone: staff_attributes.try(:[], 'GeneralPhoneNumber'),
              }
            end
          end
        end
      end
    end

    def staff_types
      [:case_manager, :assigned_staff, :counselor, :outreach_counselor]
    end

    def self.sort_options
      [
        {title: 'Last name A-Z', column: 'LastName', direction: 'asc'},
        {title: 'Last name Z-A', column: 'LastName', direction: 'desc'},
        {title: 'First name A-Z', column: 'FirstName', direction: 'asc'},
        {title: 'First name Z-A', column: 'FirstName', direction: 'desc'},
        {title: 'Youngest to Oldest', column: 'DOB', direction: 'desc'},
        {title: 'Oldest to Youngest', column: 'DOB', direction: 'asc'},
        {title: 'Most served', column: 'days_served', direction: 'desc'},
        {title: 'Recently added', column: 'first_date_served', direction: 'desc'},
        {title: 'Longest standing', column: 'first_date_served', direction: 'asc'},
        {title: 'Most recently served', column: 'last_date_served', direction: 'desc'},
      ]
    end

    def self.cas_columns
      {
        disability_verified_on: 'Disability Verification on File', 
        housing_release_status: 'Housing Release Status',
        full_housing_release: 'Full HAN Release on File',
        limited_cas_release: 'Limited CAS Release on File',
        sync_with_cas: 'Available in CAS',
        dmh_eligible: 'DMH Eligible',
        va_eligible: 'VA Eligible',
        hues_eligible: 'HUES Eligible',
        hiv_positive: 'HIV+'
      }
    end

    def self.housing_release_options
      [
       'Full HAN Release',
       'Limited CAS Release',
      ]
    end

    def invalidate_service_history
      if processed_service_history.present?
        processed_service_history.destroy
      end
    end

    def destination?
      source_clients.size > 0
    end

    def source?
      destination_client.present?
    end

    # Determine the date of the most-recent change to: Enrollment, Exit, Service
    def last_service_updated_at
      if source_clients.any?
        source_clients.map(&:last_service_updated_at).max
      else
        [exits.maximum('DateUpdated'), enrollments.maximum('DateUpdated'), services.maximum('DateUpdated')].compact.max
      end
    end

    def full_name
      [self.FirstName,self.MiddleName,self.LastName].select(&:present?).join(' ')
    end

    def consent_form_status
      @consent_form_status ||= source_hmis_clients.joins(:client).
        where.not(consent_form_status: nil).
        merge(Client.order(DateUpdated: :desc)).
        first.try(&:consent_form_status)
    end
    # Find the most-recently updated source_hmis_client with a non-null consent_form
    def signed_consent_form_fully?
      consent_form_status == 'Signed fully'
    end

    def service_date_range
      @service_date_range ||= begin
        at = service_history.arel_table
        query = service_history.service.select( at[:date].minimum, at[:date].maximum )
        service_history.connection.select_rows(query.to_sql).first.map{ |m| m.try(:to_date) }
      end
    end

    def date_of_first_service
      # service_date_range.first
      processed_service_history.try(:first_date_served)
    end

    def date_of_last_service
      # service_date_range.last
      processed_service_history.try(:last_date_served)
    end

    def date_of_last_homeless_service
      # TODO: This will need to be re-written when the Warehouse moves to postgres
      service_history.homeless.
        from("#{GrdaWarehouse::ServiceHistory.quoted_table_name} with(index(index_warehouse_client_service_history_on_client_id))").
        maximum(:date)
    end

    def last_projects_served_by
      # FIXME: this is a hack because processed_service_history's date sometimes doesn't match any service history record
      # astoundingly, this is faster than a more sensible database query that doesn't return everything
      service_history.pluck(:date, :project_name).group_by(&:first).max_by(&:first).last.map(&:last).uniq.sort
      # service_history.where( date: processed_service_history.select(:last_date_served) ).order(:project_name).distinct.pluck(:project_name)
    end

    def weeks_of_service
      total_days_of_service / 7
    end

    def days_of_service
      # self.class.where(id: self.id).service_days_by_client_id.values.first
      processed_service_history.try(:days_served)
    end

    def months_served
      return [] unless date_of_first_service.present?
      [].tap do |i|
        (date_of_first_service.year..date_of_last_service.year).each do |y|
          start_month = if date_of_first_service.year == y then date_of_first_service.month else 1 end
          end_month = if date_of_last_service.year == y then date_of_last_service.month else 12 end
          (start_month..end_month).each do |m|
            i << {start: "#{y}-#{m}-01"}
          end
        end
      end
    end

    def self.service_days_by_client_id
      services = GrdaWarehouse::ServiceHistory
      at = services.arel_table
      query = services.service.
        joins(:client).
        select(:client_id).
        select(nf( 'COUNT', [ nf( 'DISTINCT', [at[:date]] ) ] )).
        group(:client_id)
      services.connection.select_rows(query.to_sql).to_h
    end

    def self.without_service_history
      sh  = GrdaWarehouse::WarehouseClientsProcessed
      sht = sh.arel_table
      where(
        sh.where( sht[:client_id].eq arel_table[:id] ).exists.not
      )
    end

    def total_days_of_service
      ((date_of_last_service - date_of_first_service).to_i + 1)
    end

    def service_dates_for_display start_date
      @service_dates_for_display ||= begin
        st = service_history.arel_table
        query = service_history.
          select( :date, :record_type, :project_id, :project_type, :enrollment_group_id, :first_date_in_program, :last_date_in_program, :data_source_id ).
          where( st[:date].gt start_date.beginning_of_week ).
          where( st[:date].lteq start_date.end_of_month.end_of_week ).
          order( date: :asc ).
          distinct
        ungrouped_services = query.each_with_index.map do |m,i|
          day = {
            id: i,
            service_type: m.service_type_brief,
            program_id: m.project_id,
            class: "service-type__#{m.record_type} program-group_#{m.enrollment_group_id} client__service_type_#{m.project_type}",
            record_type: m.record_type,
            database_id: m.data_source_id,
          }
          if m.enrollment_group_id.present?
            day[:group] = "#{m.enrollment_group_id}"
          end
          if m.record_type == 'service'
            day[:start] = m.date.to_date
          elsif m.record_type == 'exit'
            day[:start] = if m.last_date_in_program.present?
              then
              m.last_date_in_program.to_date
            else
              date_of_last_service
            end
          else
            day[:start] = m.first_date_in_program.to_date
            day[:end] = if m.last_date_in_program.present?
              then
              m.last_date_in_program.to_date
            else
              date_of_last_service
            end
          end
          day
        end
        ungrouped_services.group_by{ |m| m[:start] }
      end
    end

    def self.text_search(text)
      return none unless text.present?
      text.strip!
      sa = source.arel_table
      alpha_numeric = /[[[:alnum:]]-]+/.match(text).try(:[], 0) == text
      numeric = /[\d-]+/.match(text).try(:[], 0) == text
      date = /\d\d\/\d\d\/\d\d\d\d/.match(text).try(:[], 0) == text
      social = /\d\d\d-\d\d-\d\d\d\d/.match(text).try(:[], 0) == text
      # Explicitly search for only last, first if there's a comma in the search
      if text.include?(',')
        last, first = text.split(',').map(&:strip)
        where = sa[:FirstName].lower.matches("#{first.downcase}%")
          .and(sa[:LastName].lower.matches("#{last.downcase}%"))
      # Explicity search for "first last"
      elsif text.include?(' ')
        first, last = text.split(' ').map(&:strip)
        where = sa[:FirstName].lower.matches("#{first.downcase}%")
          .and(sa[:LastName].lower.matches("#{last.downcase}%"))
      # Explicitly search for a PersonalID
      elsif alpha_numeric && (text.size == 32 || text.size == 36)
        where = sa[:PersonalID].matches(text.gsub('-', ''))
      elsif social
        where = sa[:SSN].eq(text.gsub('-',''))
      elsif date
        where = sa[:DOB].eq(text)
      elsif numeric
        where = sa[:PersonalID].eq(text).or(sa[:id].eq(text))
      else
        query = "%#{text}%"
        alt_names = UniqueName.where(double_metaphone: Text::Metaphone.double_metaphone(text).to_s).map(&:name)
        nicks = Nickname.for(text).map(&:name)
        where = sa['FirstName'].matches(query)
          .or(sa['LastName'].matches(query))
        if nicks.any?
          nicks_for_search = nicks.map{|m| GrdaWarehouse::Hud::Client.connection.quote(m)}.join(",")
          where = where.or(nf('LOWER', [arel_table[:FirstName]]).in(nicks_for_search))
        end
        if alt_names.present?
          alt_names_for_search = alt_names.map{|m| GrdaWarehouse::Hud::Client.connection.quote(m)}.join(",")
          where = where.or(nf('LOWER', [arel_table[:FirstName]]).in(alt_names_for_search)).
            or(nf('LOWER', [arel_table[:LastName]]).in(alt_names_for_search))
        end
      end

      client_ids = GrdaWarehouse::Hud::Client
        .joins(:warehouse_client_source).source
        .where(where)
        .preload(:destination_client)
        .map{|m| m.destination_client.id}
      where(id: client_ids)
    end

    def self.age date:, dob:
      age = date.year - dob.year
      age -= 1 if dob > date.years_ago(age)
      return age
    end

    def age date=Date.today
      return unless attributes['DOB'].present?
      date = date.to_date
      dob = attributes['DOB'].to_date
      self.class.age(date: date, dob: dob)
    end
    alias_method :age_on, :age

    def uuid
      @uuid ||= if data_source.munged_personal_id
        self.PersonalID.split(/(\w{8})(\w{4})(\w{4})(\w{4})(\w{12})/).reject{ |c| c.empty? || c == '__#' }.join('-')
      else
        self.PersonalID
      end
    end

    def self.uuid personal_id
      personal_id.split(/(\w{8})(\w{4})(\w{4})(\w{4})(\w{12})/).reject{ |c| c.empty? || c == '__#' }.join('-')
    end

    def veteran?
      self.VeteranStatus == 1
    end

    # those columns that relate to race
    def self.race_fields
      %w( AmIndAKNative Asian BlackAfAmerican NativeHIOtherPacific White RaceNone )
    end

    # those race fields which are marked as pertinent to the client
    def race_fields
      self.class.race_fields.select{ |f| send(f).to_i == 1 }
    end

    def race_description
      race_fields.map{ |f| ::HUD::race f }.join ', '
    end

    def cas_primary_race_code
      race_text = ::HUD::race(race_fields.first)
      Cas::PrimaryRace.find_by_text(race_text).try(:numeric)
    end

    def self_and_sources
      if destination?
        [ self, *self.source_clients ]
      else
        [self]
      end
    end

    def primary_caseworkers
      staff.merge(GrdaWarehouse::HMIS::StaffXClient.primary_caseworker)
    end

    # convert all clients to the appropriate destination client
    def normalize_to_destination
      if destination?
        self
      else
        self.destination_client
      end
    end

    def previous_permanent_locations
      source_enrollments.any_address.sort_by(&:EntryDate).map(&:address_lat_lon).uniq
    end

    # Build a set of potential client matches grouped by criteria
    # FIXME: consolidate this logic with merge_candidates below
    def potential_matches
      @potential_matches ||= begin
        {}.tap do |m|
          c_arel = self.class.arel_table
          # Find anyone with a nickname match
          nicks = Nickname.for(self.FirstName).map(&:name)

          if nicks.any?
            nicks_for_search = nicks.map{|m| GrdaWarehouse::Hud::Client.connection.quote(m)}.join(",")
            similar_destinations = self.class.destination.where(
              nv('LOWER', [Client.FirstName]).in(nicks_for_search)
            ).where(c_arel['LastName'].matches("%#{self.LastName}%")).
            where.not(id: self.id)
            m[:by_nickname] = similar_destinations if similar_destinations.any?
          end
          # Find anyone with similar sounding names
          alt_first_names = UniqueName.where(double_metaphone: Text::Metaphone.double_metaphone(self.FirstName).to_s).map(&:name)
          alt_last_names = UniqueName.where(double_metaphone: Text::Metaphone.double_metaphone(self.LastName).to_s).map(&:name)
          alt_names = alt_first_names + alt_last_names
          if alt_names.any?
            alt_names_for_search = alt_names.map{|m| GrdaWarehouse::Hud::Client.connection.quote(m)}.join(",")
            similar_destinations = self.class.destination.where(
              nf('LOWER', [c_arel[:FirstName]]).in(alt_names_for_search).
                and(nf('LOWER', [c_arel[:LastName]]).matches('#{self.LastName}%')).
              or(nf('LOWER', [c_arel[:LastName]]).in(alt_names_for_search).
                and(nf('LOWER', [c_arel[:FirstName]]).matches('#{self.FirstName}%'))
              )
            ).where.not(id: self.id)
            m[:where_the_name_sounds_similar] = similar_destinations if similar_destinations.any?
          end
          # Find anyone with similar sounding names
          # similar_destinations = self.class.where(id: GrdaWarehouse::WarehouseClient.where(source_id:  self.class.source.where("difference(?, FirstName) > 1", self.FirstName).where('LastName': self.class.source.where('soundex(LastName) = soundex(?)', self.LastName).select('LastName')).where.not(id: source_clients.pluck(:id)).pluck(:id)).pluck(:destination_id))
          # m[:where_the_name_sounds_similar] = similar_destinations if similar_destinations.any?
        end
      end

      # TODO
      # Soundex on names
      # William/Bill/Will

      # Others
    end

    # find other clients with similar names
    def merge_candidates(scope=self.class.source)

      # skip self and anyone already known to be related
      scope = scope.where.not( id: source_clients.map(&:id) + [ id, destination_client.try(&:id) ] )

      # some convenience stuff to clean the code up
      at = self.class.arel_table

      diff_full = nf(
        'DIFFERENCE', [
          ct( cl( at[:FirstName], '' ), cl( at[:MiddleName], '' ), cl( at[:LastName], '' ) ),
          name
        ],
        'diff_full'
      )
      diff_last  = nf( 'DIFFERENCE', [ cl( at[:LastName], '' ), last_name || '' ], 'diff_last' )
      diff_first = nf( 'DIFFERENCE', [ cl( at[:LastName], '' ), first_name || '' ], 'diff_first' )

      # return a scope return clients plus their "difference" from this client
      scope.select( Arel.star, diff_full, diff_first, diff_last ).order('diff_full DESC, diff_last DESC, diff_first DESC')
    end

    # Move source clients to this destination client
    # other_client can be a single source record or a destination record
    # if its a destination record, all of its sources will move and it will be delete
    #
    # returns the source client records that moved
    def merge_from(other_client, reviewed_by:, reviewed_at: , client_match_id: nil)
      raise 'only works for destination_clients' unless self.destination?
      moved = []
      transaction do
        # get the existing destination client for other_client
        prev_destination_client = if other_client.destination_client
          other_client.destination_client
        elsif other_client.destination?
          other_client
        end
        # if it had have sources then move those over to us
        # and say who made the decision and when
        other_client.source_clients.each do |m|
          m.warehouse_client_source.update_attributes!(
            destination_id: self.id,
            reviewed_at: reviewed_at,
            reviewd_by: reviewed_by.id,
            client_match_id: client_match_id,
          )
          moved << m
        end
        # if we are a source, move us
        if other_client.warehouse_client_source
          other_client.warehouse_client_source.update_attributes!(
            destination_id: self.id,
            reviewed_at: reviewed_at,
            reviewd_by: reviewed_by.id,
            client_match_id: client_match_id,
          )
          moved << other_client
        end
        # clean up the previous destination
        if prev_destination_client
          
          # move any CAS column data
          previous_cas_columns = prev_destination_client.attributes.slice(*self.class.cas_columns.keys.map(&:to_s))
          current_cas_columns = self.attributes.slice(*self.class.cas_columns.keys.map(&:to_s))
          current_cas_columns.merge!(previous_cas_columns){ |k, old, new| old.presence || new}
          self.update(current_cas_columns)
          self.save()
          prev_destination_client.invalidate_service_history
          prev_destination_client.delete if prev_destination_client.source_clients(true).empty?
        end
        # and invaldiate our own service history
        invalidate_service_history
      end
      moved
    end

    def homeless_episodes_since date:
      source_enrollments
        .homeless
        .where(EntryDate: date..Date.today)
        .map(&:new_episode?)
        .count(true)
    end

    def homeless_episodes_between start_date:, end_date:
      source_enrollments
        .homeless
        .where(EntryDate: start_date..end_date)
        .map(&:new_episode?)
        .count(true)
    end

    # build an array of useful hashes for the enrollments roll-ups
    def enrollments_for scope
      conn = ActiveRecord::Base.connection
      exit_table = GrdaWarehouse::Hud::Exit.arel_table
      enrollment_table = GrdaWarehouse::Hud::Enrollment.arel_table
      project_table = GrdaWarehouse::Hud::Project.arel_table
      organization_table = GrdaWarehouse::Hud::Organization.arel_table
      service_table = GrdaWarehouse::ServiceHistory.arel_table
      client_table = GrdaWarehouse::Hud::Client.arel_table
      columns = {
        ProjectEntryID: enrollment_table[:ProjectEntryID].as('ProjectEntryID').to_sql,
        EntryDate: enrollment_table[:EntryDate].as('EntryDate').to_sql,
        PersonalID: enrollment_table[:PersonalID].as('PersonalID').to_sql,
        ExitDate: exit_table[:ExitDate].as('ExitDate').to_sql,
        date: service_table[:date].as('date').to_sql,
        project_type: service_table[:project_type].as('project_type').to_sql,
        project_name: service_table[:project_name].as('project_name').to_sql,
        project_tracking_method: service_table[:project_tracking_method].as('project_tracking_method').to_sql,
        household_id: service_table[:household_id].as('household_id').to_sql,
        record_type: service_table[:record_type].as('record_type').to_sql,
        data_source_id: service_table[:data_source_id].as('data_source_id').to_sql,
        OrganizationName: organization_table[:OrganizationName].as('OrganizationName').to_sql,
        ProjectID: project_table[:ProjectID].as('ProjectID').to_sql,
        project_id: project_table[:id].as('project_id').to_sql,
        client_source_id: client_table[:id].as('client_source_id').to_sql,
      }
      exit_join = enrollment_table.join(exit_table, Arel::Nodes::OuterJoin).
        on(enrollment_table[:ProjectEntryID].eq(exit_table[:ProjectEntryID]).
          and(enrollment_table[:data_source_id].eq(exit_table[:data_source_id]))
        )
      enrollments = scope.
        joins(exit_join.join_sources).
        joins(:service_histories, :project).
        # joins(:organization).
        where(service_table[:record_type].in(['service', 'entry'])).
        select(*columns.values).
        pluck(*columns.values).
        map do |row|
          Hash[columns.keys.zip(row)]
        end
      enrollments_by_project_entry = enrollments.group_by do |m| 
        [m[:ProjectEntryID], m[:ProjectID], m[:EntryDate], m[:data_source_id]]
      end

      enrollments_by_project_entry.map do |_, e|
        e.sort_by!{|m| m[:date]}
        meta = e.select{|m| m[:record_type] == 'entry'}.first
        dates_served = e.select{|m| m[:record_type] == 'service'}.map{|m| m[:date]}.uniq
        # days that are not also served by a later enrollment of the same project type
        # unless this is a bed-night style project, in which case we count all nights
        count_until = if meta[:project_tracking_method] == 3
          meta[:ExitDate]
        else
          next_enrollment(enrollments: enrollments, type: meta[:project_type], start: meta[:EntryDate]).try(:[], :EntryDate) || meta[:ExitDate]
        end
        # days included in adjusted days that are not also served by a residential project 
        adjusted_dates_for_similar_programs = adjusted_dates(dates: dates_served, stop_date: count_until)
         
        homeless_dates_for_enrollment = adjusted_dates_for_similar_programs - residential_dates(enrollments: enrollments)
        
        {
          client_source_id: meta[:client_source_id],
          project_id: meta[:project_id],
          ProjectID: meta[:ProjectID],
          project_name: "#{meta[:project_name]} < #{meta[:OrganizationName]}",
          entry_date: meta[:EntryDate],
          exit_date: meta[:ExitDate],
          days: dates_served.count,
          homeless: meta[:project_type].in?(Project::CHRONIC_PROJECT_TYPES),
          homeless_days: homeless_dates_for_enrollment.count,
          adjusted_days: adjusted_dates_for_similar_programs.count,
          months_served: adjusted_months_served(dates: adjusted_dates_for_similar_programs),
          household: self.household(meta[:household_id], meta[:EntryDate]),
          project_type: ::HUD::project_type_brief(meta[:project_type]),
          class: "client__service_type_#{meta[:project_type]}",
          most_recent_service: e.select{|m| m[:record_type] == 'service'}.last.try(:[], :date),
          new_episode: new_episode?(enrollments: enrollments, project_type: meta[:project_type], entry_date: meta[:EntryDate]),
          # support: dates_served,
        }
      end
    end

    private def next_enrollment enrollments:, type:, start:
      entry_dates = entry_dates(enrollments: enrollments)
      entry_dates_for_type(entry_dates: entry_dates, type: type).reverse.find do |m|
        m[:EntryDate] > start
      end
    end

    private def entry_dates enrollments:
      @entry_dates ||= enrollments.map do |e|
        {
          ProjectEntryID: e[:ProjectEntryID],
          EntryDate: e[:EntryDate],
          ExitDate: e[:ExitDate],
          project_type: e[:project_type],
          data_source_id: e[:data_source_id], 
        }
      end.uniq
    end

    private def entry_dates_for_type entry_dates:, type:
      @entry_dates_by_project_type ||= entry_dates.group_by do |e|
        e[:project_type]
      end
      @entry_dates_by_project_type[type]
    end

    private def adjusted_dates dates:, stop_date:
      return dates if stop_date.nil?
      dates.select{|date| date < stop_date}
    end

    private def residential_dates enrollments:
      @non_homeless_types ||= GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS - GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES
      @residential_dates ||= enrollments.select do |e| 
        e[:record_type] == 'service' && e[:project_type].in?(@non_homeless_types)
      end.map do |e|
       e[:date]
     end.compact.uniq
    end

    private def homeless_dates enrollments:
      @homeless_dates ||= enrollments.select do |e| 
        e[:project_type].in? GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES
      end.map do |e|
       e[:date]
      end.compact.uniq
   end

    private def adjusted_months_served dates:
      dates.group_by{ |d| [d.year, d.month] }.keys
    end

    # If we haven't been in a homeless project type in the last 30 days, this is a new episode
    # If we dont' currently have a non-homeless residential and we have had one for the past 90 days 
    private def new_episode? enrollments:, project_type:, entry_date:
      return false unless GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES.include?(project_type)
      thirty_days_ago = entry_date - 30.days
      ninety_days_ago = entry_date - 90.days
      res_dates = residential_dates(enrollments: enrollments)
      no_other_homeless = (homeless_dates(enrollments: enrollments) & (thirty_days_ago...entry_date).to_a).empty?
      current_residential = res_dates.include?(entry_date)
      residential_for_past_90_days = (res_dates & (ninety_days_ago...entry_date).to_a).present?
      no_other_homeless || (! current_residential && residential_for_past_90_days)
    end
  end
end
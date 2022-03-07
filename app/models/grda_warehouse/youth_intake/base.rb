###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::YouthIntake
  class Base < GrdaWarehouseBase
    include ArelHelper
    include YouthExport
    self.table_name = :youth_intakes
    has_paper_trail
    acts_as_paranoid

    attr_accessor :other_language, :other_how_hear

    # serialize :client_race, Array
    # serialize :disabilities, Array

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', inverse_of: :youth_intakes
    belongs_to :user, optional: true
    has_many :youth_follow_ups, through: :client
    has_many :case_managements, through: :client

    # after_save :create_required_follow_up!
    after_save :update_destination_client

    scope :visible_by?, ->(user) do
      # users at your agency, plus your own user in case you have no agency.
      agency_user_ids = User.
        with_deleted.
        where.not(agency_id: nil).
        where(agency_id: user.agency_id).
        pluck(:id) + [user.id]

      # if you can see all youth intakes, show them all
      if user.can_view_youth_intake? || user.can_edit_youth_intake?
        all
      # If you can see your agancy's, then show yours and those for your agency
      elsif user.can_view_own_agency_youth_intake? || user.can_edit_own_agency_youth_intake?
        where(user_id: agency_user_ids)
      else
        none
      end
    end

    scope :editable_by?, ->(user) do
      agency_user_ids = User.
        with_deleted.
        where.not(agency_id: nil).
        where(agency_id: user.agency_id).
        pluck(:id) + [user.id]

      # if you can see all youth intakes, show them all
      if user.can_edit_youth_intake?
        all
      # If you can edit your agancy's, then show yours and those for your agency
      elsif user.can_edit_own_agency_youth_intake?
        where(user_id: agency_user_ids)
      else
        none
      end
    end

    scope :served, -> do
      where(turned_away: false)
    end

    scope :not_served, -> do
      where(turned_away: true)
    end

    scope :ongoing, -> do
      where(exit_date: nil)
    end

    scope :open_between, ->(start_date:, end_date:) do
      at = arel_table
      # Excellent discussion of why this works:
      # http://stackoverflow.com/questions/325933/determine-whether-two-date-ranges-overlap
      d_1_start = start_date
      d_1_end = end_date
      d_2_start = at[:engagement_date]
      d_2_end = at[:exit_date]
      # Currently does not count as an overlap if one starts on the end of the other
      where(d_2_end.gteq(d_1_start).or(d_2_end.eq(nil)).and(d_2_start.lteq(d_1_end)))
    end

    scope :opened_after, ->(start_date) do
      at = arel_table
      where(at[:engagement_date].gteq(start_date))
    end

    scope :ordered, -> do
      order(engagement_date: :desc, exit_date: :desc)
    end

    scope :at_risk, -> do
      where(housing_status: at_risk_string)
    end

    scope :homeless, -> do
      where(housing_status: homeless_strings)
    end

    scope :stably_housed, -> do
      where(housing_status: stably_housed_string)
    end

    scope :street_outreach_initial_contact, -> do
      where(street_outreach_contact: 'Yes')
    end

    scope :non_street_outreach_initial_contact, -> do
      where(street_outreach_contact: 'No')
    end

    def self.current_generic_housing_status(on_date: Date.current)
      record = ordered.where(arel_table[:engagement_date].lt(on_date)).limit(1)&.first
      return [] unless record.present?

      [
        record.engagement_date,
        generic_housing_status(record.housing_status),
      ]
    end

    def self.generic_housing_status(status)
      if status == at_risk_string
        :at_risk
      elsif status == stably_housed_string
        :housed
      elsif status.in?(homeless_strings)
        :homeless
      else
        :other
      end
    end

    def self.at_risk_string
      'At risk of homelessness'
    end

    def self.stably_housed_string
      'Stably housed'
    end

    def self.any_visible_by?(user)
      user.can_view_youth_intake? || user.can_edit_youth_intake? || user.can_view_own_agency_youth_intake? || user.can_edit_own_agency_youth_intake?
    end

    def self.any_modifiable_by?(user)
      user.can_edit_youth_intake? || user.can_edit_own_agency_youth_intake?
    end

    def ongoing?
      exit_date.blank?
    end

    # Follow-ups are required 90 days after:
    # 1. The first time a youth identified as at risk for losing housing
    # 2. A youth reports having moved from a non-housed situation to housing
    def create_required_follow_up!
      return if youth_follow_ups.incomplete.exists?

      action = self.class.generic_housing_status(housing_status)
      return unless action
      return unless transitioning_to_at_risk? || transitioning_to_housing?

      options = {
        client_id: client_id,
        user_id: user_id,
        action_on: engagement_date,
        required_on: GrdaWarehouse::Youth::YouthFollowUp.follow_up_date(engagement_date),
        housing_status: housing_status,
        zip_code: stable_housing_zipcode,
        action: action,
      }
      return if GrdaWarehouse::Youth::YouthFollowUp.where(required_on: options[:required_on]).exists?

      GrdaWarehouse::Youth::YouthFollowUp.create(options)
    end

    private def transitioning_to_housing?
      stably_housed? && client.current_youth_housing_situation(on_date: engagement_date) != :housed
    end

    private def transitioning_to_at_risk?
      at_risk_of_homelessness? && client.current_youth_housing_situation(on_date: engagement_date).in?([nil, :housed])
    end

    private def at_risk_of_homelessness?
      housing_status == at_risk_string
    end

    private def at_risk_string
      self.class.at_risk_string
    end

    private def stably_housed?
      housing_status == stably_housed_string
    end

    private def stably_housed_string
      self.class.stably_housed_string
    end

    def self.homeless_strings
      [
        couch_surfing_string,
        street_string,
        shelter_string,
      ]
    end

    def self.couch_surfing_string
      'Experiencing homelessness: couch surfing'
    end

    def self.street_string
      'Experiencing homelessness: street'
    end

    def self.shelter_string
      'Experiencing homelessness: in shelter'
    end

    def yes_no_unknown_refused
      @yes_no_unknown_refused ||= [
        'Yes',
        'No',
        'Unknown',
        'Refused',
      ]
    end

    def yes_no_unknown
      @yes_no_unknown ||= yes_no_unknown_refused - ['Refused']
    end

    def yes_no
      @yes_no ||= [['Yes', 'Yes'], ['No', 'No']]
    end

    def available_housing_stati
      @available_housing_stati ||= begin
        options = {
          self.class.stably_housed_string => 'Stably housed <em>(Individual has sufficient resources or support networks immediately available to prevent them from moving to emergency shelter or another place within 30 days.)</em>'.html_safe,
          self.class.at_risk_string => 'At risk of homelessness <em>(A person 24 years of age or younger whose status or circumstances indicate a significant danger of experiencing homelessness in the near future (four months). Statuses or circumstances that indicate a significant danger may include: (1) youth exiting out-of-home placements; (2) youth who previously were homeless; (3) youth whose parents or primary caregivers are or were previously homeless or have a history of multiple evictions or other types of housing instability; (4) youth who are exposed to abuse and neglect in their homes; (5) youth who experience conflict with parents due to chemical or alcohol dependency, mental health disabilities, or other disabilities; and (6) runaways.)</em>'.html_safe,
        }
        options.merge!({ 'Unstably housed' => 'Unstably housed but does not meet definition of At risk of homelessness' }) if GrdaWarehouse::Config.get(:enable_youth_unstably_housed)
        options.merge!(
          {
            self.class.couch_surfing_string => 'Experiencing homelessness: couch surfing',
            self.class.street_string => 'Experiencing homelessness: street',
            self.class.shelter_string => 'Experiencing homelessness: in shelter',
            'Unknown' => 'Unknown',
          },
        )
        options
      end
    end

    def available_secondary_education
      @available_secondary_education ||= [
        'Currently attending High School',
        'Completed High School',
        'Dropped out of High School',
        'Working on GED/HiSET',
        'Completed GED/HiSET',
        'Unknown',
      ]
    end

    def languages
      @languages ||= ([
        'English',
        'Spanish',
        'Unknown',
        'Other...',
      ] + [client_primary_language&.strip]).compact.uniq
    end

    def parenting_options
      @parenting_options ||= [
        'Not Pregnant',
        'Pregnant',
        'Parenting',
        'Pregnant and Parenting',
        'Unknown',
      ]
    end

    def available_disabilities
      @available_disabilities ||= [
        'Mental / Emotional disability',
        'Medical / Physical disability',
        'Developmental disability',
        'Substance abuse disorder',
        'No disabilities',
        'Unknown',
      ]
    end

    def how_hear_options
      @how_hear_options ||= ([
        'Friend or Family',
        'Other community agency / organization',
        'Social media / agency website',
        'Referred from Street Outreach',
        'Walk-in / self-referral',
        'Other...',
      ] + [other_how_hear&.strip]).reject(&:blank?).compact.uniq
    end

    def other_referral?
      how_hear&.include?('Other') || false
    end

    def stable_housing_options
      @stable_housing_options ||= [
        'Yes, through this agency directly',
        'Yes, through another service provider',
        'Yes, living with family',
        'No',
        'Unknown',
      ]
    end

    def state_agencies
      @state_agencies ||= {
        'DCF' => 'Department of Children and Families (DCF)',
        'DDS' => 'Department of Developmental Services (DDS)',
        'DMH' => 'Department of Mental Health (DMH)',
        'DTA' => 'Department of Transitional Assistance (DTA)',
        'DYS' => 'Department of Youth Services (DYS)',
        'MRC' => 'Massachusetts Rehabilitation Commission (MRC)',
        'Yes' => 'Yes, but the agency name is unspecified',
        'No' => 'No',
        'Unknown' => 'Unknown',
      }
    end

    def race_array
      return [] if client_race == '[]'

      client_race&.map { |r| ::HUD.race(r).presence }&.compact
    end

    def ethnicity_description
      ::HUD.ethnicity(client_ethnicity)
    end

    def gender
      ::HUD.gender(client_gender)
    end

    def update_destination_client
      authoritative_clients = client.source_clients.joins(:data_source).merge(GrdaWarehouse::DataSource.authoritative.youth)
      return unless authoritative_clients.exists?

      data = {
        DOBDataQuality: 1,

        Ethnicity: client_ethnicity,
        AmIndAKNative: client_race.include?('AmIndAKNative') ? 1 : 0,
        Asian: client_race.include?('Asian') ? 1 : 0,
        BlackAfAmerican: client_race.include?('BlackAfAmerican') ? 1 : 0,
        NativeHIPacific: client_race.include?('NativeHIPacific') ? 1 : 0,
        White: client_race.include?('White') ? 1 : 0,
        RaceNone: compute_race_none,
        DateUpdated: Time.now,
      }
      gender_column = HUD.gender_id_to_field_name[client_gender]
      data[gender_column] = 1 unless gender_column.nil?
      data[:FirstName] = first_name if first_name.present?
      data[:LastName] = last_name if last_name.present?
      data[:SSN] = ssn.gsub('-', '') if ssn.present?
      data[:DOB] = client_dob if client_dob.present?

      authoritative_clients.update_all(data)
    end

    def compute_race_none
      return 9 if client_race.include?('RaceNone')
      return 99 if client_race.blank?
      return 99 if client_race&.reject(&:blank?)&.all?(&:empty?)

      nil
    end

    def self.report_columns
      columns = column_names
      columns -= ['user_id', 'deleted_at', 'other_agency_involvement']
      columns.map do |col|
        case col
        when 'client_gender'
          'gender'
        when 'client_race'
          'race_array'
        when 'client_ethnicity'
          'ethnicity_description'
        when 'type'
          'title'
        else
          col
        end
      end
    end

    def self.intake_data
      {}
    end
  end
end

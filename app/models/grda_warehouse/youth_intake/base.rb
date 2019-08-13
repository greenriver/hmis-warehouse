###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::YouthIntake
  class Base < GrdaWarehouseBase
    include ArelHelper
    self.table_name = :youth_intakes
    has_paper_trail
    acts_as_paranoid

    attr_accessor :other_language
    attr_accessor :other_how_hear

    # serialize :client_race, Array
    # serialize :disabilities, Array

    belongs_to :client, class_name: GrdaWarehouse::Hud::Client.name
    belongs_to :user

    after_save :update_destination_client

    scope :visible_by?, -> (user) do
      agency_user_ids = User.
        with_deleted.
        where.not(agency_id: nil).
        where(agency_id: user.agency_id).
        pluck(:id)
      if user.can_edit_anything_super_user?
        all
      # If you can see any, then show yours, those for your agency, and those for anyone with a full release
      elsif user.can_view_youth_intake? || user.can_edit_youth_intake?
        joins(:client).where(
          c_t[:id].in(Arel.sql(GrdaWarehouse::Hud::Client.full_housing_release_on_file.select(:id).to_sql)).
          or(arel_table[:user_id].in(agency_user_ids)).
          or(arel_table[:user_id].eq(user.id))
        )
      # If you can see your agancy's, then show yours and those for your agency
      elsif user.can_view_own_agency_youth_intake? || user.can_edit_own_agency_youth_intake?
        joins(:client).where(
          arel_table[:user_id].in(agency_user_ids).
          or(arel_table[:user_id].eq(user.id))
        )
      else
        none
      end
    end

    scope :editable_by?, -> (user) do
      agency_user_ids = User.
        with_deleted.
        where.not(agency_id: nil).
        where(agency_id: user.agency_id).
        pluck(:id)
      if user.can_edit_anything_super_user?
        all
      # If you can edit any, then show yours and those for anyone with a full release
      elsif  user.can_edit_youth_intake?
        joins(:client).where(
          c_t[:id].in(Arel.sql(GrdaWarehouse::Hud::Client.full_housing_release_on_file.select(:id).to_sql)).
          or(arel_table[:user_id].in(agency_user_ids)).
          or(arel_table[:user_id].eq(user.id))
        )
      # If you can edit your agancy's, then show yours and those for your agency
      elsif user.can_edit_own_agency_youth_intake?
        joins(:client).where(
          arel_table[:user_id].in(agency_user_ids).
          or(arel_table[:user_id].eq(user.id))
        )
      else
        none
      end
    end

    scope :served, -> () do
      where(turned_away: false)
    end

    scope :ongoing, -> do
      where(exit_date: nil)
    end

    scope :open_between, -> (start_date:, end_date:) do
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

    scope :open_after, -> (start_date) do
      at = arel_table
      where(at[:engagement_date].gteq(start_date))
    end

    scope :ordered, -> do
      order(engagement_date: :desc, exit_date: :desc)
    end

    def self.any_visible_by?(user)
      user.can_view_youth_intake? || user.can_edit_youth_intake?
    end

    def self.any_modifiable_by?(user)
      user.can_edit_youth_intake?
    end

    def ongoing?
      exit_date.blank?
    end

    def yes_no_unknown_refused
      @yes_no_unknown_refused ||= [
        'Yes',
        'No',
        'Unknown',
        'Refused'
      ]
    end

    def yes_no_unknown
      @yes_no_unknown ||= yes_no_unknown_refused - ['Refused']
    end

    def yes_no
      @yes_no ||= [['Yes', 'Yes'], ['No', 'No']]
    end

    def available_housing_stati
      @available_housing_stati ||= {
        'Stably housed' => 'Stably housed <em>(Individual has sufficient resources or support networks immediately available to prevent them from moving to emergency shelter or another place within 30 days.)</em>'.html_safe,
        'At risk of homelessness' => 'At risk of homelessness <em>(About to lose primary nighttime residence within 14 days, no subsequent residence identified, and the individual lacks the resources or support networks needed to obtain other permanent housing.)</em>'.html_safe,
        'Unstably housed' => 'Unstably housed but does not meet definition of At risk of homelessness',
        'Experiencing homelessness: couch surfing' => 'Experiencing homelessness: couch surfing',
        'Experiencing homelessness: street' => 'Experiencing homelessness: street',
        'Experiencing homelessness: in shelter' => 'Experiencing homelessness: in shelter',
        'Unknown' => 'Unknown',
      }
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
        'Other...'
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
        'No disabilities',
        'Unknown',
      ]
    end

    def how_hear_options
      @how_hear_options ||= ([
        'Friend of family',
        'Other community agency / organization',
        'Social media / agency website',
        'Referred from Street Outreach',
        'Walk-in / self-referral',
        'Other...',
      ] + [other_how_hear&.strip]).reject(&:blank?).compact.uniq
    end

    def other_referral?
      how_hear.include? 'Other' rescue false
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

    def update_destination_client
      authoritative_clients = client.source_clients.joins(:data_source).merge(GrdaWarehouse::DataSource.authoritative.youth)
      return unless authoritative_clients.exists?

      authoritative_clients.update_all(
        DOB: client_dob,
        DOBDataQuality: 1,
        Gender: client_gender,
        Ethnicity: client_ethnicity,
        AmIndAKNative: client_race.include?('AmIndAKNative') ? 1 : 0,
        Asian: client_race.include?('Asian') ? 1 : 0,
        BlackAfAmerican: client_race.include?('BlackAfAmerican') ? 1 : 0,
        NativeHIOtherPacific: client_race.include?('NativeHIOtherPacific') ? 1 : 0,
        White: client_race.include?('White') ? 1 : 0,
        RaceNone: compute_race_none,

        # Education, Health, and Disability information are also collected, but not processed

        DateUpdated: Time.now,
      )
    end

    def compute_race_none
      return 9 if client_race.include?('RaceNone')
      return 99 if client_race.select { |race| ! race.empty? }.empty?
      return nil
    end

  end
end
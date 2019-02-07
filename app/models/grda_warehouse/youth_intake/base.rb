module GrdaWarehouse::YouthIntake
  class Base < GrdaWarehouseBase
    self.table_name = :youth_intakes
    has_paper_trail
    acts_as_paranoid

    attr_accessor :other_language
    attr_accessor :other_how_hear

    # serialize :client_race, Array
    # serialize :disabilities, Array

    belongs_to :client, class_name: GrdaWarehouse::Hud::Client.name
    belongs_to :user

    scope :visible_by?, -> (user) do
      if user.can_edit_anything_super_user?
        all
      # If you can see any, then show yours and those for anyone with a full release
      elsif user.can_view_youth_intake? || user.can_edit_youth_intake?
        joins(:client).where(
          c_t[:id].in(Arel.sql(GrdaWarehouse::Hud::Client.full_housing_release_on_file.select(:id).to_sql)).
          or(arel_table[:user_id].eq(user.id))
        )
      else
        none
      end
    end

    scope :editable_by?, -> (user) do
      if user.can_edit_anything_super_user?
        all
      # If you can edit any, then show yours and those for anyone with a full release
      elsif  user.can_edit_youth_intake?
        joins(:client).where(
          c_t[:id].in(Arel.sql(GrdaWarehouse::Hud::Client.full_housing_release_on_file.select(:id).to_sql)).
          or(arel_table[:user_id].eq(user.id))
        )
      else
        none
      end
    end

    scope :ongoing, -> do
      where(exit_date: nil)
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
      @available_housing_stati ||= [
        'Stably housed',
        'Unstably housed',
        'Experiencing homelessness: couch surfing',
        'Experiencing homelessness: street',
        'Experiencing homelessness: in shelter',
        'Unknown',
      ]
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

    def stable_housing_options
      @stable_housing_options ||= [
        'Yes, through this agency directly',
        'Yes, through another service provider',
        'Yes, living with family',
        'No',
        'Unknown',
      ]
    end

  end
end
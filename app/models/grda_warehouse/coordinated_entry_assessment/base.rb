###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::CoordinatedEntryAssessment
  class Base < GrdaWarehouseBase
    self.table_name = :ce_assessments

    ####################
    # Associations
    ####################
    belongs_to :user
    belongs_to :assessor, class_name: 'User'
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', inverse_of: :ce_assessments

    ####################
    # Behaviors
    ####################
    has_paper_trail

    ####################
    # Validations
    ####################
    validates_presence_of :user
    validates_email_format_of :client_email, allow_blank: true

    ####################
    # Scopes
    ####################

    scope :in_progress, -> { where(submitted_at: nil) }
    scope :completed, -> { where.not(submitted_at: nil) }
    scope :active, -> { where(active: true) }
    scope :scores, -> { order(submitted_at: :desc).select(:score, :priority_score) }
    # scope :high_vulnerability, -> {
    #   where(priority_score: 731..Float::INFINITY)
    # }
    # scope :medium_vulnerability, -> {
    #   where(priority_score: 365..730)
    # }
    # scope :low_vulnerability, -> {
    #   where(priority_score: 0..364)
    # }
    scope :visible_by?, -> (user) do
      if user.can_view_ce_assessment? || user.can_edit_ce_assessment?
        all
      elsif user.can_submit_ce_assessment?
        in_progress
      else
        none
      end
    end

    def self.available_types
      [
        'GrdaWarehouse::CoordinatedEntryAssessment::Individual',
      ]
    end

    ####################
    # Callbacks
    ####################
    before_save :calculate_score, :calculate_priority_score
    after_update :notify_users

    ####################
    # Access
    ####################
    def self.any_visible_by?(user)
      user.can_view_ce_assessment? || user.can_edit_ce_assessment? || user.can_submit_ce_assessment?
    end

    def self.any_modifiable_by(user)
      user.can_edit_vspdat? || user.can_submit_vspdat?
    end

    def show_as_readonly?
      ! changed? && completed?
    end

    def visible_by?(user)
      self.class.visible_by?(user).where(id: id).exists?
    end

    def notify_users
      return if changes.empty?
      notify_ce_assessment_completed
    end

    def notify_ce_assessment_completed
      if ce_assessment_completed?
        NotifyUser.ce_assessment_completed( id ).deliver_later
      end
    end

    def ce_assessment_completed?
      if changes.any?
        before, after = changes[:submitted_at]
        return before.nil? && after.present?
      else
        return false
      end
    end

    def add_to_cohorts
      if ce_assessment_completed?
        GrdaWarehouse::Cohort.active.where(assessment_trigger: self.class.name).each do |cohort|
          AddCohortClientsJob.perform_later(cohort.id, "#{client_id}", user_id)
        end
      end
    end

    def youth?
      false
    end

    def individual?
      false
    end

    def family?
      false
    end

    def calculate_score
      self.score = [
        lacks_access_to_shelter,
        high_potential_for_vicitimization,
        danger_of_harm,
        acute_medical_condition,
        acute_psychiatric_condition,
        acute_substance_abuse,
      ].count(true)
    end
    def calculate_score!
      calculate_score
      save
    end

    def calculate_priority_score
      score
      # homeless = days_homeless
      # begin
      #   self.priority_score = if score >= 8 && homeless >= 1095
      #     score + 1095
      #    elsif score >= 8 && homeless >= 730
      #     score + 730
      #   elsif score >= 8 && homeless >= 365
      #     score + 365
      #   elsif score >= 0
      #     score
      #   else
      #     0
      #   end
      # rescue
      #   0
      # end
    end

    def version
      1
    end

    def completed?
      submitted_at.present?
    end

    def in_progress?
      !completed
    end

    def self.allowed_parameters
      [
        :assessor_id,
        :location,
        :client_email,
        :military_duty,
        :under_25,
        :over_60,
        :lgbtq,
        :children_under_18,
        :fleeing_dv,
        :living_outdoors,
        :urgent_health_issue,
        :location_option_1,
        :location_option_2,
        :location_option_3,
        :location_option_4,
        :location_option_5,
        :location_option_6,
        :location_option_other,
        :location_option_no,
        :homelessness,
        :substance_use,
        :mental_health,
        :health_care,
        :legal_issues,
        :income,
        :work,
        :independent_living,
        :community_involvement,
        :survival_skills,
        :barrier_no_rental_history,
        :barrier_no_income,
        :barrier_poor_credit,
        :barrier_eviction_history,
        :barrier_eviction_from_public_housing,
        :barrier_bedrooms_3,
        :barrier_service_animal,
        :barrier_cori_issues,
        :barrier_registered_sex_offender,
        :barrier_other,
        :preferences_studio,
        :preferences_roomate,
        :preferences_pets,
        :preferences_accessible,
        :preferences_quiet,
        :preferences_public_transport,
        :preferences_parks,
        :preferences_other,
        :assessor_rating,
        :homeless_six_months,
        :mortality_hospitilization_3,
        :mortality_emergency_room_3,
        :mortality_over_60,
        :mortality_cirrhosis,
        :mortality_renal_disease,
        :mortality_frostbite,
        :mortality_hiv,
        :mortality_tri_morbid,
        :lacks_access_to_shelter,
        :high_potential_for_vicitimization,
        :danger_of_harm,
        :acute_medical_condition,
        :acute_psychiatric_condition,
        :acute_substance_abuse,
      ]
    end

    def assessor_rating_options
      (0..9).map do |i|
        if i.zero?
          ['No services needed', i]
        elsif i == 9
          ['Intensive services needed', i]
        else
          [i, i]
        end
      end
    end

    def options_for_scored column
      scored_column_options[column]
    end

    def scored_column_options
      @scored_column_options ||= {
        homelessness: {
          label: 'Homelessness and Vulnerability',
          collection: {
            'Chronically homeless (12 consecutive months of homelessness/or 4 episodes in 3 yrs totaling at least 1 year; disability.)' => 3,
            'Literally homeless ( Non-Chronic – sleeping in shelter, safe haven or place not meant for human habitation.)' => 2,
            'At immediate risk of homelessness (Housing loss will occur within 48 hours; no other support/housing options.)' => 1,
            'Unstably housed and/or somewhat at risk of homelessness' => 0,
          }
        },
        substance_use: {
          label: 'Substance Use',
          collection: {
            'Vulnerable (Negative consequences due to behaviors associated with substance use. Frequent relapses.)' => 3,
            'Safe (Ability to identify risks and access tools/support systems to decrease harm. Sporadic relapses.)' => 2,
            'Building Capacity (Regular use of supports. Positive results due to increased safety. Abstinent < 12 months, no relapse.)' => 1,
            'Empowered (No history of substance abuse/use. Abstinent 12+ months, without relapse.)' => 0,
          }
        },
        mental_health: {
          label: 'Mental Health',
          collection: {
            'Vulnerable (Danger to self or others. History of no prolonged treatment. No demonstrated ability to utilize support.)' => 3,
            'Safe (Some ability to identify and access support services. Recurrent MH symptoms, but not a danger to self/others.)' => 2,
            'Building Capacity (Mild/minimal symptoms are transient. Only slight impairment in functioning. Ongoing use of supports.)' => 1,
            'Empowered (No history of mental illness. Symptoms are absent or rare.)' => 0,
          }
        },
        health_care: {
          label: 'Health Care',
          collection: {
            'Vulnerable (No medical coverage. High utilizer of emergency services. Significant medical issues.)' => 3,
            'Safe (Has medical coverage. Some medical issues. Some ability to manage healthcare.)' => 2,
            'Building Capacity (Ability to participate in healthcare and manage health issues as they arise.)' => 1,
            'Empowered (Manages and directs own healthcare network. => 0)' => 0,
          }
        },
        legal_issues: {
          label: 'Legal Issues',
          collection: {
            'Vulnerable (Open cases, warrants.)' => 3,
            'Safe (No recent criminal activity. Probation/parole compliant. No open cases, warrants.)' => 2,
            'Building Capacity (No recent criminal activity. No probation/parole.)' => 1,
            'Empowered (No criminal history. No criminal activity in 5+ years.)' => 0,
          }
        },
        income: {
          label: 'Income',
          collection: {
            'Vulnerable (No income. Inability to access benefits. Inadequate income and/or spontaneous or inappropriate spending.)' => 3,
            'Safe (Can meet basic needs with subsidy. Has accessed all mainstream benefits/resources and spending is appropriate.)' => 2,
            'Building Capacity (Meeting basic needs and managing budget without assistance.)' => 1,
            'Empowered (Financially stable, has discretionary income, income is well managed and client is saving money.)' => 0,
          }
        },
        work: {
          label: 'Work',
          collection: {
            'Vulnerable (Unemployed or underemployed; temporary, seasonal, or part-time work; inadequate pay; no benefits.)' => 3,
            'Safe (Employed full-time; inadequate pay; few or no benefits.)' => 2,
            'Building Capacity (Employed full-time with adequate pay and benefits.)' => 1,
            'Empowered (Maintains full-time employment with adequate pay and benefits.) '=> 0,
          }
        },
        independent_living: {
          label: 'Independent Living Skills',
          collection: {
            'Vulnerable (Unable to meet basic needs such as food, clothing, hygiene, housekeeping, etc.)' => 3,
            'Safe (Can meet some, but not all daily living needs without assistance.)' => 2,
            'Building Capacity (Can meet most, but not all daily living needs without assistance.)' => 1,
            'Empowered (Able to meet all basic needs of daily living without assistance.)' => 0,
          }
        },
        community_involvement: {
          label: 'Community Involvement',
          collection: {
            'Vulnerable (Negative consequences due to lack of social supports, isolating or anti‐social behavior.)' => 3,
            'Safe (Ability to identify and utilize support systems. Becoming familiar with resources. "Good neighbor" behavior.)' => 2,
            'Building Capacity (Regular use of support systems. Some participation in recreation; work; education; vocation programs.)' => 1,
            'Empowered (Fully participating and engaged in community activities.)' => 0,
          }
        },
        survival_skills: {
          label: 'Survival Skills',
          collection: {
            'Vulnerable (Vulnerable to exploitation; experiences regular victimization; opts for street; no insight re: dangerous behavior.)' => 3,
            'Safe (Frequently in dangerous situations; dependent on detrimental social network; communicates some social fears.)' => 2,
            'Building Capacity (Has some survival skills; occasionally taken advantage of; may need help recognizing unsafe behaviors.)' => 1,
            'Empowered (Capable of networking and self-advocacy; knows where to go and get there; can maintain safety.)' => 0,
          },
        },
      }
    end
  end
end

###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::CoordinatedEntryAssessment
  class Base < GrdaWarehouseBase
    self.table_name = :ce_assessments

    ####################
    # Associations
    ####################
    belongs_to :user, optional: true
    belongs_to :assessor, class_name: 'User', optional: true
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', inverse_of: :ce_assessments, optional: true

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
    before_save :calculate_scores, :calculate_priority_score
    after_save :notify_users
    after_save :add_to_cohorts

    ####################
    # Access
    ####################
    def self.any_visible_by?(user)
      user.can_view_ce_assessment? || user.can_edit_ce_assessment? || user.can_submit_ce_assessment?
    end

    def self.any_modifiable_by(user)
      user.can_edit_ce_assessment? || user.can_submit_ce_assessment?
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
      if saved_change_to_attribute?(:submitted_at)
        before, after = saved_change_to_attribute(:submitted_at)
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

    def individual?
      false
    end

    def calculate_scores
      self.vulnerability_score = [
        mortality_hospitilization_3,
        mortality_emergency_room_3,
        mortality_over_60,
        mortality_cirrhosis,
        mortality_renal_disease,
        mortality_frostbite,
        mortality_hiv,
        mortality_tri_morbid,
        lacks_access_to_shelter,
        high_potential_for_vicitimization,
        danger_of_harm,
        acute_medical_condition,
        acute_psychiatric_condition,
        acute_substance_abuse,
      ].count(true)
      self.score = [
        optional_score(:homelessness),
        optional_score(:substance_use),
        optional_score(:mental_health),
        optional_score(:health_care),
        optional_score(:legal_issues),
        optional_score(:income),
        optional_score(:work),
        optional_score(:independent_living),
        optional_score(:community_involvement),
        optional_score(:survival_skills),
      ].compact.sum
    end

    def optional_score(attribute)
      value = send(attribute)
      value == 99 ? 0 : value
    end

    def calculate_scores!
      calculate_scores
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

    def make_active!(user)
      assign_attributes(
        submitted_at: Time.now,
        active: true,
        user_id: user.id,
      )
      if valid?
        save
        # mark any other actives as inactive
        client.ce_assessments.where(active: true).where.not(id: id).update_all(active: false)
      else
        assign_attributes(
          submitted_at: nil,
          active: false,
        )
      end
    end

    def self.ensure_active(client)
      most_recent_completed = client.ce_assessments.completed.order(submitted_at: :desc).first
      if most_recent_completed.present?
        most_recent_completed.update(active: true)
        client.ce_assessments.where(active: true).where.not(id: most_recent_completed.id).update_all(active: false)
      end
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
        :location_no_preference,
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


    def self.detail_columns
      @detail_columns ||= {
        'WarehouseID' => [:client, :id],
        'Client Name' => [:client, :name],
        'DOB' => [:client, :DOB],

        'Started At' => [:assessment, :created_at],
        'Submitted At' => [:assessment, :submitted_at],
        'Assessment Score' => [:assessment, :score],
        'Vulnerability Score' => [:assessment, :vulnerability_score],
        'Priority Score' => [:assessment, :priority_score],

        'Assessor' => [:assessor, :name],

        'Current Location' => [:assessment, :location],
        'Military Duty' => [:assessment, :military_duty],
        'Under 25' => [:assessment, :under_25],
        'Over 60' => [:assessment, :over_60],
        'LGBTQ' => [:assessment, :lgbtq],
        'Children Under 18' => [:assessment, :children_under_18],
        'Fleeing DV' => [:assessment, :fleeing_dv],
        'Living Outdoors' => [:assessment, :living_outdoors],
        'Urgent Health Issue' => [:assessment, :urgent_health_issue],

        _('Location Option 1') => [:assessment, :location_option_1],
        _('Location Option 2') => [:assessment, :location_option_2],
        _('Location Option 3') => [:assessment, :location_option_3],
        _('Location Option 4') => [:assessment, :location_option_4],
        'Other Location' => [:assessment, :location_option_other],
        'Unwanted Location' => [:assessment, :location_option_no],
        'No Location Preference' => [:assessment, :location_no_preference],

        'Homelessness Score' => [:assessment, :homelessness],
        'Substance Use Score' => [:assessment, :substance_use],
        'Mental Health Score' => [:assessment, :mental_health],
        'Health Care Score' => [:assessment, :health_care],
        'Legal Issues Score' => [:assessment, :legal_issues],
        'Income Score' => [:assessment, :income],
        'Work Score' => [:assessment, :work],
        'Independent Living Score' => [:assessment, :independent_living],
        'Community Involvement Score' => [:assessment, :community_involvement],
        'Survival Skills Score' => [:assessment, :survival_skills],

        'Barrier: No Rental History' => [:assessment, :barrier_no_rental_history],
        'Barrier: No Income' => [:assessment, :barrier_no_income],
        'Barrier: Poor Credit' => [:assessment, :barrier_poor_credit],
        'Barrier: Eviction History' => [:assessment, :barrier_eviction_history],
        'Barrier: Eviction from Public Housing' => [:assessment, :barrier_eviction_from_public_housing],
        'Barrier: Need 3+ Bedrooms' => [:assessment, :barrier_bedrooms_3],
        'Barrier: Service Animal' => [:assessment, :barrier_service_animal],
        'Barrier: CORI Issues' => [:assessment, :barrier_cori_issues],
        'Barrier: Registered Sex Offender' => [:assessment, :barrier_registered_sex_offender],
        'Other Barriers' => [:assessment, :barrier_other],

        'Prefer: Studio or SRO' => [:assessment, :preferences_studio],
        'Prefer: Roommate' => [:assessment, :preferences_roomate],
        'Prefer: Pets Allowed' => [:assessment, :preferences_pets],
        'Prefer: Handicap Accessible' => [:assessment, :preferences_accessible],
        'Prefer: Quiet Neighborhood' => [:assessment, :preferences_quiet],
        'Prefer: Near Public Transportation' => [:assessment, :preferences_public_transport],
        'Prefer: Near Outdoor Spaces (Parks, Trails, Playgrounds)' => [:assessment, :preferences_parks],
        'Other Preferences' => [:assessment, :preferences_other],

        'Assessor Rating' => [:assessment, :assessor_rating],
        'Client Email Address' => [:assessment, :client_email],

        '6+ Months Homeless' => [:assessment, :homeless_six_months],
        '>3 Hospitalizations/ER Visits' => [:assessment, :mortality_hospitilization_3],
        '>3 ER Visits' => [:assessment, :mortality_emergency_room_3],
        'Age 60+' => [:assessment, :mortality_over_60],
        'Cirrhosis' => [:assessment, :mortality_cirrhosis],
        'Renal Disease' => [:assessment, :mortality_renal_disease],
        'Frostbite' => [:assessment, :mortality_frostbite],
        'HIV/AIDS' => [:assessment, :mortality_hiv],
        'Tri-morbidity' => [:assessment, :mortality_tri_morbid],

        'Lack of Shelter Access' => [:assessment, :lacks_access_to_shelter],
        'Potential of Victimization' => [:assessment, :high_potential_for_vicitimization],
        'Danger of Harm' => [:assessment, :danger_of_harm],
        'Acute Medical Condition' => [:assessment, :acute_medical_condition],
        'Acute Psychiatric Condition' => [:assessment, :acute_psychiatric_condition],
        'Acute Substance Abuse' => [:assessment, :acute_substance_abuse],
      }.freeze
    end

    def assessor_rating_options
      (0..9).map do |i|
        if i.zero?
          ["#{i} - No services needed", i]
        elsif i == 9
          ["#{i} - Intensive services needed", i]
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
            '3 -- Chronically homeless (12 consecutive months of homelessness/or 4 episodes in 3 yrs totaling at least 1 year; disability.)' => 3,
            '2 -- Literally homeless ( Non-Chronic – sleeping in shelter, safe haven or place not meant for human habitation.)' => 2,
            '1 -- At immediate risk of homelessness (Housing loss will occur within 48 hours; no other support/housing options.)' => 1,
            '0 -- Unstably housed and/or somewhat at risk of homelessness.' => 0,
            'Client refused to answer.' => 99,
          }
        },
        substance_use: {
          label: 'Substance Use',
          collection: {
            '3 -- Vulnerable (Negative consequences due to behaviors associated with substance use. Frequent relapses.)' => 3,
            '2 -- Safe (Ability to identify risks and access tools/support systems to decrease harm. Sporadic relapses.)' => 2,
            '1 -- Building Capacity (Regular use of supports. Positive results due to increased safety. Abstinent < 12 months, no relapse.)' => 1,
            '0 -- Empowered (No history of substance abuse/use. Abstinent 12+ months, without relapse.)' => 0,
            'Client refused to answer.' => 99,
          }
        },
        mental_health: {
          label: 'Mental Health',
          collection: {
            '3 -- Vulnerable (Danger to self or others. History of no prolonged treatment. No demonstrated ability to utilize support.)' => 3,
            '2 -- Safe (Some ability to identify and access support services. Recurrent MH symptoms, but not a danger to self/others.)' => 2,
            '1 -- Building Capacity (Mild/minimal symptoms are transient. Only slight impairment in functioning. Ongoing use of supports.)' => 1,
            '0 -- Empowered (No history of mental illness. Symptoms are absent or rare.)' => 0,
            'Client refused to answer.' => 99,
          }
        },
        health_care: {
          label: 'Health Care',
          collection: {
            '3 -- Vulnerable (No medical coverage. High utilizer of emergency services. Significant medical issues.)' => 3,
            '2 -- Safe (Has medical coverage. Some medical issues. Some ability to manage healthcare.)' => 2,
            '1 -- Building Capacity (Ability to participate in healthcare and manage health issues as they arise.)' => 1,
            '0 -- Empowered (Manages and directs own healthcare network.)' => 0,
            'Client refused to answer.' => 99,
          }
        },
        legal_issues: {
          label: 'Legal Issues',
          collection: {
            '3 -- Vulnerable (Open cases, warrants.)' => 3,
            '2 -- Safe (No recent criminal activity. Probation/parole compliant. No open cases, warrants.)' => 2,
            '1 -- Building Capacity (No recent criminal activity. No probation/parole.)' => 1,
            '0 -- Empowered (No criminal history. No criminal activity in 5+ years.)' => 0,
            'Client refused to answer.' => 99,
          }
        },
        income: {
          label: 'Income',
          collection: {
            '3 -- Vulnerable (No income. Inability to access benefits. Inadequate income and/or spontaneous or inappropriate spending.)' => 3,
            '2 -- Safe (Can meet basic needs with subsidy. Has accessed all mainstream benefits/resources and spending is appropriate.)' => 2,
            '1 -- Building Capacity (Meeting basic needs and managing budget without assistance.)' => 1,
            '0 -- Empowered (Financially stable, has discretionary income, income is well managed and client is saving money.)' => 0,
            'Client refused to answer.' => 99,
          }
        },
        work: {
          label: 'Work',
          collection: {
            '3 -- Vulnerable (Unemployed or underemployed; temporary, seasonal, or part-time work; inadequate pay; no benefits.)' => 3,
            '2 -- Safe (Employed full-time; inadequate pay; few or no benefits.)' => 2,
            '1 -- Building Capacity (Employed full-time with adequate pay and benefits.)' => 1,
            '0 -- Empowered (Maintains full-time employment with adequate pay and benefits.) '=> 0,
            'Client refused to answer.' => 99,
          }
        },
        independent_living: {
          label: 'Independent Living Skills',
          collection: {
            '3 -- Vulnerable (Unable to meet basic needs such as food, clothing, hygiene, housekeeping, etc.)' => 3,
            '2 -- Safe (Can meet some, but not all daily living needs without assistance.)' => 2,
            '1 -- Building Capacity (Can meet most, but not all daily living needs without assistance.)' => 1,
            '0 -- Empowered (Able to meet all basic needs of daily living without assistance.)' => 0,
            'Client refused to answer.' => 99,
          }
        },
        community_involvement: {
          label: 'Community Involvement',
          collection: {
            '3 -- Vulnerable (Negative consequences due to lack of social supports, isolating or anti‐social behavior.)' => 3,
            '2 -- Safe (Ability to identify and utilize support systems. Becoming familiar with resources. "Good neighbor" behavior.)' => 2,
            '1 -- Building Capacity (Regular use of support systems. Some participation in recreation; work; education; vocation programs.)' => 1,
            '0 -- Empowered (Fully participating and engaged in community activities.)' => 0,
            'Client refused to answer.' => 99,
          }
        },
        survival_skills: {
          label: 'Survival Skills',
          collection: {
            '3 -- Vulnerable (Vulnerable to exploitation; experiences regular victimization; opts for street; no insight re: dangerous behavior.)' => 3,
            '2 -- Safe (Frequently in dangerous situations; dependent on detrimental social network; communicates some social fears.)' => 2,
            '1 -- Building Capacity (Has some survival skills; occasionally taken advantage of; may need help recognizing unsafe behaviors.)' => 1,
            '0 -- Empowered (Capable of networking and self-advocacy; knows where to go and get there; can maintain safety.)' => 0,
            'Client refused to answer.' => 99,
          },
        },
      }
    end
  end
end

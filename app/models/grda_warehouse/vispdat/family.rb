###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Vispdat
  class Family < Base

    has_many :children

    accepts_nested_attributes_for :children, allow_destroy: true, limit: 7, reject_if: :all_blank

    %w(
      any_member_pregnant
      family_member_tri_morbidity
      any_children_removed
      any_family_legal_issues
      any_children_lived_with_family
      any_child_abuse
      children_attend_school
      family_members_changed
      other_family_members
      planned_family_activities
      time_spent_alone_13
      time_spent_alone_12
      time_spent_helping_siblings
    ).each do |field|
      enum "#{field}_answer".to_sym => { "#{field}_answer_yes".to_sym => 1, "#{field}_answer_no".to_sym => 0, "#{field}_answer_refused".to_sym => 2 }
    end

    # Require the refused checkbox to be checked if no answer given
    # Require an answer if the refused checkbox not checked.
    %w(
      number_of_children_under_18_with_family
      number_of_children_under_18_not_with_family
    ).each do |field|
      # if both blank, indicate that refused must be checked
      validates [field, '_refused'].join.to_sym, presence: { message: 'should be checked if refusing to answer' }, if: -> { send(field.to_sym).blank? }

      # if both blank, indicate a value is needed
      validates field.to_sym, presence: { message: 'please enter a value or mark refused' }, if: -> { send([field, '_refused?'].join.to_sym).blank? }

      # if refused checked and answer given
      validates field.to_sym, absence: { message: 'cannot have an entry if refusing to answer' }, if: -> { send([field, '_refused?'].join.to_sym) }
    end

    def parent2_age
      return if parent2_dob.blank?
      GrdaWarehouse::Hud::Client.age_on(date: Date.current, dob: parent2_dob)
    end

    def calculate_score
      self.score = pre_survey_score +
      history_score +
      risk_score +
      social_score +
      wellness_score +
      family_unit_score
    end

    # family pre-survey include family size
    def pre_survey_score
      dob_score + family_size_score
    end

    # family omits pregnancy question for physical health
    # and asks this under family_size_score
    def physical_health_score
      (
        leave_answer_yes? ||
        chronic_answer_yes? ||
        hiv_answer_yes? ||
        disability_answer_yes? ||
        avoid_help_answer_yes?
      ) ? 1 : 0
    end

    def wellness_score
      physical_health_score +
      substance_abuse_score +
      mental_health_score +
      tri_morbidity_score +
      medication_score +
      abuse_and_trauma_score
    end

    # family tri morbidity also requires 1 member to have all 3 conditions
    def tri_morbidity_score
      (
        physical_health_score==1 &&
        substance_abuse_score==1 &&
        mental_health_score==1
      ) && family_member_tri_morbidity_answer_yes? ? 1 : 0
    end

    def family_unit_score
      family_legal_issues_score +
      needs_of_children_score +
      family_stability_score +
      parental_engagement_score
    end

    def family_legal_issues_score
      (
        any_children_removed_answer_yes? ||
        any_family_legal_issues_answer_yes?
      ) ? 1 : 0
    end

    def needs_of_children_score
      (
        any_children_lived_with_family_answer_yes? ||
        any_child_abuse_answer_yes? ||
        children_attend_school_answer_no?
      ) ? 1 : 0
    end

    def family_stability_score
      (
        family_members_changed_answer_yes? ||
        other_family_members_answer_yes?
      ) ? 1 : 0
    end

    def parental_engagement_score
      (
        planned_family_activities_answer_no? ||
        time_spent_alone_13_answer_yes? ||
        time_spent_alone_12_answer_yes? ||
        time_spent_helping_siblings_answer_yes?
      ) ? 1 : 0
    end

    # score class different for family
    def score_class
      case score
      when 0..3
        'success'
      when 4..8
        'warning'
      when 9..Float::INFINITY
        'danger'
      else
        'default'
      end
    end

    def calculate_recommendation
      self.recommendation = case score
      when 0..3
        "No Housing Intervention"
      when 4..8
        "An Assessment for Rapid Re-Housing"
      when 9..Float::INFINITY
        "An Assessment for Permanent Supportive Housing/Housing First"
      else
        "Invalid Score"
      end
    end

    # check age of both parents
    def dob_score
      parent1_age = client.age
      return 0 if parent1_age.blank? && parent2_age.blank?
      return 1 if parent1_age && parent1_age >= 60
      return 1 if parent2_age && parent2_age >= 60
      return 0
    end

    def parent2_age
      return if parent2_dob.blank?
      ((Date.current - parent2_dob) / 365.25).to_i
    end

    def family_size_score
      (single_parent_score > 0 || two_parents_score > 0) ? 1 : 0
    end

    def single_parent_score
      (single_parent_with_2plus_children? ||
       child_age_11_or_younger? ||
       any_member_pregnant_answer_yes?) ? 1 : 0
    end

    def two_parents_score
      (two_parents_with_3plus_children? || child_age_6_or_younger? || any_member_pregnant_answer_yes?) ? 1 : 0
    end

    def single_parent_with_2plus_children?
      parent2_none? && children.size >= 2
    end

    def child_age_11_or_younger?
      children.any? { |child| child.dob && child.dob <= 11.years.ago }
    end

    def two_parents_with_3plus_children?
      !parent2_none? && children.size >= 3
    end

    def child_age_6_or_younger?
      children.any? { |child| child.dob && child.dob <= 6.years.ago }
    end

    def two_parents?
      !parent2_none?
    end

    def self.allowed_parameters
      super + [
        :parent2_none,
        :parent2_first_name,
        :parent2_nickname,
        :parent2_last_name,
        :parent2_language_answer,
        :parent2_dob,
        :parent2_ssn,
        :parent2_drug_release,
        :parent2_hiv_release,
        :number_of_children_under_18_with_family,
        :number_of_children_under_18_with_family_refused,
        :number_of_children_under_18_not_with_family,
        :number_of_children_under_18_not_with_family_refused,
        :number_of_bedrooms,
        :any_member_pregnant_answer,
        :family_member_tri_morbidity_answer,
        :any_children_removed_answer,
        :any_family_legal_issues_answer,
        :any_children_lived_with_family_answer,
        :any_child_abuse_answer,
        :children_attend_school_answer,
        :family_members_changed_answer,
        :other_family_members_answer,
        :planned_family_activities_answer,
        :time_spent_alone_13_answer,
        :time_spent_alone_12_answer,
        :time_spent_helping_siblings_answer,
        children_attributes: [:id, :first_name, :last_name, :dob, :_destroy]
      ]
    end

    def family?
      true
    end

    FAMILY_QUESTIONS = {
      number_of_bedrooms: "What is the minimum number of bedrooms required for this family?",
      sleep: "Where do you and your family sleep most frequently? (check one)",
      housing: "How long has it been since you and your family lived in permanent stable housing?",
      homeless: "In the last three years, how many times have you and your family been homeless?",
      past_six_months: "In the past six months, how many times have you or anyone in your family...",
      talked_to_police: "Talked to police because they witnessed a crime, were the victim of a crime, or the alleged perpetrator of a crime or because the police told them that they must move along?",
      been_attacked: "Have you or anyone in your family been attacked or beaten up since they’ve become homeless?",
      harm_yourself: "Have you or anyone in your family threatened to or tried to harm themself or anyone else in the last year?",
      legal_stuff: "Do you or anyone in your family have any legal stuff going on right now that may result in them being locked up, having to pay fines, or that make it more difficult to rent a place to live?",
      force_you: "Does anybody force or trick you or anyone in your family to do things that you do not want to do?",
      risky_things: "Do you or anyone in your family ever do things that may be considered to be risky like exchange sex for money, run drugs for someone, have unprotected sex with someone they don’t know, share a needle, or anything like that?",
      owe_money: "Is there any person, past landlord, business, bookie, dealer, or government group like the IRS that thinks you or anyone in your family owe them money?",
      get_money: "Do you or anyone in your family get any money from the government, a pension, an inheritance, working under the table, a regular job, or anything like that?",
      planned_activities: "Does everyone in your family have planned activities, other than just surviving, that make them feel happy and fulfilled?",
      basic_needs: "Is everyone in your family currently able to take care of basic needs like bathing, changing clothes, using a restroom, getting food and clean water and other things like that?",
      homelessness_cause: "Is your family’s current homelessness in any way caused by a relationship that broke down, an unhealthy or abusive relationship, or because other family or friends caused your family to become evicted?",
      leave_due_to_health: "Has your family ever had to leave an apartment, shelter program, or other place you were staying because of the physical health of you or anyone in your family?",
      chronic_health_issues: "Do you or anyone in your family have any chronic health issues with your liver, kidneys, stomach, lungs or heart?",
      space_interest: "If there was space available in a program that specifically assists people that live with HIV or AIDS, would that be of interest to you or anyone in your family?",
      physical_disabilities: "Does anyone in your family have any physical disabilities that would limit the type of housing you could access, or would make it hard to live independently because you’d need help?",
      avoid_help: "When someone in your family is sick or not feeling well, does your family avoid getting medical help?",
      kicked_out: "Has drinking or drug use by you or anyone in your family led your family to being kicked out of an apartment or program where you were staying in the past?",
      drug_use: "Will drinking or drug use make it difficult for your family to stay housed or afford your housing?",
      trouble_housing: "Has your family ever had trouble maintaining your housing, or been kicked out of an apartment, shelter program or other place you were staying, because of:",
      mental_health: "A mental health issue or concern?",
      head_injury: "A past head injury?",
      learning_disability: "A learning disability, developmental disability, or other impairment?",
      live_independently: "Do you or anyone in your family have any mental health or brain issues that would make it hard for your family to live independently because help would be needed?",
      single_member_morbidity: "IF THE FAMILY SCORED 1 EACH FOR PHYSICAL HEALTH, SUBSTANCE ABUSE, AND MENTAL HEALTH: Does any single member of your household have a medical condition, mental health concerns, and experience with problematic substance use?",
      take_medications: "Are there any medications that a doctor said you or anyone in your family should be taking that, for whatever reason, they are not taking?",
      sell_medications: "Are there any medications like painkillers that you or anyone in your family don’t take the way the doctor prescribed or where they sell the medication?",
      abuse_trauma: "YES OR NO: Has your family’s current period of homelessness been caused by an experience of emotional, physical, psychological, sexual, or other type of abuse, or by any other trauma you or anyone in your family have experienced?"
    }

    def question key
      FAMILY_QUESTIONS[key] || super(key)
    end

  end
end

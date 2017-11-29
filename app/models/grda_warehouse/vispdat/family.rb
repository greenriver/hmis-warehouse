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
      age = (Date.today - parent2_dob) / 365.25
      age.to_i
    end

    def calculate_score
      self.score = pre_survey_score +
      history_score +
      risk_score +
      social_score +
      wellness_score +
      family_unit_score
    end

    # family omits pregnancy question for physical health
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
      (Date.today - parent2_dob) / 365.25
    end

    def family_size_score
      (single_parent_score > 0 || two_parents_score > 0) ? 1 : 0
    end

    def single_parent_score
      (single_parent_with_2plus_children? ||
       child_age_11_or_younger? ||
       any_member_pregnant?) ? 1 : 0
    end

    def two_parents_score
      (two_parents_with_3plus_children? || child_age_6_or_younger? || any_member_pregnant?) ? 1 : 0
    end

    def single_parent_with_2plus_children?
      parent2_none? && children.size >= 2
    end

    def child_age_11_or_younger?
      children.any? { |child| child.dob <= 11.years.ago }
    end

    def two_parents_with_3plus_children?
      !parent2_none? && children.size >= 3
    end

    def child_age_6_or_younger?
      children.any? { |child| child.dob <= 6.years.ago }
    end

    def two_parents?
      !parent2_none?
    end

    def family?
      true
    end

  end
end
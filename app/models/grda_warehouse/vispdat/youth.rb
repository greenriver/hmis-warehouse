module GrdaWarehouse::Vispdat
  class Youth < Base

    %w( 
      marijuana violence_between_family_members 
      homeless_due_to_ran_away 
      homeless_due_to_religions_beliefs 
      homeless_due_to_family 
      homeless_due_to_gender_identity 
      incarcerated_before_18
    ).each do |field|
      enum "#{field}_answer".to_sym => { "#{field}_answer_yes".to_sym => 1, "#{field}_answer_no".to_sym => 0, "#{field}_answer_refused".to_sym => 2 }
    end

    # different for youth
    def calculate_recommendation
      self.recommendation = case score
      when 0..3
        "no moderate or high intensity services be provided at this time"
      when 4..7
        "assessment for time-limited supports with moderate intensity"
      when 8..Float::INFINITY
        "assessment for long-term housing with high service intensity"
      else
        "Invalid Score"
      end
    end

    # abuse_and_trauma_score is put under social_score on youth form
    # whereas its under wellness_score on individual form
    def social_score
      money_management_score +
      meaningful_activity_score +
      self_care_score +
      social_relationship_score +
      abuse_and_trauma_score
    end
    def wellness_score
      physical_health_score +
      substance_abuse_score +
      mental_health_score +
      tri_morbidity_score +
      medication_score
    end

    # date of birth score differs from individual
    def dob_score
      age = client.age
      return 0 unless age.present?
      age <= 17 ? 1 : 0
    end

    def legal_issues_score
      legal_answer_yes? || incarcerated_before_18_answer_yes? ? 1 : 0
    end

    def social_relationship_score
      homeless_due_to_ran_away_answer_yes? ||
      homeless_due_to_religions_beliefs_answer_yes? ||
      homeless_due_to_family_answer_yes? ||
      homeless_due_to_gender_identity_answer_yes? ? 1 : 0
    end
    
    def abuse_and_trauma_score
      violence_between_family_members_answer_yes? || abusive_answer_yes? ? 1 : 0
    end

    def substance_abuse_score
      (eviction_answer_yes? || drinking_answer_yes? || marijuana_answer_yes?) ? 1 : 0
    end

    def self.allowed_parameters
      super + [
        :marijuana_answer, 
        :homeless_due_to_ran_away_answer, 
        :homeless_due_to_religions_beliefs_answer, 
        :homeless_due_to_family_answer, 
        :homeless_due_to_gender_identity_answer,
        :violence_between_family_members_answer,
        :incarcerated_before_18_answer
      ]
    end

  end
end
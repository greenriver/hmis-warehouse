require 'rails_helper'

RSpec.describe GrdaWarehouse::Vispdat::Family, type: :model do
  
  let(:vispdat) { build :family_vispdat }

  describe 'youth?' do
    it 'returns false' do
      expect( vispdat.youth? ).to be false
    end
  end

  describe 'family?' do
    it 'returns true' do
      expect( vispdat.family? ).to be true
    end
  end

  describe 'individual?' do
    it 'returns false' do
      expect( vispdat.individual? ).to be false
    end
  end

  describe 'dob_score' do
    before(:each) do
      vispdat.parent2_dob = Date.new(1974,1,1)
    end
    context 'when parent ages missing' do
      it 'returns 0' do
        allow( vispdat.client ).to receive(:age).and_return nil
        allow( vispdat ).to receive(:parent2_age).and_return nil
        expect( vispdat.dob_score ).to eq 0
      end
    end
    context 'when parent1 age >= 60' do
      it 'returns 1' do
        allow( vispdat.client ).to receive(:age).and_return 61
        allow( vispdat ).to receive(:parent2_age).and_return 59
        expect( vispdat.dob_score ).to eq 1
      end
    end
    context 'when parent2 age >= 60' do
      it 'returns 1' do
        allow( vispdat.client ).to receive(:age).and_return 59
        allow( vispdat ).to receive(:parent2_age).and_return 61
        expect( vispdat.dob_score ).to eq 1
      end
    end
    context 'when both parents under 60' do
      it 'returns 0' do
        allow( vispdat.client ).to receive(:age).and_return 59
        allow( vispdat ).to receive(:parent2_age).and_return 59
        expect( vispdat.dob_score ).to eq 0
      end
    end
  end

  describe 'family_size_score' do
    context 'when single_parent_score 1' do
      before(:each) { allow(vispdat).to receive(:single_parent_score).and_return 1 }
      it 'returns 1' do
        expect( vispdat.family_size_score ).to eq 1
      end
    end
    context 'when two_parents_score 1' do
      before(:each) { allow(vispdat).to receive(:two_parents_score).and_return 1 }
      it 'returns 1' do
        expect( vispdat.family_size_score ).to eq 1
      end
    end
    context 'when both 0' do
      it 'returns 0' do
        expect( vispdat.family_size_score ).to eq 0
      end
    end
  end

  describe 'single_parent_score' do
    context 'when single with 2+ children' do
      before(:each) { expect(vispdat).to receive(:single_parent_with_2plus_children?).and_return true }
      it 'returns 1' do
        expect( vispdat.single_parent_score ).to eq 1
      end
    end
    context 'when child 11 or younger' do
      before(:each) { expect(vispdat).to receive(:child_age_11_or_younger?).and_return true }
      it 'returns 1' do
        expect( vispdat.single_parent_score ).to eq 1
      end
    end
    context 'when anyone pregnant' do
      before(:each) { expect(vispdat).to receive(:any_member_pregnant_answer_yes?).and_return true }
      it 'returns 1' do
        expect( vispdat.single_parent_score ).to eq 1
      end
    end
    context 'when none of those' do
      it 'returns 0' do
        expect( vispdat.single_parent_score ).to eq 0
      end
    end
  end

  describe 'two_parents_score' do
    context 'when 2 parents with 3+ kids' do
      before(:each) do
        expect(vispdat).to receive(:two_parents_with_3plus_children?).and_return true
      end
      it 'returns 1' do
        expect( vispdat.two_parents_score ).to eq 1
      end
    end
    context 'when kid 6 or younger' do
      before(:each) do
        expect(vispdat).to receive(:child_age_6_or_younger?).and_return true
      end
      it 'returns 1' do
        expect( vispdat.two_parents_score ).to eq 1
      end
    end
    context 'when anyone pregnant' do
      before(:each) do
        expect(vispdat).to receive(:any_member_pregnant_answer_yes?).and_return true
      end
      it 'returns 1' do
        expect( vispdat.two_parents_score ).to eq 1
      end
    end
    context 'when none of those' do
      it 'returns 0' do
        expect( vispdat.two_parents_score ).to eq 0
      end
    end
  end

  describe 'sleep_score' do
    [
      :sleep_outdoors, 
      :sleep_couch_surfing, 
      :sleep_other, 
      :sleep_refused
    ].each do |answer|
      context "when #{answer}" do
        before(:each) { vispdat.sleep_answer = answer }
        it 'returns 1' do
          expect( vispdat.sleep_score ).to eq 1
        end
      end
    end

    [
      :sleep_shelters, 
      :sleep_transitional_housing, 
      :sleep_safe_haven
    ].each do |answer|
      context "when #{answer}" do
        before(:each) { vispdat.sleep_answer = answer }
        it 'returns 1' do
          expect( vispdat.sleep_score ).to eq 0
        end
      end
    end
  end

  describe 'homeless_score' do
    context 'when years_homeless > 0' do
      before(:each) { vispdat.homeless = 1; vispdat.homeless_period = 'years' }
      it 'returns 1' do
        expect( vispdat.homeless_score ).to eq 1
      end
    end
    context 'when episodes_homeless > 3' do
      before(:each) { vispdat.episodes_homeless = 4 }
      it 'returns 1' do
        expect( vispdat.homeless_score ).to eq 1
      end
    end
    context 'when years_homeless 0 and episodes_homeless 3' do
      it 'returns 0' do
        expect( vispdat.homeless_score ).to eq 0
      end
    end
  end

  describe 'emergency_services_score' do
    context 'when services > 3' do
      before(:each) do
        vispdat.ambulance = 1
        vispdat.inpatient = 1
        vispdat.jail = 2
      end
      it 'returns 1' do
        expect( vispdat.emergency_service_score ).to eq 1
      end
    end
    context 'when service <= 3' do
      it 'returns 0' do
        expect( vispdat.emergency_service_score ).to eq 0
      end
    end
  end

  describe 'risk_of_harm_score' do
    context 'when attacked_answer_yes' do
      before(:each) { vispdat.attacked_answer = :attacked_answer_yes }
      it 'returns 1' do
        expect( vispdat.risk_of_harm_score ).to eq 1
      end
    end
    context 'when threatened_answer_yes' do
      before(:each) { vispdat.threatened_answer = :threatened_answer_yes }
      it 'returns 1' do
        expect( vispdat.risk_of_harm_score ).to eq 1
      end
    end
    context 'when not attacked or threatened' do
      it 'returns 0' do
        expect( vispdat.risk_of_harm_score ).to eq 0
      end
    end
  end

  describe 'legal_issues_score' do
    context 'when legal_answer_yes' do
      before(:each) { vispdat.legal_answer = :legal_answer_yes }
      it 'returns 1' do
        expect( vispdat.legal_issues_score ).to eq 1
      end
    end
    context 'when legal_answer_no' do
      it 'returns 0' do
        expect( vispdat.legal_issues_score ).to eq 0
      end
    end
  end

  describe 'risk_of_exploitation_score' do
    context 'when tricked' do
      before(:each) { vispdat.tricked_answer = :tricked_answer_yes }
      it 'returns 1' do
        expect( vispdat.risk_of_exploitation_score ).to eq 1
      end
    end
    context 'when risky' do
      before(:each) { vispdat.risky_answer = :risky_answer_yes }
      it 'returns 1' do
        expect( vispdat.risk_of_exploitation_score ).to eq 1
      end
    end
    context 'when neither' do
      it 'returns 0' do
        expect( vispdat.risk_of_exploitation_score ).to eq 0
      end
    end
  end

  describe 'money_management_score' do
    context 'when owe' do
      before(:each) { vispdat.owe_money_answer = :owe_money_answer_yes }
      it 'returns 1' do
        expect( vispdat.money_management_score ).to eq 1
      end
    end
    context 'when not getting money' do
      before(:each) { vispdat.get_money_answer = :get_money_answer_no }
      it 'returns 1' do
        expect( vispdat.money_management_score ).to eq 1
      end
    end
    context 'when neither' do
      it 'returns 0' do
        expect( vispdat.money_management_score ).to eq 0
      end
    end
  end

  describe 'meaningful_activity_score' do
    context 'when no activities' do
      before(:each) { vispdat.activities_answer = :activities_answer_no }
      it 'returns 1' do
        expect( vispdat.meaningful_activity_score ).to eq 1
      end
    end
    context 'when activities' do
      before(:each) { vispdat.activities_answer = :activities_answer_yes }
      it 'returns 0' do
        expect( vispdat.meaningful_activity_score ).to eq 0
      end
    end
  end

  describe 'self_care_score' do
    context 'when basic needs met' do
      before(:each) { vispdat.basic_needs_answer = :basic_needs_answer_yes }
      it 'returns 0' do
        expect( vispdat.self_care_score ).to eq 0
      end
    end
    context 'when basic needs not met' do
      before(:each) { vispdat.basic_needs_answer = :basic_needs_answer_no }
      it 'returns 1' do
        expect( vispdat.self_care_score ).to eq 1
      end
    end
  end

  describe 'social_relationship_score' do
    context 'when abuse' do
      before(:each) { vispdat.abusive_answer = :abusive_answer_yes }
      it 'returns 1' do
        expect( vispdat.social_relationship_score ).to eq 1
      end
    end
    context 'when no abuse' do
      before(:each) { vispdat.abusive_answer = :abusive_answer_no }
      it 'returns 0' do
        expect( vispdat.social_relationship_score ).to eq 0
      end
    end
  end

  describe 'physical_health_score' do
    context 'when leave due to health' do
      before(:each) { vispdat.leave_answer = :leave_answer_yes }
      it 'returns 1' do
        expect( vispdat.physical_health_score ).to eq 1
      end
    end
    context 'when chronic disability' do
      before(:each) { vispdat.chronic_answer = :chronic_answer_yes }
      it 'returns 1' do
        expect( vispdat.physical_health_score ).to eq 1
      end
    end
    context 'when HIV' do
      before(:each) { vispdat.hiv_answer = :hiv_answer_yes }
      it 'returns 1' do
        expect( vispdat.physical_health_score ).to eq 1
      end
    end
    context 'when disability' do
      before(:each) { vispdat.disability_answer = :disability_answer_yes }
      it 'returns 1' do
        expect( vispdat.physical_health_score ).to eq 1
      end
    end
    context 'when avoid help' do
      before(:each) { vispdat.avoid_help_answer = :avoid_help_answer_yes }
      it 'returns 1' do
        expect( vispdat.physical_health_score ).to eq 1
      end
    end
    context 'when none' do
      it 'returns 0' do
        expect( vispdat.physical_health_score ).to eq 0
      end
    end
  end

  describe 'substance_abuse_score' do
    context 'when eviction' do
      before(:each) { vispdat.eviction_answer = :eviction_answer_yes }
      it 'returns 1' do
        expect( vispdat.substance_abuse_score ).to eq 1
      end
    end
    context 'when drinking' do
      before(:each) { vispdat.drinking_answer = :drinking_answer_yes }
      it 'returns 1' do
        expect( vispdat.substance_abuse_score ).to eq 1
      end
    end
    context 'when neither' do
      it 'returns 0' do
        expect( vispdat.substance_abuse_score ).to eq 0
      end
    end
  end

  describe 'mental_health_score' do
    context 'when mental issue' do
      before(:each) { vispdat.mental_answer = :mental_answer_yes }
      it 'returns 1' do
        expect( vispdat.mental_health_score ).to eq 1
      end
    end
    context 'when head injury' do
      before(:each) { vispdat.head_answer = :head_answer_yes }
      it 'returns 1' do
        expect( vispdat.mental_health_score ).to eq 1
      end
    end
    context 'when learning disability' do
      before(:each) { vispdat.learning_answer = :learning_answer_yes }
      it 'returns 1' do
        expect( vispdat.mental_health_score ).to eq 1
      end
    end
    context 'when brain injury' do
      before(:each) { vispdat.brain_answer = :brain_answer_yes }
      it 'returns 1' do
        expect( vispdat.mental_health_score ).to eq 1
      end
    end
    context 'when none' do
      it 'returns 0' do
        expect( vispdat.mental_health_score ).to eq 0
      end
    end
  end

  describe 'tri_morbidity_score' do
    context 'when all 3 return 1 and one member has all 3' do
      before(:each) do
        allow(vispdat).to receive(:physical_health_score).and_return 1
        allow(vispdat).to receive(:substance_abuse_score).and_return 1
        allow(vispdat).to receive(:mental_health_score).and_return 1
        vispdat.family_member_tri_morbidity_answer = :family_member_tri_morbidity_answer_yes
      end
      it 'returns 1' do
        expect( vispdat.tri_morbidity_score ).to eq 1
      end
    end
    context 'when only physical_health_score = 1' do
      before(:each) { allow(vispdat).to receive(:physical_health_score).and_return 1 }
      it 'returns 0' do
        expect( vispdat.tri_morbidity_score ).to eq 0
      end
    end
    context 'when only substance_abuse_score = 1' do
      before(:each) { allow(vispdat).to receive(:substance_abuse_score).and_return 1 }
      it 'returns 0' do
        expect( vispdat.tri_morbidity_score ).to eq 0
      end
    end
    context 'when only mental_health_score = 1' do
      before(:each) { allow(vispdat).to receive(:mental_health_score).and_return 1 }
      it 'returns 0' do
        expect( vispdat.tri_morbidity_score ).to eq 0
      end
    end
    context 'when all 0' do
      it 'returns 0' do
        expect( vispdat.tri_morbidity_score ).to eq 0
      end
    end
  end

  describe 'medication_score' do
    context 'when not taking' do
      before(:each) { vispdat.medication_answer = :medication_answer_yes }
      it 'returns 1' do
        expect( vispdat.medication_score ).to eq 1
      end
    end
    context 'when selling' do
      before(:each) { vispdat.sell_answer = :sell_answer_yes }
      it 'returns 1' do
        expect( vispdat.medication_score ).to eq 1
      end
    end
    context 'when neither' do
      it 'returns 0' do
        expect( vispdat.medication_score ).to eq 0
      end
    end
  end

  describe 'abuse_and_trauma_score' do
    context 'when yes' do
      before(:each) { vispdat.trauma_answer = :trauma_answer_yes }
      it 'returns 1' do
        expect( vispdat.abuse_and_trauma_score ).to eq 1
      end
    end
    context 'when no' do
      it 'returns 0' do
        expect( vispdat.abuse_and_trauma_score ).to eq 0
      end
    end
  end

  describe 'family_legal_issue_score' do
    context 'when children removed' do
      before(:each) { vispdat.any_children_removed_answer = :any_children_removed_answer_yes }
      it 'returns 1' do
        expect( vispdat.family_legal_issues_score ).to eq 1
      end
    end
    context 'when family legal issues' do
      before(:each) { vispdat.any_family_legal_issues_answer = :any_family_legal_issues_answer_yes }
      it 'returns 1' do
        expect( vispdat.family_legal_issues_score ).to eq 1
      end
    end
    context 'when neither' do
      it 'returns 0' do
        expect( vispdat.family_legal_issues_score ).to eq 0
      end
    end
  end

  describe 'needs_of_children_score' do
    context 'when lived with' do
      before(:each) { vispdat.any_children_lived_with_family_answer = :any_children_lived_with_family_answer_yes }
      it 'returns 1' do
        expect( vispdat.needs_of_children_score ).to eq 1
      end
    end
    context 'when child abuse' do
      before(:each) { vispdat.any_child_abuse_answer = :any_child_abuse_answer_yes }
      it 'returns 1' do
        expect( vispdat.needs_of_children_score ).to eq 1
      end
    end
    context 'when not attending school' do
      before(:each) { vispdat.children_attend_school_answer = :children_attend_school_answer_no }
      it 'returns 1' do
        expect( vispdat.needs_of_children_score ).to eq 1
      end
    end
    context 'when neither' do
      it 'returns 0' do
        expect( vispdat.needs_of_children_score ).to eq 0
      end
    end
  end

  describe 'family_stability_score' do
    context 'when changed' do
      before(:each) { vispdat.family_members_changed_answer = :family_members_changed_answer_yes }
      it 'returns 1' do
        expect( vispdat.family_stability_score ).to eq 1
      end
    end
    context 'when other members' do
      before(:each) { vispdat.other_family_members_answer = :other_family_members_answer_yes }
      it 'returns 1' do
        expect( vispdat.family_stability_score ).to eq 1
      end
    end
    context 'when none' do
      it 'returns 0' do
        expect( vispdat.family_stability_score ).to eq 0
      end
    end
  end

  describe 'parental_engagement_score' do
    context 'when planned activities' do
      before(:each) { vispdat.planned_family_activities_answer = :planned_family_activities_answer_no }
      it 'returns 1' do
        expect( vispdat.parental_engagement_score ).to eq 1
      end
    end
    context 'when 13+ alone' do
      before(:each) { vispdat.time_spent_alone_13_answer = :time_spent_alone_13_answer_yes }
      it 'returns 1' do
        expect( vispdat.parental_engagement_score ).to eq 1
      end
    end
    context 'when 12 under alone' do
      before(:each) { vispdat.time_spent_alone_12_answer = :time_spent_alone_12_answer_yes }
      it 'returns 1' do
        expect( vispdat.parental_engagement_score ).to eq 1
      end
    end
    context 'when siblings help' do
      before(:each) { vispdat.time_spent_helping_siblings_answer = :time_spent_helping_siblings_answer_yes }
      it 'returns 1' do
        expect( vispdat.parental_engagement_score ).to eq 1
      end
    end
    context 'when none' do
      it 'returns 0' do
        expect( vispdat.parental_engagement_score ).to eq 0
      end
    end
  end

  describe 'section scoring' do
    before(:each) do
      [
        :dob_score,
        :family_size_score,
        :sleep_score,
        :homeless_score,
        :emergency_service_score,
        :risk_of_harm_score,
        :legal_issues_score,
        :risk_of_exploitation_score,
        :money_management_score,
        :meaningful_activity_score,
        :self_care_score,
        :social_relationship_score,
        :physical_health_score,
        :substance_abuse_score,
        :mental_health_score,
        :tri_morbidity_score,
        :medication_score,
        :abuse_and_trauma_score,
        :family_unit_score,
        :family_legal_issues_score,
        :needs_of_children_score,
        :family_stability_score,
        :parental_engagement_score
      ].each do |score|
        allow( vispdat ).to receive(score).and_return [0,1].sample
      end

      vispdat.calculate_score
    end

    describe 'pre_survey_score' do
      it 'is sum of 2 scores' do
        expect( vispdat.pre_survey_score ).to eq [
          vispdat.dob_score,
          vispdat.family_size_score
        ].sum
      end
    end

    describe 'history_score' do
      it 'is sum of 2 scores' do
        expect( vispdat.history_score ).to eq [
          vispdat.sleep_score,
          vispdat.homeless_score
        ].sum 
      end
    end

    describe 'risk_score' do
      it 'is sum of 4 scores' do
        expect( vispdat.risk_score ).to eq [
          vispdat.emergency_service_score,
          vispdat.risk_of_harm_score,
          vispdat.legal_issues_score,
          vispdat.risk_of_exploitation_score
        ].sum 
      end
    end

    describe 'social_score' do
      it 'is sum of 4 scores' do
        expect( vispdat.social_score ).to eq [
          vispdat.money_management_score,
          vispdat.meaningful_activity_score,
          vispdat.self_care_score,
          vispdat.social_relationship_score
        ].sum 
      end
    end

    describe 'wellness_score' do
      it 'is sum of 5 scores' do
        expect( vispdat.wellness_score ).to eq [    
          vispdat.physical_health_score,
          vispdat.substance_abuse_score,
          vispdat.mental_health_score,
          vispdat.tri_morbidity_score,
          vispdat.medication_score,
          vispdat.abuse_and_trauma_score
        ].sum 
      end
    end

    describe 'family_unit_score' do
      it 'is sum of 4 scores' do
        expect( vispdat.family_unit_score ).to eq [    
          vispdat.family_legal_issues_score,
          vispdat.needs_of_children_score,
          vispdat.family_stability_score,
          vispdat.parental_engagement_score
        ].sum 
      end
    end

    describe 'score' do
      it 'returns total of each section score' do
        expect( vispdat.score ).to eq [
          vispdat.pre_survey_score,
          vispdat.history_score,
          vispdat.risk_score,
          vispdat.social_score,
          vispdat.wellness_score,
          vispdat.family_unit_score
        ].sum
      end
    end
  end








end
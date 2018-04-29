require 'rails_helper'

RSpec.describe GrdaWarehouse::Vispdat::Individual, type: :model do
  ActiveJob::Base.queue_adapter = ActiveJob::QueueAdapters::DelayedJobAdapter
  let(:vispdat) { create :vispdat }

  describe 'youth?' do
    it 'returns false' do
      expect( vispdat.youth? ).to be false
    end
  end

  describe 'family?' do
    it 'returns false' do
      expect( vispdat.family? ).to be false
    end
  end

  describe 'individual?' do
    it 'returns true' do
      expect( vispdat.individual? ).to be true
    end
  end

  context 'when updated' do
    context 'and completed is set' do

      before(:each) do
        vispdat.update( submitted_at: Time.now )
      end

      it 'queues an email' do
        expect( Delayed::Job.count ).to eq 1
      end
      it 'queues a vispdat complete email' do
        expect( Delayed::Job.first.payload_object.job_data['arguments'] ).to include "NotifyUser", "vispdat_completed"
      end

    end

    describe 'and completed already set' do
      
      let(:vispat) { create :vispdat, completed: Time.now }

      before(:each) do
        vispdat.update( nickname: 'Joey' )
      end

      it 'does not queue an email' do
        expect( Delayed::Job.count ).to eq 0
      end
    end
  end

  let(:vispdat) { create :vispdat, score: 8 }

  let(:score_8) do
    allow_any_instance_of( GrdaWarehouse::Vispdat::Individual ).to receive(:calculate_score).and_return( 8 )
  end
  let(:homeless_gt_2_years) do
    allow_any_instance_of( GrdaWarehouse::Vispdat::Individual ).to receive(:days_homeless).and_return( 731 )
  end
  let(:homeless_1_year) do
    allow_any_instance_of( GrdaWarehouse::Vispdat::Individual ).to receive(:days_homeless).and_return( 365 )
  end

  describe 'priority_score' do

    context 'when score >= 8' do

      context 'and homeless > 2 years' do
        it 'is score + 730' do
          score_8
          homeless_gt_2_years
          vispdat
          expect( vispdat.priority_score ).to eq vispdat.score+730
        end
      end
      context 'and homeless 1..2 years' do
        it 'is score + 365' do
          score_8
          homeless_1_year
          vispdat
          expect( vispdat.priority_score ).to eq vispdat.score+365
        end
      end
    end

    context 'when score 0..7' do
      let(:vispdat) { create :vispdat, score: 7 }
      it 'is equal to score' do
        vispdat
        expect( vispdat.priority_score ).to eq vispdat.score
      end
    end

    context 'when score < 0' do
      let(:vispdat) { create :vispdat, score: -1 }
      it 'is 0' do
        expect( vispdat.priority_score ).to eq 0
      end
    end
  end

  describe 'dob_score' do
    context 'when client >= 60' do
      it 'returns 1' do
        allow( vispdat.client ).to receive(:age).and_return 61
        expect( vispdat.dob_score ).to eq 1
      end
    end
    context 'when client < 60' do
      it 'returns 0' do
        allow( vispdat.client ).to receive(:age).and_return 59
        expect( vispdat.dob_score ).to eq 0
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
    context 'when pregnant' do
      before(:each) { vispdat.pregnant_answer = :pregnant_answer_yes }
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
    context 'when all 3 return 1' do
      before(:each) do
        allow(vispdat).to receive(:physical_health_score).and_return 1
        allow(vispdat).to receive(:substance_abuse_score).and_return 1
        allow(vispdat).to receive(:mental_health_score).and_return 1
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

  describe 'section scoring' do
    before(:each) do
      [
        :dob_score,
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
        :abuse_and_trauma_score
      ].each do |score|
        allow( vispdat ).to receive(score).and_return [0,1].sample
      end

      vispdat.calculate_score
    end
    describe 'pre_survey_score' do
      it 'equals dob_score' do
        expect( vispdat.pre_survey_score ).to eq vispdat.dob_score
      end
    end

    describe 'history_score' do
      it 'is sum of sleep & homeless scores' do
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

    describe 'score' do
      it 'returns total of each section score' do
        expect( vispdat.score ).to eq [
          vispdat.pre_survey_score,
          vispdat.history_score,
          vispdat.risk_score,
          vispdat.social_score,
          vispdat.wellness_score
        ].sum
      end
    end
  end












end

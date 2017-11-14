require 'rails_helper'

RSpec.describe GrdaWarehouse::Vispdat, type: :model do
  
  let(:vispdat) { create :vispdat }

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
    allow_any_instance_of( GrdaWarehouse::Vispdat ).to receive(:calculate_score).and_return( 8 )
  end
  let(:homeless_gt_2_years) do
    allow_any_instance_of( GrdaWarehouse::Vispdat ).to receive(:days_homeless).and_return( 731 )
  end
  let(:homeless_1_year) do
    allow_any_instance_of( GrdaWarehouse::Vispdat ).to receive(:days_homeless).and_return( 365 )
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

end

require 'rails_helper'

RSpec.describe GrdaWarehouse::ClientFile, type: :model do

  describe 'Creating a client file' do
    let!(:consent_tag) { create :available_file_tag, consent_form: true, name: 'Consent Form', full: true }
    let!(:other_tag) { create :available_file_tag, consent_form: false, name: 'Other Tag' }
    let(:file) { create :client_file, effective_date: 5.days.ago }
    let(:second_file) { create :client_file, effective_date: 3.days.ago, client: file.client }
    let(:third_file) { create :client_file, effective_date: 1.days.ago, client: file.client }
    let(:config) { create :config }
    before :each do
      file.save!
    end
    it 'does not adjust the client consent_form_signed_on' do
      expect(file.client.consent_form_signed_on).to eq(nil)
    end
    describe 'when the file is tagged with a non-consent form tag' do
      before :each do
        file.tag_list.add(other_tag.name)
        file.save!
      end
      it "is tagged with 'Other Tag'" do
        expect(file.tag_list).to include(other_tag.name)
      end
      it 'does not adjust the client consent_form_signed_on' do
        expect(file.client.consent_form_signed_on).to eq(nil)
      end
    end
    describe 'when the file is tagged with a consent form tag' do
      before :each do
        file.tag_list.add consent_tag.name
        file.save!
      end

      it 'is tagged with a tag that constitutes a consent form' do
        expect(GrdaWarehouse::AvailableFileTag.contains_consent_form?(file.tag_list)).to be true
      end

      it 'sets client consent_form_signed_on' do
        expect(file.client.consent_form_signed_on).to eq(file.effective_date)
      end

      it 'client release is still not valid' do
        expect(file.client.consent_form_valid?).to be false      
      end

      describe 'when the consent file has been confirmed' do
        before :each do
          file.confirm_consent!
        end
        it 'client release becomes valid' do
          expect(file.client.consent_form_valid?).to be true
        end

        describe 'when a new consent form is uploaded that is not confirmed' do
          before :each do
            second_file.tag_list.add consent_tag.name
          end

          it 'is tagged with a tag that constitutes a consent form' do
            expect(GrdaWarehouse::AvailableFileTag.contains_consent_form?(second_file.tag_list)).to be true
          end

          it 'does not change the client consent_form_signed_on' do
            expect(second_file.client.consent_form_signed_on).to eq(file.effective_date)
          end
          describe 'when the new consent is confirmed' do
            before :each do
              second_file.confirm_consent!
            end
            it 'the client release remains valid' do
              expect(second_file.client.consent_form_valid?).to be true
            end
            it 'changes the client consent_form_signed_on' do
              expect(second_file.client.reload.consent_form_signed_on).to eq(second_file.effective_date)
            end
            describe 'when the new consent form is un-confirmed' do
              before :each do
                second_file.update(consent_form_confirmed: false)
              end
              it 'the client release remains valid' do
                expect(second_file.client.consent_form_valid?).to be true
              end
              describe 'when the new consent type is set to not signed' do
                before :each do
                  second_file.update(consent_type: nil)
                end
                it 'the client  release remains valid' do
                  expect(second_file.client.consent_form_valid?).to be true
                end
                describe 'when the original consent is un-confirmed' do
                  before :each do
                    file.update(consent_form_confirmed: false)
                  end
                  it 'the client release should no longer be valid' do
                    expect(file.client.consent_form_valid?).to be false
                  end           
                end
              end
            end
          end

        end

        # describe 'when a new consent form is uploaded that is confirmed' do
        #   before :each do 
            
        #   end
        #   it 'does changes the client consent_form_signed_on' do
        #     file.save!
        #     file.tag_list.add consent_tag.name
        #     file.save!
        #     file.reload
        #     second_file.tag_list.add consent_tag.name
        #     second_file.save!
        #     second_file.reload
        #     expect(file.client.consent_form_signed_on).to eq(file.effective_date)
        #   end
        # end
      end
    end
    
  end

end
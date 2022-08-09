require 'rails_helper'

RSpec.describe GrdaWarehouse::ClientFile, type: :model do
  describe 'Creating a client file' do
    let!(:consent_tag) { create :available_file_tag, consent_form: true, name: 'Consent Form', full_release: true }
    let!(:other_tag) { create :available_file_tag, consent_form: false, name: 'Other Tag' }
    let!(:file) { create :client_file, effective_date: 5.days.ago }
    let!(:second_file) { create :client_file, effective_date: 3.days.ago, client: file.client }
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

        it 'active release is set to the consent form' do
          expect(file.active_consent_form?).to be true
        end

        describe 'when a new non-consent form is uploaded' do
          before :each do
            second_file.tag_list.add(other_tag.name)
            second_file.save!
          end

          it 'does not invalidate the client consent' do
            expect(file.client.consent_form_valid?).to be true
          end
        end

        describe 'when a new consent form is uploaded that is not confirmed' do
          before :each do
            file.update(consent_form_confirmed: true)
            second_file.tag_list.add consent_tag.name
          end

          it 'is tagged with a tag that constitutes a consent form' do
            expect(GrdaWarehouse::AvailableFileTag.contains_consent_form?(second_file.tag_list)).to be true
          end

          it 'client release remains valid' do
            expect(file.client.consent_form_valid?).to be true
          end

          it 'active release is still set to the original consent form' do
            expect(file.active_consent_form?).to be true
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

            it 'active release is set to the new consent form' do
              expect(second_file.active_consent_form?).to be true
            end
            describe 'when the new consent form is un-confirmed' do
              before :each do
                second_file.update(consent_form_confirmed: false)
              end
              it 'the client release remains valid' do
                expect(second_file.client.consent_form_valid?).to be true
              end

              it 'the active release remains the same' do
                expect(second_file.active_consent_form?).to be true
              end

              describe 'when the original consent is un-confirmed' do
                before :each do
                  # rspec seems to get confused with all of the callbacks, this gets around that
                  second_file.update_columns(consent_form_confirmed: false)
                  file.update_columns(consent_form_confirmed: false)
                  # This usually gets called in a callback, but acts as taggable hates transactions
                  file.set_client_consent
                end
                it 'the client release should no longer be valid' do
                  expect(file.client.reload.consent_form_valid?).to be false
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

  describe 'visible_by scope for verified homeless history files' do
    GrdaWarehouse::Config.delete_all
    GrdaWarehouse::Config.first_or_create
    GrdaWarehouse::Config.update(verified_homeless_history_visible_to_all: true)
    GrdaWarehouse::Config.invalidate_cache
    # before do
    #   GrdaWarehouse::Config.delete_all
    #   GrdaWarehouse::Config.invalidate_cache
    # end
    let!(:user) { create :user }
    let!(:can_manage_client_files) { create :role, can_manage_client_files: true }
    let!(:can_manage_window_client_files) { create :role, can_manage_window_client_files: true }
    let(:config) { create :config }
    let!(:verified_homeless_tag) { create :available_file_tag, name: 'Homeless Verification', verified_homeless_history: true }
    let!(:file) { create :client_file }
    let!(:own_file) { create :client_file, user: user }

    before :each do
      # config.update(verified_homeless_history_visible_to_all: true)
      file.tag_list.add(verified_homeless_tag.name)
      file.save!
      own_file.tag_list.add(verified_homeless_tag.name)
      own_file.save!
    end

    describe 'when user can manage all files' do
      before :each do
        user.roles << can_manage_client_files
      end
      it 'can see own and others files' do
        visible_files = GrdaWarehouse::ClientFile.visible_by?(user)
        expect(visible_files.count).to eq(2)
      end
    end
    describe 'when user can manage window files' do
      before :each do
        user.roles << can_manage_window_client_files
      end
      describe 'and verified_homeless_history_method is not :release' do
        it 'can see own and others files' do
          visible_files = GrdaWarehouse::ClientFile.visible_by?(user)
          expect(visible_files.count).to eq(2) # got 1
        end
      end

      describe 'and verified_homeless_history_method is :release' do
        before :each do
          GrdaWarehouse::Config.update(verified_homeless_history_method: :release)
          GrdaWarehouse::Config.invalidate_cache
          # config.update(verified_homeless_history_method: :release)
        end
        describe 'and client does not have consent' do
          it 'can see own files' do
            visible_files = GrdaWarehouse::ClientFile.visible_by?(user)
            expect(visible_files.count).to eq(1)
            expect(visible_files.first.id).to eq(own_file.id)
          end
        end
        describe 'and client has consent in user\'s coc' do
          before :each do
            user.coc_codes = ['ZZ-999']
            client = file.client
            client.update(
              housing_release_status: client.class.full_release_string,
              consent_form_signed_on: 5.days.ago,
              consent_expires_on: Date.current + 1.years,
              consented_coc_codes: ['ZZ-999', 'AA-000'],
            )
          end
          it 'can see own and others files' do
            expect(GrdaWarehouse::Hud::Client.active_confirmed_consent_in_cocs(user.coc_codes).count).to eq(1)
            visible_files = GrdaWarehouse::ClientFile.visible_by?(user)
            expect(visible_files.count).to eq(2) # got 1
          end
        end
        describe 'and client has consent in different coc' do
          before :each do
            user.coc_codes = ['BB-000']
            client = file.client
            client.update(
              housing_release_status: client.class.full_release_string,
              consent_form_signed_on: 5.days.ago,
              consent_expires_on: Date.current + 1.years,
              consented_coc_codes: ['AA-000'],
            )
          end
          it 'can see own files' do
            expect(GrdaWarehouse::Hud::Client.active_confirmed_consent_in_cocs(user.coc_codes).count).to eq(0)
            visible_files = GrdaWarehouse::ClientFile.visible_by?(user)
            expect(visible_files.count).to eq(1)
            expect(visible_files.first.id).to eq(own_file.id)
          end
        end
        describe 'user does not have coc_codes assigned' do
          before :each do
            user.coc_codes = []
            client = file.client
            client.update(
              housing_release_status: client.class.full_release_string,
              consent_form_signed_on: 5.days.ago,
              consent_expires_on: Date.current + 1.years,
              consented_coc_codes: ['ZZ-999', 'AA-000'],
            )
          end
          it 'can see own files' do
            expect(GrdaWarehouse::Hud::Client.active_confirmed_consent_in_cocs(user.coc_codes).count).to eq(0)
            visible_files = GrdaWarehouse::ClientFile.visible_by?(user)
            expect(visible_files.count).to eq(1)
          end
        end
      end
    end
  end
end

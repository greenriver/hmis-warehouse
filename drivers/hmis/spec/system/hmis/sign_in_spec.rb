require 'rails_helper'
# require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.feature 'HMIS Sign In', type: :system do
  include_context 'hmis base setup'

  let!(:ds1) { create(:hmis_data_source, hmis: 'hmis-warehouse-web.nginx-proxy') }

  # context "When not signed in" do
  #   it "shows sign-in form" do
  #     visit "/"
  #     expect(page).to have_content 'Sign In'
  #   end
  # end

  context 'When signed in' do
    let(:user) { create(:user) }
    before(:each) { sign_in(user) }

    it 'Loads client search' do
      expect(page).to have_content 'Clients'
    end

    context 'and signed out' do
      before(:each) { sign_out }
      it 'shows sign-in form' do
        expect(page).to have_content 'Sign In'
      end
    end
  end
end

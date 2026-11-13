###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Content Security Policy', type: :request do
  subject(:csp_header) { response.headers['Content-Security-Policy'] }

  before { get root_path }

  it 'is present in the response headers' do
    expect(response.headers).to have_key('Content-Security-Policy')
  end

  it 'is not in report-only mode' do
    expect(response.headers).not_to have_key('Content-Security-Policy-Report-Only')
  end

  it 'contains the default-src directive' do
    expect(csp_header).to include("default-src 'self'")
  end

  it 'contains key directives to prevent common attacks' do
    expect(csp_header).to include("object-src 'none'")
    expect(csp_header).to include("base-uri 'self'")
  end

  it 'includes script-src and style-src directives' do
    expect(csp_header).to include('script-src')
    expect(csp_header).to include('style-src')
  end

  it 'does not allow unsafe-inline in script-src' do
    script_src = csp_header[/script-src[^;]*/]
    expect(script_src).not_to include('unsafe-inline')
  end

  it 'does not allow unsafe-eval in script-src' do
    script_src = csp_header[/script-src[^;]*/]
    expect(script_src).not_to include('unsafe-eval')
  end

  it 'includes a nonce source in script-src' do
    expect(csp_header).to match(/script-src[^;]*'nonce-[A-Za-z0-9+\/]+=*'/)
  end

  it 'issues a different nonce for each request' do
    first_nonce = csp_header[/nonce-([A-Za-z0-9+\/=]+)/, 1]

    get root_path
    second_nonce = response.headers['Content-Security-Policy'][/nonce-([A-Za-z0-9+\/=]+)/, 1]

    expect(second_nonce).not_to eq(first_nonce)
  end

  describe 'inline script nonces on an authenticated, converted application view' do
    let(:user) { create(:acl_user) }
    let(:cohort) { create(:cohort) }
    let(:cohort_role) { create(:cohort_manager) }
    let(:all_cohorts_collection) { Collection.system_collection(:cohorts) }

    before do
      Collection.maintain_system_groups
      setup_access_control(user, cohort_role, all_cohorts_collection)
      allow(CasAccess::Tag).to receive(:available_cohort_tags).and_return([])
      sign_in user
      get edit_cohort_path(cohort)
    end

    it "gives the page's own inline script (not just layout boilerplate) the current request's nonce" do
      header_nonce = response.headers['Content-Security-Policy'][/nonce-([A-Za-z0-9+\/=]+)/, 1]
      page_scripts = Capybara.string(response.body).all('script[nonce]', visible: :all)
      page_script = page_scripts.find { |el| el.text(:all).include?('minicolors') }

      expect(page_script).not_to be_nil
      expect(page_script['nonce']).to eq(header_nonce)
    end
  end

  describe 'inline script nonces' do
    it 'renders inline <script> tags whose nonce matches the CSP header nonce' do
      header_nonce = response.headers['Content-Security-Policy'][/nonce-([A-Za-z0-9+\/=]+)/, 1]
      script_nonces = Capybara.string(response.body).all('script[nonce]', visible: :all).map { |el| el['nonce'] }

      expect(script_nonces).not_to be_empty
      expect(script_nonces.uniq).to eq([header_nonce])
    end

    it 'exposes the current nonce to client-side JS before loading application.js' do
      header_nonce = response.headers['Content-Security-Policy'][/nonce-([A-Za-z0-9+\/=]+)/, 1]

      expect(response.body).to include("window.CSP_NONCE = \"#{header_nonce}\"")
      nonce_relay_position = response.body.index('window.CSP_NONCE')
      application_js_match = response.body.match(/<script src="\/assets\/application-[^"]*\.js"/)
      application_js_position = application_js_match&.begin(0)

      expect(nonce_relay_position).not_to be_nil
      expect(application_js_position).not_to be_nil
      expect(nonce_relay_position).to be < application_js_position
    end
  end
end

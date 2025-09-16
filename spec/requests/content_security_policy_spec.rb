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
end

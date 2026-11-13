###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WardenProxyFactory, type: :model do
  let!(:user) { create(:acl_user) }
  let!(:role) { create(:role, can_view_all_reports: true) }
  let!(:collection) { create(:collection) }

  before do
    setup_access_control(user, role, collection)
  end

  describe '.build' do
    it 'answers the :user scope with the user it was built for' do
      proxy = described_class.build(user)

      expect(proxy.user(:user)).to eq(user)
      expect(proxy.authenticated?(:user)).to be true
    end

    it 'answers no user for a scope it was not built for' do
      proxy = described_class.build(user)

      expect(proxy.user(:hmis_user)).to be_nil
    end
  end

  describe "a document export rendered through the rack 'warden' key, the only channel it has" do
    let(:export) do
      GrdaWarehouse::WarehouseReports::DocumentExports::ActiveClientReportExport.new(user_id: user.id)
    end
    let(:rendered_html) { [] }

    before do
      # Stubbing stops at PdfGenerator.render_pdf, which needs a headless-Chrome binary. Stub
      # PdfGenerator.html too and the spec still passes while rendering nothing through the proxy.
      allow(PdfGenerator).to receive(:render_pdf) do |html|
        rendered_html << html
        '%PDF-'
      end
      allow(PdfGenerator).to receive(:merge_inline_pdfs) { |pdfs| Array.wrap(pdfs).join }
    end

    it 'renders the report for the user the export runs as' do
      export.perform

      expect(rendered_html.first).to include(ERB::Util.html_escape(user.name_with_email))
    end

    it 'completes the export' do
      export.perform

      expect(export.status).to eq(DocumentExportBehavior::COMPLETED_STATUS)
      expect(export.file_data).to be_present
    end
  end

  describe 'the render sites' do
    let(:offenders) do
      paths = Dir.glob(
        [
          Rails.root.join('{app,lib,spec}/**/*.rb'),
          Rails.root.join('drivers/*/{app,lib,spec}/**/*.rb'),
        ],
      ) - [Rails.root.join('app/models/warden_proxy_factory.rb').to_s, __FILE__]

      paths.sort.flat_map do |path|
        File.readlines(path).each_with_index.
          reject { |line, _index| line.lstrip.start_with?('#') }.
          select { |line, _index| line.match?(pattern) }.
          map { |_line, index| "#{Pathname.new(path).relative_path_from(Rails.root)}:#{index + 1}" }
      end
    end

    describe 'a Warden::Proxy built outside the factory' do
      let(:pattern) { /\bWarden::Proxy\.new/ }

      it 'is nowhere' do
        expect(offenders).to be_empty, <<~MSG
          Warden loads only in the :devise bundler group, so this raises NameError under
          AUTH_METHOD=jwt:

          #{offenders.join("\n")}

          Call WardenProxyFactory.renderer_env(user) instead.
        MSG
      end
    end

    describe "a rack 'warden' env key spelled outside the factory" do
      let(:pattern) { /['"]warden['"]\s*=>/ }

      it 'is nowhere' do
        expect(offenders).to be_empty, <<~MSG
          The 'warden' key name is WardenProxyFactory's contract with Idp::JwtCurrentUser, which
          reads the proxy back out of the rack env:

          #{offenders.join("\n")}

          Pass WardenProxyFactory.renderer_env(user) to ActionController::Renderer.new instead.
        MSG
      end
    end
  end
end

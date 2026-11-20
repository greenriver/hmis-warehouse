###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AssetHelper, type: :helper do
  # read_asset returns nil for a stylesheet it cannot resolve, which would satisfy the
  # @import assertions below with no css at all. The smallest inlined stylesheet is ~91KB.
  minimum_size = 50_000

  describe '.wicked_pdf_stylesheet_link_tag' do
    # Sass does not inline an @import written with an explicit .css extension; it emits
    # a plain `@import url(...)` instead. A browser resolves that over HTTP, but a
    # stylesheet inlined into a <style> tag for PDF rendering cannot, so the imported
    # rules are dropped. Import vendor css without the extension.
    #
    # Assertions match against extracts rather than the stylesheet itself to keep
    # failure output small.

    # Stylesheets named literally in a call to inline_stylesheet_link_tag. The example
    # below fails if this list drifts from the call sites.
    inlined_for_pdf = ['dashboard_pdf', 'application', 'print', 'roi_pdf'].freeze

    it 'covers every stylesheet named literally in a call to inline_stylesheet_link_tag' do
      paths = Dir.glob(Rails.root.join('{app,drivers,lib,config}/**/*.{haml,erb,rb}'))
      named = paths.flat_map { |path| File.read(path).scan(/inline_stylesheet_link_tag\(?\s*['"]([^'"]+)['"]/) }

      expect(named.flatten.uniq.sort).to eq(inlined_for_pdf.sort)
    end

    inlined_for_pdf.each do |stylesheet|
      it "has no unresolved @import in #{stylesheet}.css" do
        css = described_class.wicked_pdf_stylesheet_link_tag(stylesheet)

        expect(css.bytesize).to be > minimum_size
        expect(css.scan(/@import\s+url\([^)]*\)/)).to be_empty
      end
    end

    # Without `fill: none` billboard.js line series render as filled polygons, and
    # without a grid stroke the gridlines are invisible. These assert the declarations
    # rather than the selectors, so dropping a declaration is still a failure.
    it 'inlines the billboard.js declarations' do
      css = described_class.wicked_pdf_stylesheet_link_tag('dashboard_pdf')

      expect(css[/\.bb path,\s*\.bb line\s*\{[^}]*fill:\s*none/]).to be_present
      expect(css[/\.bb-grid line\s*\{[^}]*stroke:/]).to be_present
    end

    # The theme declares its variables on a grouped selector; there is no bare
    # `.ag-theme-balham {}` rule.
    it 'inlines the ag-grid theme declarations' do
      css = described_class.wicked_pdf_stylesheet_link_tag('application')

      expect(css[/\.ag-theme-balham[^{]*\{[^}]*--ag-balham-active-color:/]).to be_present
    end
  end

  # Staging runs with config.assets.compile = false, where an asset missing from the
  # manifest raises instead of rendering.
  it 'precompiles every asset named literally in a call that inlines assets' do
    calls = /(inline_javascript_include_tag|inline_stylesheet_link_tag|inline_asset_base64|AssetHelper\.asset_content|AssetHelper\.read_asset)\(?\s*['"]([^'"]+)['"]/
    paths = Dir.glob(Rails.root.join('{app,drivers}/**/*.{haml,erb,rb}'))
    named = paths.flat_map { |path| File.read(path).scan(calls) }.map do |call, name|
      next name if File.extname(name).present?

      call == 'inline_stylesheet_link_tag' ? "#{name}.css" : "#{name}.js"
    end.uniq

    # Guards against the regex silently matching nothing.
    expect(named).to include('hud_report_pdf_autoscale.js', 'dashboard_pdf.css', 'theme/open_path.svg', 'icons.ttf')
    expect(named.reject { |name| Rails.application.asset_precompiled?(name) }).to be_empty
  end

  describe 'reading assets outside development and test' do
    let(:manifest_dir) { Dir.mktmpdir }
    let(:manifest_assets) { { 'pdf.js' => 'pdf-0123.js', 'theme/open_path.svg' => 'theme/open_path-0123.svg' } }

    before do
      File.write(File.join(manifest_dir, 'pdf-0123.js'), 'precompiled pdf.js')
      FileUtils.mkdir_p(File.join(manifest_dir, 'theme'))
      File.write(File.join(manifest_dir, 'theme/open_path-0123.svg'), '<svg>precompiled</svg>')
      File.write(File.join(manifest_dir, ".sprockets-manifest-#{'0' * 32}.json"), { files: {}, assets: manifest_assets }.to_json)
      allow(Rails.application).to receive(:assets_manifest).and_return(Sprockets::Manifest.new(nil, manifest_dir))
    end

    after { FileUtils.remove_entry(manifest_dir) }

    context 'with assets.compile on (production)' do
      before { allow(Rails).to receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new('production')) }

      it 'reads a precompiled asset from the manifest instead of compiling it' do
        expect(described_class.read_asset('pdf.js')).to eq('precompiled pdf.js')
      end

      it 'compiles an asset missing from the manifest' do
        compiled = Rails.application.assets.find_asset('application.js', base_path: Rails.root.to_s).to_s

        expect(described_class.read_asset('application.js')).to eq(compiled)
      end
    end

    context 'with assets.compile off (staging)' do
      before do
        allow(Rails).to receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new('staging'))
        allow(Rails.application).to receive(:assets).and_return(nil)
      end

      it 'reads a precompiled asset from the manifest' do
        expect(described_class.read_asset('pdf.js')).to eq('precompiled pdf.js')
      end

      it 'raises for an asset missing from the manifest' do
        expect { described_class.read_asset('application.js') }.
          to raise_error(Sprockets::Rails::Helper::AssetNotFound, /application\.js/)
      end

      it 'base64-encodes a precompiled image with its content type' do
        expected = "data:image/svg+xml;base64,#{Rack::Utils.escape(Base64.strict_encode64('<svg>precompiled</svg>'))}"

        expect(described_class.wicked_pdf_asset_base64('theme/open_path.svg')).to eq(expected)
      end

      it 'returns the digest path from the manifest' do
        expect(described_class.digest_path('pdf.js')).to eq('pdf-0123.js')
      end
    end

    context 'with assets.compile off (staging) and the real PDF stylesheets precompiled' do
      let(:stylesheets) { ['application.css', 'print.css', 'dashboard_pdf.css', 'roi_pdf.css'] }
      let(:manifest_assets) { stylesheets.to_h { |name| [name, name.sub('.', '-0123.')] } }

      before do
        manifest_assets.each do |name, digest_path|
          File.write(File.join(manifest_dir, digest_path), Rails.application.assets.find_asset(name, base_path: Rails.root.to_s).to_s)
        end
        allow(Rails).to receive(:env).and_return(ActiveSupport::EnvironmentInquirer.new('staging'))
        allow(Rails.application).to receive(:assets).and_return(nil)
      end

      it 'inlines each stylesheet, resolving every url() it references' do
        inlined = stylesheets.to_h { |name| [name, described_class.wicked_pdf_stylesheet_link_tag(name)] }

        expect(inlined.values).to all(start_with("<style type='text/css'>"))
        expect(inlined['application.css']).to include('url(#default#VML)')
      end
    end
  end
end

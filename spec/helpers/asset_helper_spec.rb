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
    # below fails if this list drifts from the call sites. layouts/pdf_with_map also
    # inlines theme/styles/*.scss through a local variable, which cannot be derived
    # statically; that glob currently matches only a sass partial, which sprockets does
    # not serve.
    inlined_for_pdf = ['dashboard_pdf', 'application', 'print', 'roi_pdf', 'health_flex_services_pdf'].freeze

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
end

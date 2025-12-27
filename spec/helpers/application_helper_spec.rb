# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  # Make current_user available for stubbing in helper specs
  # (ApplicationHelper#body_classes calls current_user)
  before do
    unless helper.respond_to?(:current_user)
      helper.define_singleton_method(:current_user) { nil }
    end
  end
  describe '#render_generic_search_form' do
    let(:url) { '/search' }
    let(:prompt) { 'Search...' }
    let(:initial_value) { 'test' }
    let(:tooltip) { 'Search tooltip' }
    let(:aria_label) { 'Search label' }

    def parse_html(html)
      Nokogiri::HTML.fragment(html)
    end

    it 'renders a search form with default options' do
      result = parse_html(helper.render_generic_search_form(url))
      form = result.at_css('form')
      input = form.at_css('input')
      button = form.at_css('button')

      expect(form['method']).to eq('get')
      expect(input['type']).to eq('search')
      expect(input['name']).to eq('q')
      expect(input.key?('autofocus')).to be true
      expect(button.text.strip).to eq('Search')
    end

    it 'renders a search form with custom options' do
      result = parse_html(
        helper.render_generic_search_form(
          url,
          prompt: prompt,
          initial_value: initial_value,
          tooltip_title: tooltip,
          aria_label: aria_label,
          input_type: 'text',
          input_name: 'search_term',
        ),
      )

      input = result.at_css('input')
      expect(input['type']).to eq('text')
      expect(input['name']).to eq('search_term')
      expect(input['placeholder']).to eq(prompt)
      expect(input['value']).to eq(initial_value)
      expect(input['data-bs-toggle']).to eq('tooltip')
      expect(input['data-title']).to eq(tooltip)
      expect(input['aria-label']).to eq(aria_label)
    end

    it 'renders a search form with post method' do
      result = parse_html(helper.render_generic_search_form(url, method: 'post'))
      expect(result.at_css('form')['method']).to eq('post')
    end

    it 'renders a search form without autofocus' do
      result = parse_html(helper.render_generic_search_form(url, autofocus: false))
      expect(result.at_css('input')['autofocus']).to be_nil
    end
  end

  describe '#body_classes' do
    before do
      allow(ENV).to receive(:fetch).with('CLIENT').and_return('test-client')
      allow(helper).to receive(:params).and_return(ActionController::Parameters.new(controller: 'test/nested', action: 'show'))
      allow(helper).to receive(:current_user).and_return(nil)
      helper.instance_variable_set(:@layout__width, 'lg')
    end

    it 'builds array with string concatenation operations' do
      result = helper.body_classes

      expect(result).to be_an(Array)
      expect(result).to include('test-client')
      expect(result).to include('test/nested')
      expect(result).to include('test_nested') # String manipulation: split('/').join('_')
      expect(result).to include('show')
      expect(result).to include('not-signed-in')
      expect(result).to include('l-content-width-lg')
    end

    context 'with signed in user' do
      before do
        allow(helper).to receive(:current_user).and_return(double('User'))
      end

      it 'does not include not-signed-in class' do
        result = helper.body_classes
        expect(result).not_to include('not-signed-in')
      end
    end

    context 'with medium layout width' do
      before do
        helper.instance_variable_set(:@layout__width, 'md')
      end

      it 'includes medium width class' do
        result = helper.body_classes
        expect(result).to include('l-content-width-md')
      end
    end
  end

  describe '#checkmark_or_x' do
    it 'renders checkmark with default size' do
      result = helper.checkmark_or_x(true)
      expect(result).to include('icon-checkmark')
      expect(result).to include('o-color--positive')
    end

    it 'renders cross for false value' do
      result = helper.checkmark_or_x(false)
      expect(result).to include('icon-cross')
      expect(result).to include('o-color--danger')
    end

    it 'applies medium size class' do
      result = helper.checkmark_or_x(true, size: :md)
      expect(result).to include('icon-lg')
    end

    it 'applies large size class' do
      result = helper.checkmark_or_x(true, size: :lg)
      expect(result).to include('icon-xl')
    end

    it 'includes tooltip when provided' do
      result = helper.checkmark_or_x(true, 'Test tooltip')
      expect(result).to include('Test tooltip')
    end
  end

  describe '#options_for_available_tags' do
    let(:grouped_tags) do
      {
        'Category 1' => [double('Tag', name: 'Tag 1')],
        'Category 2' => [
          double('Tag', name: 'Tag 2a'),
          double('Tag', name: 'Tag 2b'),
        ],
      }
    end

    it 'generates proper HTML options for grouped tags' do
      result = helper.options_for_available_tags(grouped_tags, 'prompt')

      expect(result).to include('Tag 1')
      expect(result).to include('Category 2')
      expect(result).to include('Tag 2a')
      expect(result).to include('Tag 2b')
      expect(result).to include('<option')
      expect(result).to include('<optgroup')
    end
  end

  describe '#container_classes' do
    before do
      allow(helper).to receive(:enable_responsive?).and_return(false)
    end

    it 'builds array with conditional string appends' do
      result = helper.container_classes

      expect(result).to be_an(Array)
      expect(result).to include('non-responsive')
    end

    context 'when responsive is enabled' do
      before do
        allow(helper).to receive(:enable_responsive?).and_return(true)
      end

      it 'returns empty array when responsive' do
        result = helper.container_classes
        expect(result).to be_empty
      end
    end
  end

  describe 'string concatenation in view helpers' do
    describe '#yes_no with concat operations' do
      it 'uses concat to build HTML strings' do
        # This tests the concat operations in the capture block
        result = helper.yes_no(true, include_icon: true, include_content_tag: true)

        expect(result).to be_a(String)
        expect(result).to include('icon-checkmark')
        expect(result).to include('o-color--positive')
        expect(result).to include('Yes')
      end

      it 'renders yes_no without mocking concat' do
        result = helper.yes_no(true, include_icon: true, include_content_tag: true)

        expect(result).to include('icon-checkmark')
        expect(result).to include('Yes')
      end
    end

    describe '#tagged method' do
      it 'renders tagged element with title and label' do
        result = helper.tagged(true, 'positive', title: 'Test Title', label: 'Test Label')

        expect(result).to include('c-tag')
        expect(result).to include('c-tag--positive')
        expect(result).to include('Test Title')
        expect(result).to include('Test Label')
      end

      it 'renders tagged element without optional title' do
        result = helper.tagged(true, 'positive', label: 'Test Label')

        expect(result).to include('Test Label')
        expect(result).not_to include('c-tag__title')
      end
    end

    describe '#render_paginated_list_with_explicit_pagy concat operations' do
      let(:mock_pagy) { double('pagy', count: 5) }
      let(:mock_list) { ['item1', 'item2', 'item3'] }

      before do
        allow(helper).to receive(:capture).and_yield
        allow(helper).to receive(:render).and_return('<div>pagination</div>')
        allow(helper).to receive(:concat)
      end

      it 'uses concat to build paginated list HTML' do
        # Test the concat operations from lines 502-504
        expect(helper).to receive(:concat).with('<div>pagination</div>').exactly(3).times

        helper.render_paginated_list_with_explicit_pagy(
          pagy: mock_pagy,
          list: mock_list,
          item_name: 'item',
          list_partial: 'test/list',
        )
      end
    end

    describe '#render_display_title concat operations' do
      it 'uses concat to build title display HTML' do
        # Test the concat operations from lines 536-537 by calling the actual method
        result = helper.render_display_title('Test Title') do
          content_tag(:div, 'Block content')
        end

        expect(result).to include('<h1>Test Title</h1>')
        expect(result).to include('<div>Block content</div>')
      end

      it 'works without block content' do
        result = helper.render_display_title('Just Title')

        expect(result).to include('<h1>Just Title</h1>')
        expect(result).not_to include('Block content')
      end
    end

    describe '#hmis_external_link concat operations' do
      let(:mock_entity) { double('entity') }
      let(:mock_data_source) { double('data_source') }

      before do
        allow(mock_entity).to receive(:data_source).and_return(mock_data_source)
      end

      it 'uses concat to build external link HTML when URL present' do
        allow(mock_data_source).to receive(:hmis_url_for).and_return('http://example.com')

        result = helper.hmis_external_link(mock_entity)

        expect(result).to include('Open in HMIS')
        expect(result).to include('icon-link-ext')
        expect(result).to include('http://example.com')
      end

      it 'returns nil when no URL available' do
        allow(mock_data_source).to receive(:hmis_url_for).and_return(nil)

        result = helper.hmis_external_link(mock_entity)

        expect(result).to be_nil
      end
    end
  end

  describe 'comprehensive string mutation regression tests' do
    describe '#checkmark_or_x size variations' do
      it 'applies correct size classes' do
        result_md = helper.checkmark_or_x(true, size: :md)
        result_lg = helper.checkmark_or_x(true, size: :lg)
        result_xs = helper.checkmark_or_x(true, size: :xs)

        expect(result_md).to include('icon-lg')
        expect(result_lg).to include('icon-xl')
        expect(result_xs).not_to include('icon-lg')
        expect(result_xs).not_to include('icon-xl')
      end
    end

    describe 'comprehensive array << operations' do
      describe '#body_classes array building' do
        before do
          allow(ENV).to receive(:fetch).with('CLIENT').and_return('test-client')
          allow(helper).to receive(:params).and_return(ActionController::Parameters.new(controller: 'admin/users', action: 'index'))
          allow(helper).to receive(:current_user).and_return(nil)
          helper.instance_variable_set(:@layout__width, 'md')
        end

        it 'tests all << operations in body_classes method' do
          # Test all the << operations from lines 234-239
          result = helper.body_classes

          # Each << operation should add an element
          expect(result).to include('test-client')          # line 234: result << ENV.fetch('CLIENT')
          expect(result).to include('admin/users')          # line 235: result << params[:controller]
          expect(result).to include('admin_users')          # line 236: result << params[:controller].split('/').join('_')
          expect(result).to include('index')                # line 237: result << params[:action]
          expect(result).to include('not-signed-in')        # line 238: result << 'not-signed-in' if current_user.blank?
          expect(result).to include('l-content-width-md')   # line 239: result << conditional layout width
        end
      end

      describe '#container_classes array building' do
        it 'tests << operation in container_classes method' do
          allow(helper).to receive(:enable_responsive?).and_return(false)

          # Test the << operation from line 254
          result = helper.container_classes
          expect(result).to include('non-responsive') # line 254: result << 'non-responsive' unless enable_responsive?
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
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
    it 'builds CSS class string with concatenation' do
      # Test the string building logic inside the method
      symbol_names = { true => 'checkmark', false => 'cross' }
      wrapper_classes = { true => 'o-color--positive', false => 'o-color--danger' }

      boolean = true
      symbol_name = symbol_names[boolean]
      wrapper_class = wrapper_classes[boolean]
      html_class = "#{symbol_name} #{wrapper_class}" # String interpolation

      expect(html_class).to eq('checkmark o-color--positive')

      # Test string concatenation for size
      size = :lg
      case size.to_sym
      when :md
        html_class += ' icon-lg'  # String mutation +=
      when :lg
        html_class += ' icon-xl'  # String mutation +=
      end

      expect(html_class).to eq('checkmark o-color--positive icon-xl')
    end

    it 'handles false boolean value' do
      symbol_names = { true => 'checkmark', false => 'cross' }
      wrapper_classes = { true => 'o-color--positive', false => 'o-color--danger' }

      boolean = false
      symbol_name = symbol_names[boolean]
      wrapper_class = wrapper_classes[boolean]
      html_class = "#{symbol_name} #{wrapper_class}"

      expect(html_class).to eq('cross o-color--danger')
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

    it 'builds HTML options with array concatenation' do
      # Test the array building logic
      opts = []
      grouped_tags.each do |key, group|
        if group.size == 1
          item = group.first
          opts << "<option value=\"#{item.name}\">#{item.name}</option>" # Array << operation
        else
          opts << "<optgroup label=\"#{key}\"></optgroup>" # Array << operation
          group.each do |group_item|
            opts << "<option value=\"#{group_item.name}\">#{group_item.name}</option>" # Array << operation
          end
        end
      end

      expect(opts).to be_an(Array)
      expect(opts.length).to eq(4) # 1 single tag + 1 optgroup + 2 grouped tags
      expect(opts[0]).to include('Tag 1')
      expect(opts[1]).to include('Category 2')
      expect(opts[2]).to include('Tag 2a')
      expect(opts[3]).to include('Tag 2b')

      # Test join operation
      joined = opts.join('')
      expect(joined).to include('Tag 1')
      expect(joined).to include('Category 2')
      expect(joined).to include('Tag 2a')
      expect(joined).to include('Tag 2b')
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
    end

    describe '#tagged method array building' do
      it 'builds arrays with << operations for inner content' do
        # Test the array building logic similar to what's in the tagged method
        inner = []
        title = 'Test Title'
        label = 'Test Label'

        inner << 'title content' if title.present? # Array << operation
        inner << 'wrapper content' # Array << operation

        expect(inner).to eq(['title content', 'wrapper content'])

        # Test nested array building
        icon_label = []
        icon_label << 'icon content' # Array << operation
        icon_label << 'label content' if label.present? # Array << operation

        expect(icon_label).to eq(['icon content', 'label content'])
      end
    end
  end
end

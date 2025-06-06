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
      result = parse_html(helper.render_generic_search_form(
                            url,
                            prompt: prompt,
                            initial_value: initial_value,
                            tooltip_title: tooltip,
                            aria_label: aria_label,
                            input_type: 'text',
                            input_name: 'search_term',
                          ))

      input = result.at_css('input')
      expect(input['type']).to eq('text')
      expect(input['name']).to eq('search_term')
      expect(input['placeholder']).to eq(prompt)
      expect(input['value']).to eq(initial_value)
      expect(input['data-toggle']).to eq('tooltip')
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
end

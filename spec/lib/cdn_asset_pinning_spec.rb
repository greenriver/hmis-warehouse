###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'CDN assets with integrity hashes' do
  view_globs = ['app/views/**/*.{haml,erb}', 'drivers/*/app/views/**/*.{haml,erb}']
  view_lines = view_globs.flat_map { |glob| Rails.root.glob(glob) }.sort.flat_map do |path|
    relative_path = path.relative_path_from(Rails.root).to_s
    path.each_line.with_index(1).map { |line, number| { location: "#{relative_path}:#{number}", text: line } }
  end

  # Match http(s) only: some SRI hashes contain '//'.
  integrity_urls = view_lines.select { |line| line[:text].include?('integrity') }.flat_map do |line|
    line[:text].scan(/https?:\/\/[^\s'"]+/).map { |url| { location: line[:location], url: url } }
  end

  it 'pins every CDN URL that has an integrity hash to an exact version' do
    offenders = integrity_urls.reject { |entry| entry[:url].match?(/\d+\.\d+\.\d+/) }.map { |entry| "#{entry[:location]} #{entry[:url]}" }

    expect(offenders).to eq([])
  end

  it 'finds the pinned tags it checks' do
    expect(integrity_urls.map { |entry| entry[:url] }).to include('https://cdn.jsdelivr.net/npm/billboard.js@3.18.0/dist/billboard.min.js')
  end

  it 'allows every pinned CDN script in the CSP script-src' do
    allowed = Rails.application.config.content_security_policy.script_src
    offenders = integrity_urls.select { |entry| entry[:url].end_with?('.js') }.
      reject { |entry| allowed.any? { |source| entry[:url].start_with?(source.to_s) } }.
      map { |entry| "#{entry[:location]} #{entry[:url]}" }

    expect(offenders).to eq([])
  end

  it 'keeps an integrity hash on every CDN d3 script' do
    offenders = view_lines.select { |line| line[:text].include?('cdn.jsdelivr.net/npm/d3@') && !line[:text].include?('integrity') }.
      map { |line| line[:location] }

    expect(offenders).to eq([])
  end

  it 'loads no scripts from the d3js.org moving aliases' do
    offenders = view_lines.select { |line| line[:text].include?('d3js.org/d3.v') }.map { |line| line[:location] }

    expect(offenders).to eq([])
  end
end

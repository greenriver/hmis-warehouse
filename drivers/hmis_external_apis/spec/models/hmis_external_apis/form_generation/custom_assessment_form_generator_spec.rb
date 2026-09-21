###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisExternalApis::FormGeneration::CustomAssessmentFormGenerator, type: :model do
  # Smoke test: a couple of CSV rows in, one JSON form definition out, with the expected shape.
  describe '#call' do
    it 'builds a form definition JSON file from CSV rows' do
      Dir.mktmpdir do |dir|
        csv_path = File.join(dir, 'source.csv')
        output_dir = File.join(dir, 'generated')
        overlay_path = File.join(dir, 'overlay.yml')

        File.write(csv_path, <<~CSV)
          form_definition_identifier,legacy_assessment_name,form_group_name,link_id,label,key,form_item_type,pick_list_options
          test_form,Test Assessment,,q1,First Question,test_form_q1,STRING,
          test_form,Test Assessment,,q2,Second Question,test_form_q2,CHOICE,Yes|No
        CSV

        result = described_class.call(csv_path: csv_path, output_dir: output_dir, overlay_path: overlay_path)

        expect(result[:success]).to eq(true)
        expect(result[:validator_errors]).to be_empty

        document = JSON.parse(File.read(File.join(output_dir, 'test_form.json')))
        expect(document['name']).to eq('Test Assessment')

        items = document['item'].sole['item']
        # For a single-group form, "Assessment Date" is inserted first in that group.
        expect(items[0]).to include('type' => 'DATE', 'assessment_date' => true)
        expect(items[1]).to include(
          'type' => 'STRING',
          'link_id' => 'q1',
          'text' => 'First Question',
          'mapping' => { 'custom_field_key' => 'test_form_q1' },
        )
        expect(items[2]).to include(
          'type' => 'CHOICE',
          'link_id' => 'q2',
          'text' => 'Second Question',
          'mapping' => { 'custom_field_key' => 'test_form_q2' },
          'pick_list_options' => [{ 'code' => 'Yes' }, { 'code' => 'No' }],
        )

        expect(File.exist?(overlay_path)).to eq(true)
      end
    end

    it 'gives multi-group forms a leading "Details" group holding just the assessment date' do
      Dir.mktmpdir do |dir|
        csv_path = File.join(dir, 'source.csv')
        output_dir = File.join(dir, 'generated')
        overlay_path = File.join(dir, 'overlay.yml')

        File.write(csv_path, <<~CSV)
          form_definition_identifier,legacy_assessment_name,form_group_name,link_id,label,key,form_item_type,pick_list_options
          test_form,Test Assessment,Section A,q1,First Question,test_form_q1,STRING,
          test_form,Test Assessment,Section B,q2,Second Question,test_form_q2,STRING,
        CSV

        result = described_class.call(csv_path: csv_path, output_dir: output_dir, overlay_path: overlay_path)

        expect(result[:success]).to eq(true)
        document = JSON.parse(File.read(File.join(output_dir, 'test_form.json')))
        groups = document['item']

        expect(groups.size).to eq(3)
        expect(groups[0]).to include('type' => 'GROUP', 'text' => 'Details')
        expect(groups[0]['item'].sole).to include('type' => 'DATE', 'assessment_date' => true)
        expect(groups[1]).to include('text' => 'Section A')
        expect(groups[1]['item'].map { |i| i['link_id'] }).to eq(['q1'])
        expect(groups[2]).to include('text' => 'Section B')
        expect(groups[2]['item'].map { |i| i['link_id'] }).to eq(['q2'])
      end
    end

    it 'warns and falls back to STRING for an unrecognized form_item_type' do
      Dir.mktmpdir do |dir|
        csv_path = File.join(dir, 'source.csv')
        output_dir = File.join(dir, 'generated')
        overlay_path = File.join(dir, 'overlay.yml')

        File.write(csv_path, <<~CSV)
          form_definition_identifier,legacy_assessment_name,form_group_name,link_id,label,key,form_item_type,pick_list_options
          test_form,Test Assessment,,q1,First Question,test_form_q1,MULTISELECT,
        CSV

        result = described_class.call(csv_path: csv_path, output_dir: output_dir, overlay_path: overlay_path)

        expect(result[:warnings].map(&:kind)).to include(:unrecognized_type)
        document = JSON.parse(File.read(File.join(output_dir, 'test_form.json')))
        item = document['item'].sole['item'][1]
        expect(item['type']).to eq('STRING')
        expect(item['_comment']).to match(/"MULTISELECT" not recognized/)
      end
    end

    it 'skips rows with a blank form_definition_identifier' do
      Dir.mktmpdir do |dir|
        csv_path = File.join(dir, 'source.csv')
        output_dir = File.join(dir, 'generated')
        overlay_path = File.join(dir, 'overlay.yml')

        File.write(csv_path, <<~CSV)
          form_definition_identifier,legacy_assessment_name,form_group_name,link_id,label,key,form_item_type,pick_list_options
          ,Stray Row,,q0,Stray Question,stray_q0,STRING,
          test_form,Test Assessment,,q1,First Question,test_form_q1,STRING,
        CSV

        result = described_class.call(csv_path: csv_path, output_dir: output_dir, overlay_path: overlay_path)

        expect(result[:success]).to eq(true)
        expect(Dir.glob(File.join(output_dir, '*.json')).map { |f| File.basename(f, '.json') }).to eq(['test_form'])
      end
    end

    context 'with zip: true' do
      it 'also writes a timestamped zip of the generated JSON' do
        Dir.mktmpdir do |dir|
          csv_path = File.join(dir, 'source.csv')
          output_dir = File.join(dir, 'generated')
          overlay_path = File.join(dir, 'overlay.yml')

          File.write(csv_path, <<~CSV)
            form_definition_identifier,legacy_assessment_name,form_group_name,link_id,label,key,form_item_type,pick_list_options
            test_form,Test Assessment,,q1,First Question,test_form_q1,STRING,
          CSV

          result = described_class.call(csv_path: csv_path, output_dir: output_dir, overlay_path: overlay_path, zip: true)

          expect(result[:zip_path]).to be_present
          expect(File.exist?(result[:zip_path])).to eq(true)
          expect(File.basename(result[:zip_path])).to match(/\A\d{14}_custom_forms\.zip\z/)
        end
      end
    end
  end
end

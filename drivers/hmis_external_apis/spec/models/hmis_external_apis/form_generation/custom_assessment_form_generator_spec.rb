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

    it 'adds no question_order warnings when the CSV has no question_order column' do
      Dir.mktmpdir do |dir|
        csv_path = File.join(dir, 'source.csv')
        output_dir = File.join(dir, 'generated')
        overlay_path = File.join(dir, 'overlay.yml')

        File.write(csv_path, <<~CSV)
          form_definition_identifier,legacy_assessment_name,form_group_name,link_id,label,key,form_item_type,pick_list_options
          test_form,Test Assessment,Section A,q1,First Question,test_form_q1,STRING,
          test_form,Test Assessment,,q2,"If yes, source",test_form_q2,STRING,
          test_form,Test Assessment,Section A,q3,Any income?,test_form_q3,CHOICE,Yes|No
        CSV

        result = described_class.call(csv_path: csv_path, output_dir: output_dir, overlay_path: overlay_path)

        expect(result[:warnings].map(&:kind)).not_to include(:split_group, :enable_when_parent_missing)
        document = JSON.parse(File.read(File.join(output_dir, 'test_form.json')))
        expect(document['item'].drop(1).map { |group| group['text'] }).to eq(['Section A', 'Additional Questions', 'Section A'])
      end
    end

    context 'with a question_order column' do
      let(:header) { 'form_definition_identifier,legacy_assessment_name,form_group_name,link_id,label,key,form_item_type,pick_list_options,question_order' }

      # Each row is [link_id, question_order] or [link_id, question_order, label, group, type, options].
      def generate(rows, overlay_yaml: nil)
        Dir.mktmpdir do |dir|
          csv_path = File.join(dir, 'source.csv')
          output_dir = File.join(dir, 'generated')
          overlay_path = File.join(dir, 'overlay.yml')
          File.write(overlay_path, overlay_yaml) if overlay_yaml

          lines = rows.map do |link_id, order, label, group, type, options|
            CSV.generate_line(['test_form', 'Test Assessment', group, link_id, label || "Question #{link_id}", "test_form_#{link_id}", type || 'STRING', options, order])
          end
          File.write(csv_path, "#{header}\n#{lines.join}")

          result = described_class.call(csv_path: csv_path, output_dir: output_dir, overlay_path: overlay_path)
          document = JSON.parse(File.read(File.join(output_dir, 'test_form.json')))
          [result, document]
        end
      end

      def question_items(document)
        document['item'].flat_map { |group| group['item'] }.reject { |item| item['assessment_date'] }
      end

      def question_link_ids(document)
        question_items(document).map { |item| item['link_id'] }
      end

      it 'orders questions by question_order instead of CSV row order' do
        _result, document = generate([['q1', '3'], ['q2', '1'], ['q3', '2']])

        expect(question_link_ids(document)).to eq(['q2', 'q3', 'q1'])
      end

      it 'compares question_order as a number, including decimals' do
        _result, document = generate([['q1', '2.7'], ['q2', '2.3'], ['q3', '10'], ['q4', '2']])

        expect(question_link_ids(document)).to eq(['q4', 'q2', 'q1', 'q3'])
      end

      it 'keeps CSV row order for rows with the same question_order' do
        _result, document = generate([['q1', '1', '3. C'], ['q2', '1', '1. A'], ['q3', '1', '2. B']])

        expect(question_link_ids(document)).to eq(['q1', 'q2', 'q3'])
      end

      it 'puts rows with a blank question_order after ordered rows, in CSV order' do
        _result, document = generate([['q1', ''], ['q2', '2'], ['q3', ''], ['q4', '1']])

        expect(question_link_ids(document)).to eq(['q4', 'q2', 'q1', 'q3'])
      end

      it 'warns and treats a non-numeric question_order as blank' do
        result, document = generate([['q1', 'n/a'], ['q2', '0x10'], ['q3', '1_0'], ['q4', 'Infinity'], ['q5', '1']])

        expect(question_link_ids(document)).to eq(['q5', 'q1', 'q2', 'q3', 'q4'])
        invalid = result[:warnings].select { |warning| warning.kind == :invalid_question_order }
        expect(invalid.map(&:link_id)).to eq(['q1', 'q2', 'q3', 'q4'])
        expect(invalid.map(&:label)).to eq(['q1', 'q2', 'q3', 'q4'])
      end

      it 'falls back to label-number ordering when every question_order is blank' do
        _result, document = generate([['q1', '', '2. B'], ['q2', '', '1. A'], ['q3', '', '3. C']])

        expect(question_link_ids(document)).to eq(['q2', 'q1', 'q3'])
      end

      it 'applies overlay item_order moves after question_order' do
        overlay = { 'forms' => { 'test_form' => { 'item_order' => { 'Section A' => { 'q1' => { 'after' => 'q3' } } } } } }.to_yaml
        _result, document = generate(
          [['q3', '3', nil, 'Section A'], ['q1', '1', nil, 'Section A'], ['q2', '2', nil, 'Section A']],
          overlay_yaml: overlay,
        )

        expect(question_link_ids(document)).to eq(['q2', 'q3', 'q1'])
      end

      it 'emits a split group and warns when question_order interleaves groups' do
        result, document = generate([['q1', '1', nil, 'Section A'], ['q3', '3', nil, 'Section A'], ['q2', '2']])

        groups = document['item'].drop(1)
        expect(groups.map { |group| group['text'] }).to eq(['Section A', 'Additional Questions', 'Section A'])
        expect(groups.map { |group| group['link_id'] }.uniq.size).to eq(3)
        split = result[:warnings].select { |warning| warning.kind == :split_group }
        expect(split.map(&:label)).to eq(['Section A'])
      end

      it 'warns when a follow-up is ordered before its parent' do
        result, document = generate(
          [['q1', '2', 'Any income?', nil, 'CHOICE', 'Yes|No'], ['q2', '1', 'If yes, source']],
        )

        follow_up = question_items(document).find { |item| item['link_id'] == 'q2' }
        expect(follow_up).not_to have_key('enable_when')
        missing = result[:warnings].select { |warning| warning.kind == :enable_when_parent_missing }
        expect(missing.map(&:link_id)).to eq(['q2'])
      end

      it 'infers enable_when for a follow-up ordered after its parent' do
        result, document = generate(
          [['q1', '1', 'Any income?', nil, 'CHOICE', 'Yes|No'], ['q2', '2', 'If yes, source']],
        )

        follow_up = question_items(document).find { |item| item['link_id'] == 'q2' }
        expect(follow_up['enable_when']).to eq([{ 'question' => 'q1', 'operator' => 'EQUAL', 'answer_code' => 'Yes' }])
        expect(result[:warnings].map(&:kind)).not_to include(:enable_when_parent_missing)
      end

      it 'does not warn about a follow-up-style label when the form has no matching choice question' do
        result, document = generate([['q1', '1', 'Any notes?'], ['q2', '2', 'Please describe the notes']])

        expect(question_link_ids(document)).to eq(['q1', 'q2'])
        expect(result[:warnings].map(&:kind)).not_to include(:enable_when_parent_missing)
      end

      it 'does not warn when the only Other choice question is the follow-up itself' do
        result, document = generate(
          [['q1', '1', 'Please specify type', nil, 'CHOICE', 'Other|Something']],
        )

        expect(question_link_ids(document)).to eq(['q1'])
        expect(result[:warnings].map(&:kind)).not_to include(:enable_when_parent_missing)
      end

      it 'does not warn about an Other-style follow-up when the form only has a Yes/No choice question' do
        result, document = generate(
          [['q1', '1', 'Any income?', nil, 'CHOICE', 'Yes|No'], ['q2', '2', 'Please describe']],
        )

        follow_up = question_items(document).find { |item| item['link_id'] == 'q2' }
        expect(follow_up).not_to have_key('enable_when')
        expect(result[:warnings].map(&:kind)).not_to include(:enable_when_parent_missing)
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

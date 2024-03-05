require 'nokogiri'

# Quick and dirty builder class to assist with complex assessments. Manages CDEDS, link-ids
#
# Example:
#   class MyAssessmentFormDefinitionBuilder < HmisUtil::CustomAssessmentFormDefinitionBuilder
#      def perform
#       form_definition = Hmis::Form::Definition.find(my_id)
#       content = build_content(prefix: 'my-assessment') do
#         JSON.parse({ item: [ assessment_group_1, ...]
#       end
#       HmisUtil::JsonForms.new.validate_definition(content)
#       form_definition.definition = content
#       form_definition.save!
#     end
#
#     def assessment_group_1
#       new_group_item(
#         title: 'My input group',
#         children: [
#           new_integer_question(title: 'Apples', cded: register_cded(key: 'apples')),
#           new_integer_question(title: 'Oranges', cded: register_cded(key: 'oranges')),
#         ],
#       )
#     end
#   end

class HmisUtil::CustomAssessmentFormDefinitionBuilder
  attr_accessor :registered_cdeds

  GROUP_TYPE = 'GROUP'.freeze
  BOOLEAN_TYPE = 'BOOLEAN'.freeze
  CHOICE_TYPE = 'CHOICE'.freeze
  CURRENCY_TYPE = 'CURRENCY'.freeze
  DATE_TYPE = 'DATE'.freeze
  DISPLAY_TYPE = 'DISPLAY'.freeze
  FILE_TYPE = 'FILE'.freeze
  IMAGE_TYPE = 'IMAGE'.freeze
  INTEGER_TYPE = 'INTEGER'.freeze
  OBJECT_TYPE = 'OBJECT'.freeze
  OPEN_CHOICE_TYPE = 'OPEN_CHOICE'.freeze
  STRING_TYPE = 'STRING'.freeze
  TEXT_TYPE = 'TEXT'.freeze

  def next_link_id
    @next_link_id ||= 0
    @next_link_id += 1
    "#{@prefix}-#{@next_link_id}"
  end

  module Items
    class BaseItem
      attr_writer :link_id
      attr_accessor :cded, :extra_attrs
      def initialize(attributes = {})
        attributes.each do |name, value|
          send("#{name}=", value)
        end
      end

      def link_id
        if respond_to?(:cded)
          cded&.key || @link_id
        else
          @link_id
        end
      end

      def as_json(...)
        result = super(...).compact_blank.transform_keys do |key|
          case key
          when 'title', 'content'
            'text'
          when 'children'
            'item'
          when 'choices'
            'pick_list_options'
          else
            key
          end
        end
        result.filter! { |k, _v| k !~ /\A_/ } # skip internal vars such as @_foo

        cded = result.delete('cded')
        if cded
          result['mapping'] = {
            'custom_field_key' => cded['key'],
          }
        end
        extra = result.delete('extra_attrs')
        result = extra ? result.merge(extra) : result
        result.merge({ 'type' => type, 'link_id' => link_id })
      end
    end

    class GroupItem < BaseItem
      attr_accessor :title, :children, :component
      def type
        GROUP_TYPE
      end
    end

    class DisplayItem < BaseItem
      attr_accessor :content, :visible_when_read_only
      def type
        DISPLAY_TYPE
      end

      def as_json(...)
        super(...).tap do |result|
          result.delete('visible_when_read_only')
          result['readonly_text'] = '' unless visible_when_read_only
        end
      end
    end

    class AutofillSumItem < DisplayItem
      attr_accessor :content, :sum_questions
      def type
        DISPLAY_TYPE
      end

      def as_json(...)
        super(...).tap do |result|
          result['autofill_values'] = [
            {
              'autofill_readonly' => false,
              'autofill_behavior' => 'ANY',
              'autofill_when' => [],
              'sum_questions' => result.delete('sum_questions'),
            },
          ]
          result['initial'] = [
            {
              'initial_behavior' => 'IF_EMPTY',
              'value_number' => 0,
            },
          ]
        end
      end
    end

    class AssessmentDateItem < BaseItem
      attr_accessor :title, :assessment_date, :autofill_values, :required
      def type
        DATE_TYPE
      end

      def as_json(...)
        super(...).tap do |result|
          result['mapping'] = { 'field_name' => 'assessmentDate' }
        end
      end
    end

    class SelectItem < BaseItem
      attr_accessor :title, :choices, :component, :required
      def type
        CHOICE_TYPE
      end

      def add_choice(code:, label: nil)
        @_seen ||= Set.new
        raise "already seen #{code} in #{link_id}" if code.in?(@_seen)

        @_seen.add(code)

        choice = { code: code, label: label }.compact_blank

        self.choices ||= []
        self.choices.push(choice)
      end
    end

    class PicklistItem < BaseItem
      attr_accessor :title, :pick_list_reference, :component, :required
      def type
        CHOICE_TYPE
      end

      def as_json(...)
        super(...).tap do |result|
          result['component'] = component.nil? ? 'RADIO_BUTTONS_VERTICAL' : component
        end
      end
    end

    class ScoreItem < BaseItem
      attr_accessor :title, :choices, :component, :required
      def type
        CHOICE_TYPE
      end

      def add_score_choice(score:, help:, label: nil)
        @_seen ||= Set.new
        raise "already seen #{score} in #{link_id}" if score.in?(@_seen)

        @_seen.add(score)

        label ||= "Score: #{score}"
        code = "#{cded.key}_#{score}"
        choice = { code: code, label: label, numeric_value: score, helper_text: help }.compact_blank

        self.choices ||= []
        self.choices.push(choice)
      end

      def as_json(...)
        super(...).tap do |result|
          result['component'] = 'RADIO_BUTTONS_VERTICAL'
          result['required'] = required.nil? ? true : required
        end
      end
    end

    class TextItem < BaseItem
      attr_accessor :title, :component, :required
      def type
        TEXT_TYPE
      end

      def as_json(...)
        super(...).tap do |result|
          result['required'] = required.nil? ? true : required
        end
      end
    end

    class IntegerItem < BaseItem
      attr_accessor :title, :component, :required
      def type
        INTEGER_TYPE
      end

      def as_json(...)
        super(...).tap do |result|
          result['required'] = required.nil? ? true : required
        end
      end
    end
  end

  module Html
    def self.validate(html_fragment)
      doc = Nokogiri::HTML::DocumentFragment.parse(html_fragment)
      doc.to_html
      # rescue Nokogiri::HTML::SyntaxError
    end

    List = Struct.new(:title, :items, keyword_init: true) do
      def to_s
        html_title = title ? "<div>#{title}</div>" : nil
        "#{html_title}<ul>#{items.map { |l| "<li>#{l}</li>" }.join}</ul>"
      end

      def as_json(...)
        to_s
      end
    end
  end

  def new_date_question(...)
    Items::AssessmentDateItem.new(...).tap do |item|
      item.link_id = next_link_id
    end
  end

  def new_group_item(...)
    Items::GroupItem.new(...).tap do |item|
      item.link_id = next_link_id
    end
  end

  def new_display_item(...)
    Items::DisplayItem.new(...).tap do |item|
      item.link_id = next_link_id
    end
  end

  def new_text_question(...)
    Items::TextItem.new(...)
  end

  def new_integer_question(...)
    Items::IntegerItem.new(...)
  end

  def new_score_question(...)
    Items::ScoreItem.new(...)
  end

  def new_select_question(...)
    Items::SelectItem.new(...)
  end

  def new_score_display(...)
    Items::AutofillSumItem.new(...)
  end

  def new_yes_no_question(...)
    Items::PicklistItem.new(...).tap do |item|
      item.pick_list_reference = 'NoYes'
    end
  end

  def new_list(...)
    Html.validate(Html::List.new(...).to_s)
  end

  def new_html(content)
    Html.validate(content&.to_s)
  end

  def register_cded(...)
    cded = Hmis::Hud::CustomDataElementDefinition.new(...)
    cded.key = "#{@prefix}_#{cded.key}"
    raise 'must have key' unless cded.key
    raise "already registered key #{cded.key}" if registered_cdeds.key?(cded.key)

    cded.field_type ||= 'string'
    cded.owner_type ||= Hmis::Hud::CustomAssessment.sti_name
    cded.label ||= cded.key.humanize
    registered_cdeds[cded.key] = cded.attributes.compact_blank
    cded
  end

  def data_source
    @data_source ||= GrdaWarehouse::DataSource.hmis.first!
  end

  def system_hud_user
    @system_hud_user ||= Hmis::Hud::User.system_user(data_source_id: data_source.id)
  end

  def system_user
    @system_user ||= Hmis::User.system_user
  end

  def build_content(prefix:)
    @prefix = prefix
    self.registered_cdeds = {}
    content = yield
    scope = Hmis::Hud::CustomDataElementDefinition.where(data_source_id: data_source.id)
    registered_cdeds.each_value do |attrs|
      cded = scope.where(
        key: attrs.fetch('key'),
        owner_type: attrs.fetch('owner_type'),
      ).first_or_initialize
      cded.user ||= system_hud_user
      cded.attributes = attrs
      cded.save!
    end
    content
  end
end

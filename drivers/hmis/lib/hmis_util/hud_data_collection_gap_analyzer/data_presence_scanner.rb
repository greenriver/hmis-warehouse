###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisUtil
  class HudDataCollectionGapAnalyzer
    # Answers "does real data exist for this project?" using COUNT/MIN/MAX only.
    class DataPresenceScanner
      include ArelHelper

      Presence = Struct.new(:count, :earliest, :latest, keyword_init: true) do
        def any?
          count.positive?
        end
      end

      EMPTY = Presence.new(count: 0, earliest: nil, latest: nil).freeze
      DATA_NOT_COLLECTED = 99
      DATE_COLUMNS = {
        income_benefits: :InformationDate,
        disabilities: :InformationDate,
        health_and_dvs: :InformationDate,
        employment_educations: :InformationDate,
        youth_education_statuses: :InformationDate,
        current_living_situations: :InformationDate,
        services: :DateProvided,
        enrollments: :EntryDate,
        exits: :ExitDate,
      }.freeze

      attr_reader :project, :date_range

      # @param project [GrdaWarehouse::Hud::Project]
      # @param date_range [Range<Date>]
      def initialize(project:, date_range:)
        @project = project
        @date_range = date_range
      end

      # Cached by the query the element resolves to rather than by the element itself: the
      # same HUD field recurs across intake, update, annual and exit, and nothing in the
      # query depends on which assessment role it came from.
      #
      # @param element [Element]
      # @return [Presence]
      def field_presence(element)
        key = [element.association_name, element.disability_type, element.column, element.item_type]
        field_presence_cache[key] ||= compute_field_presence(element)
      end

      # @param association_name [Symbol]
      # @return [Presence]
      def table_presence(association_name)
        aggregate(base_scope(association_name), association_name)
      end

      # Presence of a single column, rather than an entire sub-record -- for fields that
      # live directly on an association's own table (e.g. Enrollment.MoveInDate) instead of
      # a scannable sub-record.
      #
      # @param association_name [Symbol]
      # @param column [Symbol]
      # @return [Presence]
      def column_presence(association_name, column, coded: false)
        scope = base_scope(association_name)
        arel_col = scope.klass.arel_table[column]
        condition = arel_col.not_eq(nil)
        condition = condition.and(arel_col.not_eq(DATA_NOT_COLLECTED)) if coded
        aggregate(scope.where(condition), association_name)
      end

      # @return [Hash{Integer => Presence}] keyed by HUD Service RecordType
      def service_presence_by_record_type
        scope = base_scope(:services)
        column = date_arel_column(scope, :services)
        scope.
          group(:RecordType).
          pluck(:RecordType, Arel.star.count, nf('MIN', [column]), nf('MAX', [column])).
          to_h do |record_type, count, earliest, latest|
            [record_type, Presence.new(count: count, earliest: earliest, latest: latest)]
          end
      end

      protected

      def field_presence_cache
        @field_presence_cache ||= {}
      end

      def compute_field_presence(element)
        scope = base_scope(element.association_name)
        scope = scope.where(DisabilityType: element.disability_type) if element.disability?
        aggregate(scope.where(real_data_condition(element)), element.association_name)
      end

      def base_scope(association_name)
        project.public_send(association_name).where(DATE_COLUMNS.fetch(association_name) => date_range)
      end

      def aggregate(scope, association_name)
        column = date_arel_column(scope, association_name)
        count, earliest, latest = scope.pick(Arel.star.count, nf('MIN', [column]), nf('MAX', [column]))
        return EMPTY if count.nil? || count.zero?

        Presence.new(count: count, earliest: earliest, latest: latest)
      end

      def date_arel_column(scope, association_name)
        scope.klass.arel_table[DATE_COLUMNS.fetch(association_name)]
      end

      # @param element [Element]
      # @return [Arel::Nodes::Node]
      def real_data_condition(element)
        column = arel_column(element)
        condition = column.not_eq(nil)
        condition = condition.and(column.not_eq(DATA_NOT_COLLECTED)) if element.coded?
        condition = condition.and(column.not_eq('')) if element.free_text?
        condition
      end

      def arel_column(element)
        element.model_name.constantize.arel_table[element.column]
      end
    end
  end
end

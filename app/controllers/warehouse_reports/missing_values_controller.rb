###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class MissingValuesController < ApplicationController
    include WarehouseReportAuthorization
    POTENTIAL_COLUMNS = (
      GrdaWarehouse::Hud::Client.column_names + GrdaWarehouse::Hud::Enrollment.column_names
    ).reject { |n| n =~ /^date|(?<![a-z])(?:id|date)$/i }.sort.freeze

    DEFAULT_COLUMNS = [
      'FirstName',
      'LastName',
      'SSN',
      'SSNQuality',
      'DOB',
      'Ethnicity',
      'VeteranStatus',
      'DisablingCondition',
      'LivingSituation',
      'LastPermanentZIP',
    ] & POTENTIAL_COLUMNS

    COLUMN_TO_AREL = POTENTIAL_COLUMNS.map do |c|
      t = [GrdaWarehouse::Hud::Client, GrdaWarehouse::Hud::Enrollment].detect do |table|
        table.column_names.include? c
      end
      [c, t.arel_table[c.to_sym]]
    end.to_h.with_indifferent_access.freeze

    SOURCES = ['all', 'data_source', 'organization', 'project'].map(&:humanize).map(&:titleize).freeze

    def index
      report_params = { user: current_user }
      report_params.merge!(query_params[:q]) if params[:q]
      @query = MissingValuesQuery.new(**report_params.symbolize_keys)
      @query.valid? # this initializes the object so simple form will render it correctly
      respond_to :html, :xlsx
    end

    def query_params
      params.permit(
        q: [
          :source,
          :data_source,
          :organization,
          :project,
          columns: [],
        ],
      )
    end
    helper_method :query_params

    # all the rather involved query logic lives in this class
    class MissingValuesQuery < ModelForm
      include ArelHelper

      attribute :source, String, default: SOURCES.first
      attribute :columns, Array[String], default: DEFAULT_COLUMNS
      attribute :data_source,  Integer, lazy: true, default: ->(s, _) { s.all_sources[:data_sources].first.last }
      attribute :organization, Integer, lazy: true, default: ->(s, _) { s.all_sources[:organizations].first.last }
      attribute :project,      Integer, lazy: true, default: ->(s, _) { s.all_sources[:projects].first.last }
      attribute :user

      validates :columns, presence: true
      validates :source, inclusion: { in: SOURCES }, allow_blank: false
      validates :data_source, presence: true, if: ->(o) { o.source == 'Data Source' }
      validates :organization, presence: true, if: ->(o) { o.source == 'Organization' }
      validates :project, presence: true, if: ->(o) { o.source == 'Project' }
      validate do
        if (oddballs = columns - possible_columns).any?
          errors.add :columns, "Unfamiliar fields: #{oddballs.sort.to_sentence}."
        end
      end

      def columns
        @columns.select(&:present?)
      end

      def client_column?(column)
        GrdaWarehouse::Hud::Client.column_names.include?(column.to_s)
      end

      def enrollment_column?(column)
        GrdaWarehouse::Hud::Enrollment.column_names.include?(column.to_s)
      end

      def client_columns
        @client_columns ||= columns.select { |c| client_column? c }
      end

      def enrollment_columns
        @enrollment_columns ||= columns.select { |c| enrollment_column? c }
      end

      def all_missing_clients_field_key
        'All Client Fields Missing'
      end

      def all_missing_enrollments_field_key
        'All Enrollment Fields Missing'
      end

      def all_clients_key
        'All Clients'
      end

      def all_enrollments_key
        'All Enrollments'
      end

      # collects all desired counts, providing also a fraction of the total where appropriate
      # these are sorted for display
      def counts
        @counts ||= client_counts.merge(enrollment_counts).map do |k, v|
          value = if all_missing_clients_field_key == k || all_missing_enrollments_field_key == k || COLUMN_TO_AREL[k]
            denominator = if all_missing_clients_field_key == k || COLUMN_TO_AREL[k] && client_column?(k)
              denominator = client_counts[all_clients_key]
            elsif all_missing_enrollments_field_key == k || enrollment_column?(k)
              denominator = enrollment_counts[all_enrollments_key]
            else
              raise 'we should never get here'
            end
            if denominator.to_f.zero?
              { na: true }
            else
              { fraction: v.to_f / denominator }
            end
          else
            { counts_present: true } # if we aren't looking for a denominator, the number is one of the denominators we look for
          end
          [k, value.merge(total: v)]
        end.sort do |(ak, _), (bk, _)|
          # put client stuff before enrollment stuff
          # put all-x stuff before particular column info
          # otherwise, sort alphabetically
          ac, bc = [ak, bk].map { |k| COLUMN_TO_AREL[k].present? && client_column?(k) || [all_clients_key, all_missing_clients_field_key].include?(k) }
          if ac ^ bc
            ac ? -1 : 1
          elsif COLUMN_TO_AREL[ak] && COLUMN_TO_AREL[bk]
            ak <=> bk
          elsif ac   # both client-related
            ac, bc = [ak, bk].map { |k| COLUMN_TO_AREL[k].present? }
            if ac || bc
              ac ? 1 : -1
            elsif ak == all_clients_key
              -1
            else
              1
            end
          else       # both enrollment-related
            ac, bc = [ak, bk].map { |k| COLUMN_TO_AREL[k].present? }
            if ac || bc
              ac ? 1 : -1
            elsif ak == all_enrollments_key
              -1
            else
              1
            end
          end
        end.to_h
      end

      def source_name
        case source
        when 'All'
          'all sources'
        when 'Data Source'
          all_sources[:data_sources].detect { |_n, i| i == data_source }.first
        when 'Organization'
          all_sources[:organizations].detect { |_n, i| i == organization }.first
        when 'Project'
          all_sources[:projects].detect { |_n, i| i == project }.first
        end
      end

      def source_id
        case source
        when 'Data Source'
          data_source
        when 'Organization'
          organization
        when 'Project'
          project
        end
      end

      def possible_sources
        SOURCES
      end

      def possible_columns
        POTENTIAL_COLUMNS
      end

      def possible_client_columns
        possible_columns.select { |c| client_column? c }
      end

      def possible_enrollment_columns
        possible_columns.select { |c| enrollment_column? c }
      end

      def default_columns
        DEFAULT_COLUMNS
      end

      # grab in all the necessary names and ids to make the form and queries
      # returns map from type keys to maps from names to ids: { type: { name: id } }
      # rubocop:disable Lint/ShadowingOuterLocalVariable
      def all_sources
        @all_sources ||= begin
          st = data_sources.arel_table
          ot = organizations.arel_table
          pt = projects.arel_table

          scope = data_sources.importable.joins(organizations: :projects).merge(projects.viewable_by(user))
          scope = scope.merge(organizations.non_confidential) unless user.can_view_confidential_project_names?
          scope = scope.merge(projects.non_confidential) unless user.can_view_confidential_project_names?
          scope = scope.select(st[:id], st[:name], st[:short_name], ot[:id], ot[:OrganizationName], pt[:id], pt[:ProjectName])
          sql = scope.to_sql

          rows = data_sources.connection.select_rows sql

          ds = rows.uniq { |id, _| id }.map { |id, name| [name, id.to_i] }.sort_by(&:first).to_h

          orgs = rows.uniq { |_, _, _, id| id }.group_by { |_, _, _, _, name| name }
          orgs = orgs.flat_map do |_name, rows|
            if rows.many?
              rows.map do |_, _, ds, id, name|
                ["#{name} < #{ds}", id.to_i]
              end
            else
              rows.map do |_, _, _, id, name|
                [name, id.to_i]
              end
            end
          end.sort_by(&:first).to_h

          projs = rows.uniq { |_, _, _, _, _, id| id }.group_by(&:last)
          projs = projs.flat_map do |_name, rows|
            if rows.many?
              rows.group_by { |_, _, ds, _, _, _, name| [ds, name] }.flat_map do |(ds, name), rows|
                if rows.many?
                  rows.map do |_, _, _, _, org, id|
                    ["#{name} < #{org} < #{ds}", id.to_i]
                  end
                else
                  rows.map do |_, _, _, _, _, id|
                    ["#{name} < . < #{ds}", id.to_i]
                  end
                end
              end
            else
              rows.map do |_, _, _, _, _, id, name|
                [name, id.to_i]
              end
            end
          end.sort_by(&:first).to_h
          {
            data_sources: ds,
            organizations: orgs,
            projects: projs,
          }
        end
      end
      # rubocop:enable Lint/ShadowingOuterLocalVariable

      private

      def organizations
        GrdaWarehouse::Hud::Organization
      end

      def data_sources
        GrdaWarehouse::DataSource
      end

      def projects
        GrdaWarehouse::Hud::Project
      end

      def client_scope
        GrdaWarehouse::Hud::Client.source
      end

      def make_count(arel, aka)
        nf('COUNT', [acase([[arel, 1]])]).as(aka)
      end

      def ct
        GrdaWarehouse::Hud::Client.arel_table
      end

      def et
        GrdaWarehouse::Hud::Enrollment.arel_table
      end

      def normalize_hash(h) # rubocop:disable Naming/MethodParameterName
        h = h.to_a.first
        h.transform_keys { |k| k.tr('_', ' ') }.with_indifferent_access
      end

      def client_counts
        @client_counts ||= if client_columns.any?
          cols = COLUMN_TO_AREL.slice(*client_columns).values
          s = if needs_distinct?
            client_ids = scope.distinct.pluck(:id)
            client_scope.where(id: client_ids)
          else
            client_scope
          end
          if cols.many?
            first_q = cols.first.eq nil
            union = cols[1..].reduce(first_q) { |c1, c2| c1.and(c2.eq nil) }
            s = s.select make_count(union, all_missing_clients_field_key.tr(' ', '_'))
          end
          s = s.select(*cols.map { |c| make_count(c.eq(nil), c.name.to_s) })
          s = s.select nf('COUNT', [ct[:id]]).as(all_clients_key.tr(' ', '_'))
          normalize_hash s.connection.select_all(s.to_sql)
        else
          {}
        end
      end

      def enrollment_counts
        @enrollment_counts ||= if enrollment_columns.any?
          cols = COLUMN_TO_AREL.slice(*enrollment_columns).values
          s = scope
          if cols.many?
            first_q = cols.first.eq nil
            union = cols[1..].reduce(first_q) { |c1, c2| c1.and(c2.eq nil) }
            s = s.select make_count(union, all_missing_enrollments_field_key.tr(' ', '_'))
          end
          s = s.select(*cols.map { |c| make_count(c.eq(nil), c.name.to_s) })
          s = s.select nf('COUNT', [et[:id]]).as(all_enrollments_key.tr(' ', '_'))
          normalize_hash s.connection.select_all(s.to_sql)
        else
          {}
        end
      end

      # true when enrollments are joined into scope and hence there will be client field repeats
      def needs_distinct?
        source.in? ['Organization', 'Project']
      end

      def scope
        @scope ||= begin
          scope = client_scope
          case source
          when 'Data Source'
            if enrollment_columns.any?
              scope.joins(:enrollments)
            else
              scope
            end.where(ct[:data_source_id].eq data_source)
          when 'Organization'
            scope.joins(enrollments: { project: :organization }).
              where(organizations.arel_table[:id].eq organization)
          when 'Project'
            scope.joins(enrollments: :project).
              where(projects.arel_table[:id].eq project)
          else
            if enrollment_columns.any?
              scope.joins(:enrollments)
            else
              scope
            end
          end
        end
      end
    end
  end
end

###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  class CohortCopier
    NEVER_COPIED_COLUMNS = (['cohort_id', 'client_id', 'created_at', 'updated_at', 'deleted_at'] + [GrdaWarehouse::CohortClient.primary_key]).freeze

    # Destination columns the user can edit in the cohort grid
    def self.copyable_columns(cohort, user)
      Array.wrap(cohort.column_state).select do |column|
        next false unless column.editable && column.visible && column.display_as_editable?(user, nil, on_cohort: cohort)

        column.column_editable? || column.column.to_s == 'notes'
      end
    end

    attr_reader :columns

    def initialize(cohort, cohort_scope, params, user:)
      @user = user
      @columns = Array.wrap(params[:columns]).grep(String) & allowed_columns(cohort, user)
      @copy_cohort_id = params[:cohort_id]
      @cohort_scope = cohort_scope
      @destination_cohort = cohort
      load_copy!
      load_destination!
    end

    def copyable?
      columns.any? && @to_copy_cohort.id != @destination_cohort.id
    end

    def copy!
      GrdaWarehouse::CohortClient.transaction do
        @destination_clients.each do |client|
          attributes = @to_copy_clients[client.client_id]
          if attributes.present?
            client.assign_attributes(attributes)
            log_active_change(client) if client.active_changed?
            client.save!
          end
          copy_notes_to(client) if copy_notes?
        end
      end
    end

    private

    def copy_notes_to(client)
      source_row_ids = @to_copy_cohort.visible_cohort_clients(@user).where(client_id: client.client_id).select(:id)
      existing = client.cohort_client_notes.pluck(:note, :user_id, :created_at)
      GrdaWarehouse::CohortClientNote.where(cohort_client_id: source_row_ids).each do |note|
        next if existing.include?([note.note, note.user_id, note.created_at])

        new_note = note.dup
        new_note.created_at = note.created_at
        new_note.updated_at = note.updated_at
        new_note.cohort_client_id = client.id
        new_note.save!
      end
    end

    def log_active_change(client)
      GrdaWarehouse::CohortClientChange.create!(
        cohort_id: @destination_cohort.id,
        cohort_client_id: client.id,
        user_id: @user.id,
        change: client.active ? 'activate' : 'deactivate',
        changed_at: Time.current,
      )
    end

    def load_copy!
      @to_copy_cohort = @cohort_scope.find(@copy_cohort_id)
      raise ActiveRecord::RecordNotFound unless @user.policy_for(@to_copy_cohort).can_view?

      @to_copy_clients = @to_copy_cohort.visible_cohort_clients(@user).
        where(client_id: destination_client_ids).
        select(select_columns).
        group_by(&:client_id).
        transform_values { |rows| rows.first.attributes.slice(*copied_column_names) }
    end

    def load_destination!
      @destination_clients = @destination_cohort.visible_cohort_clients(@user).
        where(client_id: @to_copy_clients.keys)
    end

    def destination_client_ids
      @destination_cohort.visible_cohort_clients(@user).joins(:client).pluck(:client_id)
    end

    def allowed_columns(cohort, user)
      names = GrdaWarehouse::CohortClient.column_names + ['notes']
      self.class.copyable_columns(cohort, user).map { |column| column.column.to_s } & (names - NEVER_COPIED_COLUMNS)
    end

    def copied_column_names
      columns - ['notes']
    end

    def select_columns
      table = GrdaWarehouse::CohortClient.arel_table
      (copied_column_names + ['client_id']).map { |name| table[name] }
    end

    def copy_notes?
      columns.include?('notes')
    end
  end
end

###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin
  class EditHistoriesController < ::ApplicationController
    before_action :require_can_audit_users!
    before_action :set_user

    def show
      pt_a = GrPaperTrail::Version.arel_table
      edits = GrPaperTrail::Version.where(
        pt_a[:item_id].eq(@user_id).and(pt_a[:item_type].eq('User')).
        or(pt_a[:referenced_user_id].eq(@user_id)),
      )
      @versions = edits.where.not(whodunnit: nil).order(created_at: :desc)
      @pagy, @versions = pagy(@versions, items: 500)
    end

    def describe_changes_to(version)
      klass = version.item_type.constantize
      klass.describe_changes(version, get_changes_to(version))
    rescue NameError => e
      Rails.logger.error(e.full_message)
      ["Missing source class: #{version.item_type}"]
    end
    helper_method :describe_changes_to

    private

    def get_changes_to(version)
      if version.changeset.blank?
        compute_changes_to(version)
      else
        version.changeset
      end
    end

    def compute_changes_to(version)
      changed = {}

      current = version.reify rescue nil # rubocop:disable Style/RescueModifier
      return changed unless current

      if current.present? && version.event != 'destroy'
        if version.previous.present? && version.previous.object.present?
          previous = version.previous.reify
          changed_attr = (current.attributes.to_a - previous.attributes.to_a).map(&:first)
          changed_attr.each do |name|
            changed[name] = [previous[name], current[name]]
          end
        else
          # A create - so, all attributes are new
          current.attributes.to_a.each do |name|
            changed[name] = [nil, current[name]]
          end
        end
        # TODO: cache computed change
        # copy_of_changed = changed.clone # Serialize can be in place, so we clone to avoid stepping on the changed map
        # serializer = PaperTrail::AttributeSerializers::ObjectChangesAttribute.new(current.class)
        # serializer.serialize(copy_of_changed)

        # version.object_changes = copy_of_changed
        # version.save`
      elsif current.present?
        # Describe a destroy as setting all attributes to nil
        current.attributes.map(&:first).each do |name|
          changed[name] = [current[name], nil]
        end
      end
      changed
    end

    def set_user
      @user_id = params[:user_id].to_i
      @user = User.find(@user_id)
    end
  end
end

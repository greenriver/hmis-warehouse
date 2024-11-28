###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin
  class EditHistoriesController < ::ApplicationController
    before_action :require_can_audit_users!
    before_action :set_user

    def show
      @versions = version_scope.reorder(id: :desc)
    end

    def describe_changes_to(version)
      begin
        klass = version.item_type.constantize
      rescue NameError => e
        raise e.full_message.inspect
        Rails.logger.error(e.full_message)
        ["Missing source class: #{version.item_type}"]
      end
      klass.describe_changes(version, get_changes_to(version))
    end
    helper_method :describe_changes_to

    private

    def version_scope
      pt_a = GrPaperTrail::Version.arel_table
      scope = GrPaperTrail::Version.where(
        pt_a[:item_id].eq(@user_id).and(pt_a[:item_type].in([User.sti_name, Hmis::User.sti_name])).
        or(pt_a[:referenced_user_id].eq(@user_id)),
      )

      # skip login activity
      login_fields = [
        'current_sign_in_at',
        'current_sign_in_ip',
        'failed_at',
        'last_sign_in_at',
        'last_sign_in_ip',
        'sign_in_count',
        'updated_at'
      ]
      skip_scope = GrPaperTrail::Version.for_users.
        where(item_id: @user_id).
        matching_object_change_fields(*login_fields)
      scope = scope.where.not(id: skip_scope)

      scope
    end

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

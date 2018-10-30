module Admin
  class EditHistoriesController < ::ApplicationController
    before_action :require_can_audit_users! #TODO other parts?
    before_action :set_user

    helper_method :name_of_whodunnit
    helper_method :describe_changes_to

    WHITELIST = %w{first_name last_name email phone agency receive_file_upload_notifications
      notify_of_vispdat_completed notify_on_anomaly_identified}

    def show
      pt_a = PaperTrail::Version.arel_table
      edits = PaperTrail::Version.where(pt_a[:item_id].eq(@user_id).and(pt_a[:item_type].eq('User')).
          or(pt_a[:referenced_user_id].eq(@user_id)))
      @versions = edits.where.not(whodunnit: nil).order(created_at: :desc).page(params[:page]).per(25)
    end

    def name_of_whodunnit(version)
      who = version.whodunnit
      if who.present?
        User.find(who).name
      end
    end

    def describe_changes_to(version)
      item_type = version.item_type
      results = []
      if item_type == 'GrdaWarehouse::UserViewableEntity'
        if version.event == 'create'
          changes = get_changes_to(version)
          results << "Added #{version.referenced_entity_name} to #{humanize_entity_type_name(changes[:entity_type].last)}."
        else
          current = version.reify
          results << "Removed #{version.referenced_entity_name} from #{humanize_entity_type_name(current.entity_type)}."
        end
      else
        changed = get_changes_to(version)
        changed.map do |name, values|
          results << "Changed #{humanize_attribute_name(name)}: from \"#{values.first}\" to \"#{values.last}\"." if WHITELIST.include?(name)
        end
      end
      results
    end

    private

    def humanize_entity_type_name(name)
      humanize_attribute_name(name.split('::').last.underscore.pluralize)
    end

    def humanize_attribute_name(name)
      name.humanize.titleize
    end

    def get_changes_to(version)
      if version.object_changes.nil?
        compute_changes_to(version)
      else
        version.changeset
      end
    end

    def compute_changes_to(version)
      changed = {}
      current = version.reify
      if version.event != 'destroy'
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
        #TODO cache computed change
        #copy_of_changed = changed.clone # Serialize can be in place, so we clone to avoid stepping on the changed map
        #serializer = PaperTrail::AttributeSerializers::ObjectChangesAttribute.new(current.class)
        #serializer.serialize(copy_of_changed)

        #version.object_changes = copy_of_changed
        #version.save`
      else
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
module Admin
  class EditHistoriesController < ::ApplicationController
    before_action :require_can_audit_users! #TODO other parts?
    before_action :set_user

    helper_method :name_of_item_for
    helper_method :describe_changes_to

    WHITELIST = %w{phone agency}

    def show
      @versions = PaperTrail::Version.where(whodunnit: @user_id).
          where.not(object: nil).
          order(created_at: :desc).
          page(params[:page]).per(50)
    end

    def name_of_item_for(version)
      version.reify.name
    end

    def describe_changes_to(version)
      if version.object_changes.nil?
        changed = {}
        current = version.reify
        if version.previous
          previous = version.previous.reify
          changed_attr = (current.attributes.to_a - previous.attributes.to_a).map(&:first)
          changed_attr.each do |name|
            changed[name] = [previous[name], current[name]]
          end
        else
          # Should we describe a create here?
        end
        #TODO store the change object_changes
      else
        changed = version.changeset
      end
      changed.slice(*WHITELIST).map do |name, values|
        "#{name}: from \"#{values.first}\" to \"#{values.last}\""
      end.to_sentence
    end

    def set_user
      @user_id = params[:user_id].to_i
      @user = User.find(@user_id)
    end
  end
end
# This concern audits user activity.
# Place the following in a controller (or ApplicationController)
# 
# include ActivityLogger
# before_action :compose_activity
# after_action :log_activity
# 
# You can optionally limit the data collection like so:
# before_action :compose_activity, only: [:show]
# after_action :log_activity, only: [:show]
# 
# You can add additional bits to be recorded in your route methods.
# If you want a pretty title, create methods that correspond to your route method in the following format:
# "title_for_#{route}" eg: title_for_show or title_for_index
# 
# def show
#   log_item(@client)
# end
# 
module ActivityLogger
  extend ActiveSupport::Concern

  included do 
    def compose_activity
      attrs = {
        user_id: current_user.try(:id),
        params: params,
        controller_name: params[:controller],
        ip_address: request.remote_ip,
        action_name: action_name,
        item_id: params[:id].presence,
        referrer: request.referer,
        session_hash: session.id,
        method: request.method,
        path: request.fullpath,
      }
      @activity = ActivityLog.new(attrs)
    end

    def log_item(item)
      @activity.item_model = item.class.name
    end

    def log_activity
      @activity.title = send("title_for_#{@activity.action_name}") rescue nil
      @activity.save if @activity.user_id.present?
    end
  end
end
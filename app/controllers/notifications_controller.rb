class NotificationsController < ApplicationController
  def poll
    ids = params[:ids] || []
    time = DateTime.current
    time = time.beginning_of_day if current_user.notify_daily?
    to_send = notifications.unseen.before(time).where.not( id: ids )
    to_send.where( sent_at: nil ).update_all sent_at: DateTime.current
    render json: to_send.all
  end

  def seen
    @notification = notifications.unseen.where( id: params.require(:id) ).first
    @seen = @notification&.update_attribute :seen_at, DateTime.current
    render json: { seen: !!@seen }
  end

  private def notifications
    Notification.order( created_at: :desc ).for current_user
  end
end

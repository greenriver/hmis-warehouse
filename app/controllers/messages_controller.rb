class MessagesController < ApplicationController
  def poll
    ids = params[:ids] || []
    render json: messages.where.not( id: ids ).all
  end

  def seen
    @notification = messages.where( id: params.require(:id) ).first
    @seen = @notification&.update_attribute :seen_at, DateTime.current
    render json: { seen: !!@seen }
  end

  private def messages
    current_user.messages.unseen.order created_at: :desc
  end
end

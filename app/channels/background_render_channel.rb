class BackgroundRenderChannel < ApplicationCable::Channel
  def subscribed
    stream_from self.class.stream_name(params[:id])
  end

  def self.stream_name(id)
    "background_render:#{id}"
  end
end

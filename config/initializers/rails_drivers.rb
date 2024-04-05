Rails.application.config.to_prepare do
  # add views for drivers
  ActiveSupport.on_load(:action_controller) do
    Dir['drivers/*'].each do |driver|
      puts "#{driver}/app/views"
      prepend_view_path "#{driver}/app/views"
    end
  end
end

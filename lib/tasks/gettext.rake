namespace :gettext do
  def files_to_translate
    Dir.glob("{app}/**/*.{haml}")
  end
end

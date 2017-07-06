namespace :gettext do
  def files_to_translate
    Dir.glob("{app}/**/*.{haml}")# + Dir.glob("{app}/controllers/**/*.{rb}")# + Dir.glob("{app}/models/**/*.{rb}")
  end
end

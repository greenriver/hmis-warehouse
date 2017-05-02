namespace :roles do
  desc "Load Available Roles"
  task :seed => [:environment, "log:info_to_stdout"] do
    admin = Role.where(name: 'admin').first_or_create
    dnd_staff = Role.where(name: 'dnd_staff').first_or_create
  end
end

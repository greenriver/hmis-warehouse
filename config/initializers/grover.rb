Grover.configure do |config|
  config.options = {
    launch_args: [
      '--disable-dev-shm-usage',
      '--disable-gpu',
    ],
  }
end

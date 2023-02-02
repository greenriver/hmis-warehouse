Prometheus::Client.config.data_store = Prometheus::Client::DataStores::DirectFileStore.new(dir: '/tmp/prometheus_direct_file_store')

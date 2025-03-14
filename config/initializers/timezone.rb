Timezone::Lookup.config(:geonames) do |config|
  config.username = ENV.fetch('GEONAMES_USERNAME', 'demo')
end

Rails.application.config.after_initialize do
  Dir[Rails.root.join("app/lib/gaas/commands/*.rb")].each do |file|
    command_class = Gaas::Commands.const_get(File.basename(file, ".rb").camelize)
    GaasClient::AVAILABLE_METHODS[command_class.identifier] = command_class
  end
end

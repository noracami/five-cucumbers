module Gaas
  class BaseCommand
    GAAS_BACKEND_HOST = Rails.configuration.game_as_a_service.backend_host.freeze

    def call(*_params) = raise NotImplementedError.new "#{self.class.name}#call is not implemented."

    def self.identifier = raise NotImplementedError.new "#{self}.self.identifier is not implemented."

    def initialize(params = {})
      @token = params.delete(:token)
      @params = params
    end

    def validate_token
      return self if Auth0Client.validate_token(@token).error.nil?

      puts "Invalid token" if defined?(Rails::Console) || Rails.env.development?
      nil
    end
  end
end

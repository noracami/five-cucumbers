module Gaas
  module Commands
    class FetchUserInfo < Gaas::BaseCommand
      def self.identifier = :fetch_user_info

      def call(params = {})
        puts "fetch user info called" if defined?(Rails::Console) || Rails.env.development?

        if @token.nil?
          puts "Invalid token" if defined?(Rails::Console) || Rails.env.development?
          return
        end

        case (response = HTTPX.plugin(:auth).bearer_auth(@token).get("#{GAAS_BACKEND_HOST}/users/me"))
        in {status: 200..299}
          # success
          response.json
        in {status: 400..}
          # http error
          if defined?(Rails::Console) || Rails.env.development?
            puts "#{response.status} #{response.uri}"
            response.headers.each { |k, v| puts "#{k}: #{v}" }
          else
            Rails.logger.warn { "#{response.status} #{response.uri}" }
          end
          [nil, response.status]
        in {error: error}
          puts error.class #=> "Errno::CONNREFUSED"
          [nil, error]
        end
      end
    end
  end
end

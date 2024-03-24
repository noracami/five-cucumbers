module Gaas
  module Commands
    class FetchUserInfoInLocal < Gaas::BaseCommand
      include DevelopmentOnly

      def self.identifier = :fetch_user_info_in_local

      def call(params = {})
        {
          id: 'developer000000000000000',
          email: "dev@cucumbers.io",
          nickname: "Me"
        }.with_indifferent_access
      end

      def validate_token
        return self
      end
    end
  end
end

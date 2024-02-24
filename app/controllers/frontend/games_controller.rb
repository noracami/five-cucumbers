module Frontend
  class GamesController < ApplicationController
    after_action :allow_iframe, only: %i(show)

    def show
      Rails.logger.warn { "Frontend::GamesController#show #{params[:id]}" }
      render layout: false
    end

    private
    def allow_iframe
      response.headers.delete "X-Frame-Options"
    end
  end
end

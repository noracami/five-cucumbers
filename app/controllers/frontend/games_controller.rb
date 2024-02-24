module Frontend
  class GamesController < ApplicationController
    def show
      Rails.logger.warn { "Frontend::GamesController#show #{params[:id]}" }
      render layout: false
    end
  end
end

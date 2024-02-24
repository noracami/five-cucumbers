module Frontend
  class GamesController < ApplicationController
    def show
      render plain: "Games id: #{params[:id]}"
    end
  end
end

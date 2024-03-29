module Frontend
  class GamesController < ApplicationController
    skip_before_action :verify_authenticity_token, only: %i(show end_game)

    before_action :set_game, only: %i(show play_card play_card_ai end_game add_ai_players)
    after_action :allow_iframe, only: %i(show)

    helper_method :is_your_turn, :current_player_id

    def index
      @games = Game.playing.order(updated_at: :desc).limit(10)
      @leader_board = GameRecord.order(rounds: :asc).limit(10)
    end

    def show
      if params[:token].present?
        # save token in session
        session[:token] = params[:token]
        user_info = err = nil

        if Rails.env.development? || Rails.env.test?
          user_info, err = GaasClient.call :fetch_user_info_in_local
        else
          user_info, err = GaasClient.call :fetch_user_info, token: params[:token]
        end

        save_user_info_to_session user_info if err.nil?

        return redirect_to frontend_game_path
      end

      @current_player = @game.wrap_players.find { |p| p.id == current_player_id }

      render 'frontend/games/v1/show'
    end

    def add_ai_players
      GameJob::AddAiPlayersJob.perform_now(@game)
    end

    def play_card
      ret = current_player.play_card(params[:card].to_i)

      if ret.errors.any?
        Utils::Notify.new(@game).push_error_event(current_player_id, ret.errors.full_messages.join(", "))

        return render json: { status: "error", errors: ret.errors }, status: 422
      end

      RedisLogs::UpdateJob.perform_now(@game)

      AiJobs::AutoMoveJob.perform_later(@game.id) if @game.wrap_players.find { |p| p.id == @game.current_player_id }&.is_ai?

      render json: { status: "ok" }
    end

    def play_card_ai
      player = Games::Player.build_from_game(game: @game, player_id: params[:player_id])
      ret = player.play_card

      RedisLogs::UpdateJob.perform_now(@game)

      render json: { status: "ok" }
    end

    def end_game
      GameJob::EndGameJob.perform_now(@game, token: session[:token])

      redirect_to frontend_game_path
    end

    private

    def allow_iframe
      response.headers.delete "X-Frame-Options"
    end

    def set_game
      @game = Game.find_by!(uuid: params[:id])
    end

    def send_end_game_request_to_gaas
      raise "send_end_game_request_to_gaas is not implemented"
    end

    def is_your_turn(player_id)
      current_player_position = Utils::Redis.get("game:#{@game.uuid}:current_player_position").to_i
      @game.players[current_player_position]["id"] == player_id #session[:user_info]["id"]
    end

    def current_player_id
      session.dig("user_info", "id")
    end

    def current_player
      Games::Player.build_from_game(game: @game, player_id: current_player_id)
    end

    def save_user_info_to_session(user_info)
      session[:user_info] = {}
      user_info.each { |k, v| session[:user_info][k.to_sym] = v }
      Utils::Notify.push_player_joined_event(@game, session[:user_info][:nickname], "player_joined")
    end
  end
end

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  get "api/health" => "rails/health#show"

  namespace "frontend" do
    resources :games, only: %i(index show) do
      member do
        post :end_game
        post "play/:card" => "games#play_card", as: "play_card"
        post "ai_play/:player_id" => "games#play_card_ai", as: "ai_play"
        post :add_ai_players

        namespace "v1" do
          post :click_btn
          post :plus_one
        end
      end

      collection do
      end
    end
    namespace "games" do
    end
  end

  namespace "api" do
    resources :games, only: %i(create)
  end

  namespace "admin" do
    resources :games, only: %i(create)
  end

  # Defines the root path route ("/")
  root "frontend/games#index"
end

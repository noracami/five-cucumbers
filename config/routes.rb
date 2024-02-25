Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  get "api/health" => "rails/health#show"

  namespace "frontend" do
    resources :games, only: %i(index show) do
      member do
        # get :previous_room
        # get :next_room
        post :end_game
      end
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

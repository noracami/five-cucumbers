Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  get "api/health" => "rails/health#show"

  get "frontend/games/:id" => "frontend/games#show", as: :frontend_game
  post "api/games" => "api/games#create"

  # Defines the root path route ("/")
  root "rails/health#show"
end

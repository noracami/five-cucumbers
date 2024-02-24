Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  get "api/health" => "rails/health#show"

  get "frontend/games/:id" => "frontend/games#show", as: :frontend_game
  get "frontend/games/:id/previous_room" => "frontend/games#previous_room", as: :frontend_game_previous_room
  get "frontend/games/:id/next_room" => "frontend/games#next_room", as: :frontend_game_next_room
  get "frontend/games/:id/end_game" => "frontend/games#end_game", as: :frontend_game_end_game
  post "api/games" => "api/games#create"

  # Defines the root path route ("/")
  root "rails/health#show"
end

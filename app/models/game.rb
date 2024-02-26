class Game < ApplicationRecord
  enum state: {
    initializing: 0,
    initialized: 1,
    running: 2,
    completed: 3
  }, _prefix: true

  scope :playing, -> { where.not(state: :completed) }
end

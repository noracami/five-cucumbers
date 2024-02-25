class Game < ApplicationRecord
  enum state: {
    initializing: 0,
    initialized: 1,
    running: 2,
    ended: 3
  }, _prefix: true

  scope :playing, -> { where.not(state: :ended) }
end

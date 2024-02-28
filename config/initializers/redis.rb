# frozen_string_literal: true

$redis = Redis.new(url: ENV.fetch("REDIS_URI") { "redis://localhost:6379/1" })

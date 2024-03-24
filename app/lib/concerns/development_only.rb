module DevelopmentOnly
  extend ActiveSupport::Concern

  private

  def initialize(*)
    if Rails.env.development? || Rails.env.test?
      super
    else
      raise 'This command is only available in development mode'
    end
  end
end

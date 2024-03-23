class GaasClient
  MOCK_TOKEN = ''

  AVAILABLE_METHODS = {}

  def self.call(method = nil, params = {})
    raise ArgumentError.new("Method not found") if AVAILABLE_METHODS[method].nil?

    AVAILABLE_METHODS[method].new(params).validate_token&.call
  end

  def self.register_method(method, klass)
    AVAILABLE_METHODS[method] = klass
  end
end

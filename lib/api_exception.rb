class ApiError < StandardError
  def initialize(text, code, message)
	@text = text
	@code = code
	@message = message
  end
end
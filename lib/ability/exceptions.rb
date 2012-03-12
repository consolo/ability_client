module Ability

  # Parent class of Ability exceptions
  class AbilityException < StandardError; end

  # Responses with a status between 400 and 503 that contain an <error></error> are
  # returned in an Ability::Error. The error can be raised via the `raise` method
  # and an exception will be thrown with the error's XML message.
  #
  # All error exceptions are subclasses of ResponseError, allowing all exceptions to
  # be caught by rescuing ResponseError.
  class ResponseError < AbilityException
    attr_reader :response
    def initialize(message, response)
      @response = response
      super(message)
    end
  end
  
end

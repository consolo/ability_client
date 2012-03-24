module Ability

  # Responses with a status between 400 and 503 that contain an <error></error> are
  # returned in an Ability::Error. The error can be raised via the `raise` method
  # and an exception will be thrown with the error's XML message.
  #
  # All error exceptions are subclasses of ResponseError, allowing all exceptions to
  # be caught by rescuing ResponseError.
  class ResponseError < StandardError
    attr_reader :error

    def initialize(error)
      @error = error
    end
  end

  # The Error class can generate a custom exception based on a given error code.
  # All generated exceptions decend from ResponseError.
  #
  # An Error exception can be raised with the code, message and details of the error
  # by calling `raise` on the initialized error.
  class Error
    attr_reader :code, :message, :details

    # Generate an error class from a given hash of parsed error response data
    def self.generate(error)

      if error["head"]
        # Handling a 404 HTML error response
        code = "ResourceNotFound"
        message = error["body"]["p"]["content"].gsub(" Reason:\n", "")
        details = nil
      else
        code = error["code"]
        message = error["message"]
        details = error["details"]["detail"].inject({}) { |hash, detail|
          hash[detail["key"]] = detail["value"]
          hash
        }
      end

      new(code, message, details)
    end

    def initialize(code, message, details)
      @code = code
      @message = message
      @details = details
      find_or_create_exception!
    end

    def raise
      Kernel.raise exception.new(self)
    end

    private

    attr_reader :exception

    def find_or_create_exception!
      @exception = Ability.const_defined?(code.to_sym) ? find_exception : create_exception
    end

    def find_exception
      exception_class = Ability.const_get(code)
      Kernel.raise ExceptionClassClash.new(exception_class) unless exception_class.ancestors.include?(ResponseError)
      exception_class
    end

    def create_exception
      Ability.const_set(code, Class.new(Ability::ResponseError))
    end

  end
end

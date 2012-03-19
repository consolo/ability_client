module Ability
  class Error

    class << self
      include Ability::Helpers::XmlHelpers

      # Create an Error instance from a REXML parsed XML document
      def from_doc(doc, response = nil)
        begin
          error = elem(doc, "//error")
          code = elem_text(error, "code")
          message = elem_text(error, "message")
          details = error.elements.to_a("details/detail").map { |d|
            k, v = [d.attributes["key"], d.attributes["value"]]
            { k.to_sym => v }
          }
        rescue
          text = elem(doc, "//html")
          code = elem_text(text, "//head/title").gsub(' ', '')
          message = doc
          details = nil
        end

        new(code, message, details, response)
      end
    end

    attr_reader :code, :message, :details, :response

    def initialize(code, message, details, response = nil)
      @code = code
      @message = message
      @details = details
      @response = response
      find_or_create_exception!
    end

    def raise
      Kernel.raise exception.new(message, response)
    end

    private

    attr_reader :error, :exception

    def find_or_create_exception!
      @exception = Ability.const_defined?(code) ? find_exception : create_exception
    end

    def find_exception
      exception_class = Ability.const_get(code)
      Kernel.raise ExceptionClassClash.new(exception_class) unless exception_class.ancestors.include?(ResponseError)
      exception_class
    end

    def create_exception
      Ability.const_set(code, Class.new(Ability::ResponseError))
    end

    class Response
      attr_reader :doc, :response

      def initialize(doc, response = nil)
        @doc = doc
        @response = response
      end

      def error
        @error ||= Ability::Error.from_doc(doc, self)
      end
    end

  end
end

module Ability
  class Response
    attr_reader :doc, :parsed, :opts

    def initialize(doc, opts = nil)
      @doc = doc
      @opts = opts
    end
  end
end

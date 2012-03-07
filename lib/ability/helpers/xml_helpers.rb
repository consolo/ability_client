module Ability
  module Helpers
    module XmlHelpers

      # Get the text of the element
      def elem_text(element, xpath)
        elem(element, xpath).text
      end

      # Get the first element matching the given XPath
      def elem(element, xpath)
        element.elements.to_a(xpath).first
      end
    end
  end
end

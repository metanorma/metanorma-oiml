# frozen_string: true
module Metanorma::Oiml::Sts::Source
  module Inline
    class Text < Base
      def kind; :text; end
      def text; typed; end
    end
  end
end

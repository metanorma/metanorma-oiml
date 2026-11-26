# frozen_string_literal: true

# Delegates to the shared engine (metanorma-document 0.5.15, Metanorma::Document::Sts)
# per metanorma-iso#1760 / metanorma-document#165.

module Metanorma
  module Oiml
    module Sts
      module HtmlRenderer
        class Ruby < Metanorma::Document::Sts::HtmlRenderer::Ruby
        end
      end
    end
  end
end

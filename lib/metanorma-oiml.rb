# frozen_string_literal: true

# Top-level entry point for the metanorma-oiml gem. Loads the STS
# conversion library; the native Ruby API is `Metanorma::Oiml::Sts.convert`
# and `Metanorma::Oiml::Sts.validate`.
#
# External requires are fine at the entry point; everything inside
# lib/metanorma/oiml/ uses autoload declared in the parent namespace's
# file (lib/metanorma/oiml/sts.rb, lib/metanorma/oiml/html.rb, etc.).
require "metanorma/oiml/sts"

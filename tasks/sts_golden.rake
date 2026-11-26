# frozen_string_literal: true

# Golden STS parity harness (safety net for the engine delegation,
# metanorma-oiml STS waves / metanorma-document#165).
#
# The manifest maps each golden slug to the real-document presentation
# XML it was captured from (the r060 load-cell family shipped as
# spec/fixtures). `bundle exec rake sts:golden:capture` rewrites the
# goldens from the CURRENT pipeline; spec/sts/golden_spec.rb diffs
# every conversion against its golden byte-for-byte.

require "yaml"
require "fileutils"

GOLDEN_MANIFEST_PATH = "spec/sts/golden/manifest.yml"
GOLDEN_DIR = "spec/sts/golden"

def golden_manifest
  YAML.safe_load_file(GOLDEN_MANIFEST_PATH)
end

namespace :sts do
  namespace :golden do
    desc "Capture golden STS outputs from the real-document presentation fixtures"
    task :capture do
      require "metanorma/oiml/sts"
      require "fileutils"

      FileUtils.mkdir_p(GOLDEN_DIR)
      golden_manifest.each do |slug, input|
        warn "capturing #{slug} from #{input}"
        xml = Metanorma::Oiml::Sts.convert(File.read(input))
        File.write(File.join(GOLDEN_DIR, "#{slug}.sts.xml"), xml)
      end
      warn "captured #{golden_manifest.size} goldens into #{GOLDEN_DIR}"
    end
  end
end

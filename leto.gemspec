# frozen_string_literal: true

require_relative "lib/leto/version"

Gem::Specification.new do |spec|
  spec.name = "leto"
  spec.version = Leto::VERSION
  spec.authors = ["Janosch Müller"]
  spec.email = ["janosch84@gmail.com"]

  spec.summary = "Generic object traverser"
  spec.homepage = "https://github.com/jaynetics/leto"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.3.0"

  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["homepage_uri"] = spec.homepage

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|circleci)|appveyor)})
    end
  end
  spec.require_paths = ["lib"]
end

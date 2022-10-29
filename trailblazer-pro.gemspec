require_relative "lib/trailblazer/pro/version"

Gem::Specification.new do |spec|
  spec.name          = "trailblazer-pro"
  spec.version       = Trailblazer::Pro::VERSION
  spec.authors       = ["Nick Sutterer"]
  spec.email         = ["apotonick@gmail.com"]

  spec.summary       = "Integrations for our BPMN editor."
  # spec.description   = "TODO: Write a longer description or delete this line."
  spec.homepage      = "https://trailblazer.to/2.1/docs/pro.html"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.4.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/trailblazer/trailblazer-pro"
  spec.metadata["changelog_uri"] = "https://github.com/trailblazer/trailblazer-pro/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
end

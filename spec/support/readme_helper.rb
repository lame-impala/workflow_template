# frozen_string_literal: true

require 'markly'

module ReadmeHelper
  class Error < StandardError; end

  SPEC_RE = /ruby rspec (\S+)/.freeze

  def self.specs
    @specs ||= extract_specs(Pathname.new(__dir__).join('../../README.md'))
  end

  def self.extract_specs(path)
    doc = Markly.parse(path.read)
    specs = {}
    doc.walk do |node|
      next unless node.type == :code_block
      next unless (match = SPEC_RE.match(node.fence_info))

      key = match[1].to_sym
      raise Error, "Duplicate spec key: #{key}" if specs.key?(key)

      specs.store(key, node.string_content)
    end
    specs
  end
end

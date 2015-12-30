require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

require_relative '../lib/chess'

module RSpec::Core::MemoizedHelpers::ClassMethods
  def fixture(name, &block)
    let(name) do
      filename = File.expand_path(block.call, 'spec/fixtures')
      File.read(filename)
    end
  end

  def pgn(name)
    fixture(:pgn) { name.to_s + '.pgn' }
  end
end

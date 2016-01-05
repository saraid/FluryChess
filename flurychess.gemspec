# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'FluryChess'
  spec.version       = '1.0.10'
  spec.authors       = ['Michael Chui']
  spec.email         = ['saraid216@gmail.com']
  spec.summary       = %q{Chess program}
  spec.description   = %q{Ruby!}
  spec.homepage      = 'http://github.com/saraid/FluryChess'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']
end

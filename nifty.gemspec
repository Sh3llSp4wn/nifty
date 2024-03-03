# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = 'nifty'
  s.version = '0.0.1'
  s.executables << 'nifty'
  s.summary = 'Extendable project templating system'
  s.description = 'Nifty will bring you project templates!'
  s.authors = ['shellspawn']
  s.email = 'shellspawn@protonmail.com'
  s.bindir = 'bin'
  s.files = ['lib/nifty.rb', 'project_templates/']
  s.license = 'MIT'
end

# -*- ruby -*-

gem 'rjack-tarpit', '~> 2.0'
require 'rjack-tarpit/spec'

RJack::TarPit.specify do |s|
  require 'rjack-qpid-client/base'

  s.version = RJack::QpidClient::VERSION

  s.add_developer( 'David Kellum', 'dek-oss@gravitext.com' )

  s.depend 'rjack-jms',           '>= 1.0.0',  '< 1.2'
  s.depend 'rjack-slf4j',         '>= 1.5.8',  '< 1.7'
  s.depend 'rjack-mina',          '~> 1.0.10'

  s.depend 'rjack-logback',       '>= 0.9.18', '< 2.0',  :dev
  s.depend 'minitest',            '~> 2.2',              :dev

  s.assembly_version = '1.0'
  s.jars = %w[ common client ].map do |m|
    "qpid-#{m}-#{ RJack::QpidClient::QPID_VERSION }.jar"
  end
end
ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Adiciona todas as gems do Gemfile
require "bootsnap/setup" # Acelera o boot do sistema

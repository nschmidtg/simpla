require 'haml'
require 'mongoid'
require 'rack-flash'
require 'rack/ssl'
require 'rack/rewrite'
require 'sinatra/base'
require 'sinatra/respond_with'
require 'newrelic_rpm'
require 'trello'
require_relative 'helpers'

class Ollert < Sinatra::Base
  helpers OllertApp::Helpers

  register Sinatra::RespondWith
  configure :development do
    require 'sinatra/reloader'
    register Sinatra::Reloader
  end

  configure do
    use Rack::MethodOverride
    use Rack::Deflater

    I18n.enforce_available_locales = true
    Mongoid.logger = Logger::WARN
    Mongo::Logger.logger.level = Logger::WARN
    Mongoid.load! "#{File.dirname(__FILE__)}/mongoid.yml"
  end

  use Rack::Session::Cookie, secret: ENV['SESSION_SECRET'], expire_after: 30 * (60*60*24) # 30 days in seconds
  use Rack::Flash, sweep: true

  #configure :production do
  #  use Rack::SSL
  #  use Rack::Rewrite do
  #    r301 %r{.*}, 'https://ollertapp.com$&', :if => Proc.new {|rack_env|
  #      rack_env['SERVER_NAME'] != 'ollertapp.com'
  #    }
  #  end
  #end

  set(:auth) do |role|
    condition do
      puts session[:user]
      #puts User.find(session[:user])
      @user = session[:user].nil? ? nil : User.find(session[:user])
      if role == :connected
        if @user.nil?
          session[:user] = nil
          flash[:warning] = "Su cuenta de Trello no coincide con las credenciales provistas."
          redirect '/home'
        end
      end
    end
  end

  error Trello::Error do
    body "Su cuenta de Trello no coincide con las credenciales provistas."
    status 500
  end
end

Dir.glob("#{File.dirname(__FILE__)}/models/*.rb").each do |file|
  require file.chomp(File.extname(file))
end

Dir.glob("#{File.dirname(__FILE__)}/routes/*.rb").each do |file|
  require file.chomp(File.extname(file))
end

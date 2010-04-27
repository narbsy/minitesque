# As per the link below, need to require sinatra/base to avoid collision with redis
# https://sinatra.lighthouseapp.com/projects/9779/tickets/251-sinatra-collision-with-redis-client
require 'sinatra/base'
require 'haml'
require 'resque'
require 'coderay'
require 'lib/job'

class Testy < Sinatra::Base
  set :public, File.dirname(__FILE__) + '/public'

  helpers do
    def add_class_if_current(url, css_class)
      if request.path_info == url
        "class=\"#{css_class}\""
      end
      ""
    end

    def current_url
      request.path_info
    end end 
  get '/' do
    @title = "Testy Resque"
    @info = Resque.info
    haml :index
  end

  post '/' do
    s = Submission.new
    s.name = "fib"
    s.code = params[:file][:tempfile].read
    s.filename = params[:file][:filename]

    if s.save
      hash = { :id => s.id }
      hash[:development] = true if self.class.development?

      Resque.enqueue(Job, hash)
    else
      # failure message
    end

    redirect "/"
  end

  get '/submissions' do
    @title = "Testy Resque :: Submissions"
    @submissions = Submission.all
    haml :submissions
  end
end


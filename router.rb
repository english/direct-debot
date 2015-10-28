require 'lotus/router'
require 'coach'

# Just so we know the app is running and listening
class Index < Coach::Middleware
  def call
    [200, {}, ['hello world!']]
  end
end

# Handles Slack messages in the format of
#   /gc-me <amount> from <user>
# or
#   /gc-me register
class SlackMessage < Coach::Middleware
  def call
    [200, {}, ['slack message']]
  end
end

Router = Lotus::Router.new do
  get '/', to: Coach::Handler.new(Index)
  get '/api/slack/gc-me', to: Coach::Handler.new(SlackMessage)
end

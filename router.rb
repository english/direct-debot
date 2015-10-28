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
#   /gc-me authorise
class SlackMessages < Coach::Middleware
  def call
    message = "Visit #{Prius.get(:host)} to authorise!"

    [200, {}, [message]]
  end
end

Router = Lotus::Router.new do
  get '/', to: Coach::Handler.new(Index)
  post '/api/slack/messages', to: Coach::Handler.new(SlackMessages)
end

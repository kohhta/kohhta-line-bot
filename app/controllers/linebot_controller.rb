class LinebotController < ApplicationController
  require 'line/bot'  # gem 'line-bot-api'

  # callbackアクションのCSRFトークン認証を無効
  protect_from_forgery :except => [:callback]

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  def callback
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      head :bad_request
    end

    events = client.parse_events_from(body)

    # evnets内のtypeを識別していく。
    events.each { |event|
      case event
      when Line::Bot::Event::Message
        case event.type
          # 今回はメッセージに対応する処理を行うため、type: "text"の場合処理をする。
          # 例えば位置情報に対応する処理を行うためには、MessageType::Locationとなる。
        when Line::Bot::Event::MessageType::Text
          message = {
            type: 'text',
            text: event.message['text']  #送られた内容をそのまま返す
          }
          client.reply_message(event['replyToken'], message) # 応答メッセージを送る

        end
      end
    }

    head :ok
  end
end
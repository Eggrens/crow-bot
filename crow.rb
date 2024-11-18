require 'discordrb'
require 'dotenv'
Dotenv.load

bot = Discordrb::Commands::CommandBot.new token: ENV['CROW_TOKEN'], prefix: '~'
bot_channel = ENV['CHANNEL_ID']

bot.command :connect do |event|
    channel = event.user.voice_channel
    next "caw! not in a voice channel dummy" unless channel
    bot.voice_connect(channel)
    "caw! connected to: #{channel.name}"
end

bot.command :play do |event, file|
    voice_bot = event.voice
    if file == nil
        if voice_bot.playing?
            voice_bot.continue
            return "continued playback"
        else
            return "hey, don't do that!!"
        end
    end

    files = Dir.glob("albums/#{file}/**/*.mp3")
    files.each do |f|
        bot.send_message(bot_channel, "caw! now playing #{f}")
        voice_bot.play_file(f)
    end
end

bot.command :pause do |event|
    voice_bot = event.voice
    if voice_bot.playing?
        voice_bot.pause
        "caw! paused"
    else
        "hey! don't do that"
    end
end

bot.command :stop do |event|
    voice_bot = event.voice
    if voice_bot.playing?
        voice_bot.stop_playing
        "caw! stopped"
    end
end

bot.command :leave do |event|
    channel = event.user.voice_channel
    next "caw! not in a voice channel dummy" unless channel
    voice_bot = event.voice
    voice_bot.destroy
    "disconnected from #{channel}"
end

bot.command :quit do |event|
    bot.send_message(event.channel.id, 'caw! shutting down')
    exit
end

at_exit { bot.stop }
bot.run
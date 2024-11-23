require 'discordrb'
require 'dotenv'
Dotenv.load

bot = Discordrb::Commands::CommandBot.new token: ENV['CROW_TOKEN'], prefix: '~'
bot_channel = ENV['CHANNEL_ID']

@queue = []
FORMATS = [".mp3", ".flac", ".wav"]

def play_queue(voice_bot, bot)
    while !@queue.empty? do
        f = @queue.shift
        bot.update_status("online", f, nil, 0, false, 2)
        voice_bot.play_file(f)
    end
    "caw! finished playing"
end

bot.command(:mew, description: "mew") do |event|
    "mew! :>"
end

bot.command(:connect, description: "connect Crow to the voice channel") do |event|
    channel = event.user.voice_channel
    next "caw! not in a voice channel dummy" unless channel
    bot.voice_connect(channel)
    "caw! connected to: #{channel.name}"
end

bot.command(:albums, description: "lists all the directories in the albums folder") do |event|
    next "the albums directory does not exist!" unless Dir.exist?("albums")

    Dir.chdir("albums") do
        albums = Dir.glob("*/")
        next "no albums found" unless albums

        list = "```\nalbums:\n"
        albums.each do |a|
            list << "\t#{a}\n"
        end
        list << "```"
    end
end

bot.command(:queue, description: "prints the current queue") do |event|
    next "caw! queue is empty" if @queue.empty?

    list = "```\nqueue:\n"
    @queue.each do |q|
        list << "\t#{q}\n"
    end
    list << "```"
end

bot.command(:play, description: "play a given file / continue playback") do |event, file|
    voice_bot = event.voice
    if file == nil
        if voice_bot.playing?
            voice_bot.continue
            return "continued playback"
        else
            return "hey, don't do that!!"
        end
    end

    next "#{file} not found..." unless File.exist?(file)
    next "#{file} is a directory, dummy" unless !File.directory?(file)
    next "#{file} does not have .mp3/.flac/.wav extension!" unless FORMATS.include? File.extname(file)

    @queue << file
    bot.send_message(bot_channel, "Added #{file} to the queue")

    play_queue(voice_bot, bot) unless voice_bot.playing?
end

bot.command(:playalbum, description: "play all music files in an album folder") do |event, album|
    voice_bot = event.voice

    next "album #{album} not found..." unless Dir.exist?("albums/#{album}")

    files = Dir.glob("albums/#{album}/**/*.{mp3,flac,wav}")
    files.each do |f|
        @queue << f
    end

    bot.send_message(bot_channel, "caw! added album #{album} to the queue")
    play_queue(voice_bot, bot) unless voice_bot.playing?
end

bot.command(:pause, description: "pause current song") do |event|
    voice_bot = event.voice
    if voice_bot.playing?
        voice_bot.pause
        "caw! paused"
    else
        "hey! don't do that"
    end
end

bot.command(:stop, description: "clears the queue and stops playback") do |event|
    voice_bot = event.voice
    if voice_bot.playing?
        @queue.clear
        voice_bot.stop_playing
        "caw! cleared the queue"
    end
end

bot.command(:skip, description: "skip to the next song in queue") do |event|
    voice_bot = event.voice
    if voice_bot.playing?
        voice_bot.stop_playing
        "caw! skipped"
    end
end

bot.command(:disconnect, description: "disconnect Crow from the voice channel") do |event|
    channel = event.user.voice_channel
    next "caw! not in a voice channel dummy" unless channel
    voice_bot = event.voice
    voice_bot.destroy
    "disconnected from #{channel}"
end

bot.command(:quit, description: "shuts down Crow") do |event|
    bot.send_message(bot_channel, 'caw! shutting down')
    exit
end

at_exit { bot.stop }
bot.run
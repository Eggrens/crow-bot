require 'discordrb'
require 'dotenv'
Dotenv.load

Dotenv.require_keys("CROW_TOKEN", "CHANNEL_ID", "CROW_PREFIX")

env_log = ENV['CROW_LOGGING']
case env_log
when 'debug'
    log_mode = :debug
when 'verbose'
    log_mode = :verbose
when 'quiet'
    log_mode = :quiet
else
    log_mode = :normal
end

bot = Discordrb::Commands::CommandBot.new log_mode: log_mode, token: ENV['CROW_TOKEN'], prefix: ENV['CROW_PREFIX']
bot_channel = ENV['CHANNEL_ID']

@queue = []
FORMATS = [".mp3", ".flac", ".wav"]

def play_queue(voice_bot, bot)
    while !@queue.empty? do
        f = @queue.shift
        bot.update_status("online", f, nil, 0, false, 2)
        voice_bot.play_file(f)
    end
    bot.update_status("online", nil, nil)
    "caw! finished playing"
end

def trim_quotes(s)
    if s[0] == '"'
        s = s.delete_prefix('"')
    elsif s[0] == "'"
        s = s.delete_prefix("'")
    end

    if s[-1] == '"'
        s = s.delete_suffix('"')
    elsif s[-1] == "'"
        s = s.delete_suffix("'")
    end

    return s
end

bot.command(:mew, description: "mew") do |event|
    "mew! :>"
end

bot.command(:connect, description: "connect Crow to the voice channel") do |event|
    channel = event.user.voice_channel
    next "caw! you're not in a voice channel" unless channel
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

bot.command(:shuffle, description: "shuffles the queue") do |event|
    next "caw! queue is empty" if @queue.empty?

    @queue = @queue.shuffle
    "caw! queue shuffled :>"
end

bot.command(:play, description: "play a given file / continue playback") do |event, *filename|
    voice_bot = event.voice
    next "i'm not connected to a voice channel! (use connect command)" unless voice_bot

    if filename.empty?
        if voice_bot.playing?
            voice_bot.continue
            return "continued playback"
        else
            return "there's nothing in the queue to play!"
        end
    end

    file = trim_quotes(filename.join(" "))

    next "#{file} not found..." unless File.exist?(file)
    next "#{file} is a directory..." unless !File.directory?(file)
    next "#{file} does not have .mp3/.flac/.wav extension!" unless FORMATS.include? File.extname(file)

    @queue << file
    bot.send_message(bot_channel, "caw! added #{file} to the queue")

    play_queue(voice_bot, bot) unless voice_bot.playing?
end

bot.command(:playalbum, description: "play all music files in an album folder; add '-s' if you want it shuffled first") do |event, arg1, arg2|
    voice_bot = event.voice
    shuffle = false

    if arg1 == "-s"
        album = arg2
        shuffle = true
    elsif arg2 == "-s"
        album = arg1
        shuffle = true
    else
        album = arg1
    end

    next "album #{album} not found..." unless Dir.exist?("albums/#{album}")

    files = Dir.glob("albums/#{album}/**/*.{mp3,flac,wav}")
    files.each do |f|
        @queue << f
    end

    if shuffle
        @queue = @queue.shuffle
    end
    bot.send_message(bot_channel, "shuffling #{album}") if shuffle
    bot.send_message(bot_channel, "caw! added album #{album} to the queue")
    play_queue(voice_bot, bot) unless voice_bot.playing?
end

bot.command(:pause, description: "pause current song") do |event|
    voice_bot = event.voice
    if voice_bot.playing?
        voice_bot.pause
        "caw! paused"
    else
        "but i'm not playing anything..."
    end
end

bot.command(:stop, description: "clears the queue and stops playback") do |event|
    voice_bot = event.voice
    if voice_bot.playing?
        @queue.clear
        voice_bot.stop_playing
        "caw! cleared the queue"
    else
	    "but i'm not playing anything..."
    end
end

bot.command(:skip, description: "skip to the next song in queue") do |event|
    voice_bot = event.voice
    if voice_bot.playing?
        voice_bot.stop_playing
        "caw! skipped"
    else
	    "but i'm not playing anything..."
    end
end

bot.command(:disconnect, description: "disconnect Crow from the voice channel") do |event|
    channel = event.user.voice_channel
    next "caw! not in a voice channel" unless channel
    voice_bot = event.voice
    voice_bot.destroy
    "disconnected from #{channel.name}"
end

bot.command(:quit, description: "shuts down Crow") do |event|
    bot.send_message(bot_channel, 'caw! shutting down')
    exit
end

at_exit { bot.stop }
bot.run

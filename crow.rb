require 'discordrb'
require 'dotenv'
require 'taglib'
Dotenv.load

Dotenv.require_keys("CROW_TOKEN", "CROW_PREFIX")

case ENV['CROW_LOGGING']
when 'debug'
    log_mode = :debug
when 'verbose'
    log_mode = :verbose
when 'quiet'
    log_mode = :quiet
else
    log_mode = :normal
end

channels = ENV['CROW_CHANNELS'] ? ENV['CROW_CHANNELS'].split(',') : []

options = {
    log_mode: log_mode,
    token: ENV['CROW_TOKEN'],
    prefix: ENV['CROW_PREFIX'],
    channels: channels,
    # advanced functionality is enabled only to make parsing arguments wrapped in quotes much easier.
    # command chaining functionality is disabled with these options!
    advanced_functionality: true,
    previous: '',
    chain_delimiter: '',
    chain_args_delim: '',
    sub_chain_start: '',
    sub_chain_end: ''
}

bot = Discordrb::Commands::CommandBot.new(**options)
@queue = []
@current_song = nil
@time_skipped = 0
FORMATS = [".mp3", ".flac", ".wav"]

def convert_to_time(secs)
    if secs / 3600 < 1
        "%d:%02d" % [secs / 60 % 60, secs % 60]
    else
        "%d:%02d:%02d" % [secs / 3600, secs / 60 % 60, secs % 60]
    end
end

def convert_to_secs(time)
    time.split(':').map(&:to_i).inject(0) { |a, b| a * 60 + b}
end

class Song
    attr_reader :filename
    attr_reader :short
    attr_reader :title
    attr_reader :artist
    attr_reader :length

    def initialize(filename)
        @filename = filename
        @short = filename.match(/[^\/]+\.(mp3|flac|wav)/)[0]
        TagLib::FileRef.open(filename) do |file|
            unless file.null?
                tag = file.tag
                prop = file.audio_properties
                @title = tag.title
                @artist = tag.artist
                @length = prop.length_in_seconds
            end
        end
    end

    def to_s
        if !@title.empty? && !@artist.empty?
            "#{@title} - #{@artist}"
        else
            # return title if metadata present, or return its shortened filename
            @title.empty? ? @short : @title
        end
    end
end

def play_queue(voice_bot, bot)
    while !@queue.empty? do
        song = @queue.shift
        @current_song = song
        @time_skipped = 0
        # Set status to "Playing [songtitle] - [songartist]"
        bot.update_status("online", song.to_s, nil, 0, false, 2)
        voice_bot.play_file(song.filename)
    end
    @current_song = nil
    bot.update_status("online", nil, nil)
    "caw! finished playing"
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

bot.command(:list, min_args: 1, max_args: 1, description: "list all music files inside a given album", usage: "list [album]") do |event, album|
    next "the albums directory does not exist!" unless Dir.exist?("albums")
    next "album #{album} not found..." unless Dir.exist?("albums/#{album}")
    list = nil

    Dir.chdir("albums/#{album}") do
        songs = Dir.glob("**/*.{mp3,flac,wav}")
        next "no songs found" unless songs

        list = "```\nsongs in #{album}:\n"
        songs.each_with_index do |a, i|
            entry = "\t#{a}\n"
            if list.size + entry.size > 1978
                list << "(and #{songs.length - i+1} more...)\n"
                break
            else
                list << entry
            end
        end
        list << "```"
    end

    next "caw! this album listing is too big... (exceeded 2000 characters)" if list.size > 2000
    return list
end

bot.command(:nowplaying, description: "lists the current song being played", aliases: [:np]) do |event|
    next "caw! no song is being played" unless @current_song

    event << "Playing:"
    event << "**#{@current_song.to_s}**"
    event << "`#{convert_to_time(event.voice.stream_time + @time_skipped)} / #{convert_to_time(@current_song.length)}`"
end

bot.command(:queue, description: "prints the current queue", aliases: [:q]) do |event|
    next "caw! queue is empty" if @queue.empty?

    list = "```\nqueue:\n"
    @queue.each_with_index do |q, i|
        entry = "\t%3d. | %8s | %s\n" % [i+1, convert_to_time(q.length), q.to_s]
        if list.size + entry.size > 1978
            list << "(and #{@queue.length - i+1} more...)\n"
            break
        else
            list << entry
        end
    end
    next "caw! this album listing is too big... (exceeded 2000 characters)" if list.size > 2000
    list << "```"
end

bot.command(:shuffle, description: "shuffles the queue") do |event|
    next "caw! queue is empty" if @queue.empty?

    @queue = @queue.shuffle
    "caw! queue shuffled :>"
end

bot.command(:play, max_args: 1, description: "play a given file / continue playback", usage: 'play [path-to-file]', aliases: [:p]) do |event, file|
    voice_bot = event.voice
    next "i'm not connected to a voice channel! (use connect command)" unless voice_bot

    unless file
        if voice_bot.playing?
            voice_bot.continue
            return "continued playback"
        else
            return "there's nothing in the queue to play!"
        end
    end

    next "#{file} not found..." unless File.exist?(file)
    next "#{file} is a directory..." unless !File.directory?(file)
    next "#{file} does not have .mp3/.flac/.wav extension!" unless FORMATS.include? File.extname(file)

    @queue << Song.new(file)
    event.respond "caw! added #{file} to the queue"
    play_queue(voice_bot, bot) unless voice_bot.playing?
end

bot.command(:playalbum, min_args: 1, max_args: 2, description: "play all music files in an album folder; add '-s' if you want it shuffled first",
 usage: 'playalbum [album] [-s]', aliases: [:pa]) do |event, *args|
    voice_bot = event.voice
    next "i'm not connected to a voice channel! (use connect command)" unless voice_bot
    shuffle = false

    if args.count == 2
        next "invalid parameters passed (was expecting -s)" if args[0] != "-s" && args[1] != "-s"
        shuffle = true
        album = args[0] == "-s" ? args[1] : args[0]
    else
        album = args[0]
    end

    next "the albums directory does not exist!" unless Dir.exist?("albums")
    next "album #{album} not found..." unless Dir.exist?("albums/#{album}")

    files = Dir.glob("albums/#{album}/**/*.{mp3,flac,wav}")
    files.each do |f|
        @queue << Song.new(f)
    end

    if shuffle
        @queue = @queue.shuffle
    end
    event.respond "shuffling #{album}" if shuffle
    event.respond "caw! added album #{album} to the queue"
    play_queue(voice_bot, bot) unless voice_bot.playing?
end

bot.command(:pause, description: "pause current song") do |event|
    voice_bot = event.voice
    next "i'm not connected to a voice channel! (use connect command)" unless voice_bot

    if voice_bot.playing?
        voice_bot.pause
        "caw! paused"
    else
        "but i'm not playing anything..."
    end
end

bot.command(:stop, description: "clears the queue and stops playback") do |event|
    voice_bot = event.voice
    next "i'm not connected to a voice channel! (use connect command)" unless voice_bot

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
    next "i'm not connected to a voice channel! (use connect command)" unless voice_bot

    if voice_bot.playing?
        voice_bot.stop_playing
        "caw! skipped song"
    else
	    "but i'm not playing anything..."
    end
end

bot.command(:seek, min_args: 1, max_args: 1, description: "seek to a later timecode in the current song being played",
usage: "seek [H:MM:SS or M:SS]") do |event, time|
    voice_bot = event.voice
    next "i'm not connected to a voice channel! (use connect command)" unless voice_bot
    next "but i'm not playing anything..." unless voice_bot.playing?

    hms = time.split(':')
    next "invalid timecode format (must be H:MM:SS or M:SS)" if hms.length > 3 || hms.length < 2

    secs = convert_to_secs(time)
    next "timecode out of bounds!" if secs > @current_song.length
    next "timecode has been passed already (cannot go back in time)" if secs <= (voice_bot.stream_time + @time_skipped)

    @time_skipped += secs - voice_bot.stream_time
    voice_bot.skip(secs)
    "caw! skipped to `#{convert_to_time(secs)} / #{convert_to_time(@current_song.length)}`"
end

bot.command(:disconnect, description: "disconnect Crow from the voice channel") do |event|
    channel = event.user.voice_channel
    next "caw! not in a voice channel" unless channel
    voice_bot = event.voice
    voice_bot.destroy
    "disconnected from #{channel.name}"
end

# note: you may want to remove this command unless you absolutely trust whoever's using it :)
bot.command(:quit, description: "shuts down Crow") do |event|
    event.respond 'caw! shutting down'
    exit
end

at_exit { bot.stop }
bot.run

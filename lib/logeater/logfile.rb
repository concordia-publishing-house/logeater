module Logeater
  class Logfile
    attr_reader :path, :filename
    attr_accessor :show_progress
    alias :show_progress? :show_progress

    def initialize(path)
      @path = path
      @filename = File.basename(path)
    end

    def each_line
      File.open(path) do |file|
        io = File.extname(path) == ".gz" ? Zlib::GzipReader.new(file) : file
        pbar = ProgressBar.create(title: filename, total: file.size, autofinish: false, output: $stderr) if show_progress?
        io.each_line do |line|
          yield line
          pbar.progress = file.pos if show_progress?
        end
        pbar.finish if show_progress?
      end
    end

  end
end

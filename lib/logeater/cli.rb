require "thor"
require "logeater"

module Logeater
  class CLI < Thor

    desc "parse APP FILES", "parses files and writes their output to stdout"
    def parse(app, *files)
      if files.empty?
        $stderr.puts "No files to parse"
        return
      end

      started_all = Time.now
      files.each_with_index do |file, i|
        reader = Logeater::Reader.new(app, Logeater::Logfile.new(file), progress: true)

        started_at = Time.now
        requests = reader.parse
        finished_at = Time.now

        $stderr.puts " > \e[34mParsed \e[1m%d\e[0;34m requests in \e[1m%.2f\e[0;34m seconds (%d of %d)\e[0m\n\n" % [
          requests,
          finished_at - started_at,
          i + 1,
          files.length ]
      end

      finished_all = Time.now
      seconds = finished_all - started_all
      minutes = (seconds / 60).to_i
      seconds -= (minutes * 60)
      $stderr.puts "Total time %d minutes, %.2f seconds" % [minutes, seconds]
    end

    option :force, type: :boolean, desc: "Imports all specified files, overwiting previous imports if necessary"
    option :progress, type: :boolean, desc: "Renders a progress bar while importing"
    option :verbose, type: :boolean
    desc "import APP FILES", "imports files"
    def import(app, *files)
      unless options[:force]
        started_at = Time.now
        imported_files = Logeater::Request.where(app: app).pluck("DISTINCT logfile")
        finished_at = Time.now

        $stderr.puts " > \e[34mListed imported logfiles for \e[1m#{app}\e[0;34m in \e[1m%.2f\e[0;34m seconds\e[0m\n" % [
          finished_at - started_at ]

        files_count = files.count
        files.reject! { |file| imported_files.member? File.basename(file) }

        $stderr.puts "   \e[34;1m#{files_count}\e[0;34m files passed, \e[1m#{files_count - files.length}\e[0;34m removed as already imported.\e[0m\n\n"
      end

      if files.empty?
        $stderr.puts "No files to import"
        return
      end

      started_all = Time.now
      files.each_with_index do |file, i|
        $stderr.puts " > \e[34mImporting \e[1m#{File.basename(file)}\e[0;34m (%d of %d)\e[0m\n" % [
          i + 1,
          files.length ]

        import_file Logeater::Logfile.new(file), app, options
      end

      finished_all = Time.now
      seconds = finished_all - started_all
      minutes = (seconds / 60).to_i
      seconds -= (minutes * 60)
      $stderr.puts "Total time %d minutes, %.2f seconds" % [minutes, seconds]
    end

    desc "import_since APP TIMESTAMP", "imports log events since timestamp"
    def import_since(app, timestamp)
      started_all = Time.now
      $stderr.puts " > \e[34mImporting events since \e[1m#{timestamp}\e[0m\n"

      events = Logeater::Event.where(ep_app: app).since(timestamp)
      import_file Logeater::Eventfile.new(events), app

      finished_all = Time.now
      seconds = finished_all - started_all
      minutes = (seconds / 60).to_i
      seconds -= (minutes * 60)
      $stderr.puts "Total time %d minutes, %.2f seconds" % [minutes, seconds]
    end


    def import_file(file, app, options={})
      reader = Logeater::Reader.new(app, file, options.slice(:progress, :verbose))

      started_at = Time.now
      count = reader.remove_existing_entries!
      finished_at = Time.now

      $stderr.puts "   \e[34mDeleted \e[1m%d\e[0;34m requests for #{reader.filename} in \e[1m%.2f\e[0;34m seconds\e[0m\n" % [
        count,
        finished_at - started_at ]

      started_at = Time.now
      count = reader.import
      finished_at = Time.now

      $stderr.puts "   \e[34mImported \e[1m%d\e[0;34m requests in \e[1m%.2f\e[0;34m seconds\e[0m\n\n" % [
        count,
        finished_at - started_at ]
    end

  end
end

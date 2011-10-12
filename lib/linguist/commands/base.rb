require 'fileutils'

module Linguist::Command
  class Base
    include Linguist::Helpers

    attr_accessor :args
    attr_reader :autodetected_app

    def initialize(args, linguist=nil)
      @args             = args
      @linguist         = linguist
      @autodetected_app = false
    end

    def linguist
      @linguist ||= Linguist::Command.run_internal('auth:client', args)
    end

    def extract_app(force=true)
      app = extract_option('--app', false)
      raise(CommandFailed, "You must specify an app name after --app") if app == false
      unless app
        app = extract_app_from_git || extract_from_dir_name ||
          raise(CommandFailed, "No app specified.\nRun this command from app folder or set it adding --app <app name>") if force
        @autodetected_app = true
      end
      app
    end

    def extract_from_dir_name
      dir = Dir.pwd
      File.basename(dir)
    end

    def extract_app_from_git
      dir = Dir.pwd
      return unless remotes = git_remotes(dir)

      if remote = extract_option('--remote')
        remotes[remote]
      elsif remote = extract_app_from_git_config
        remotes[remote]
      else
        apps = remotes.values.uniq
        return apps.first if apps.size == 1
      end
    end

    def extract_app_from_git_config
      remote = git("config heroku.remote")
      remote == "" ? nil : remote
    end

    def git_remotes(base_dir=Dir.pwd)
      remotes      = { }
      original_dir = Dir.pwd
      Dir.chdir(base_dir)

      # TODO
#      git("remote -v").split("\n").each do |remote|
#        name, url, method = remote.split(/\s/)
#        if url =~ /^git@#{heroku.host}:([\w\d-]+)\.git$/
#          remotes[name] = $1
#        end
#      end

      Dir.chdir(original_dir)
      remotes
    end

    def extract_option(options, default=true)
      values = options.is_a?(Array) ? options : [options]
      return unless opt_index = args.select { |a| values.include? a }.first
      opt_position = args.index(opt_index) + 1
      if args.size > opt_position && opt_value = args[opt_position]
        if opt_value.include?('--')
          opt_value = nil
        else
          args.delete_at(opt_position)
        end
      end
      opt_value ||= default
      args.delete(opt_index)
      block_given? ? yield(opt_value) : opt_value
    end

    def git_url(name)
      "git@#{heroku.host}:#{name}.git"
    end

    def app_urls(name)
#      "#{web_url(name)} | #{git_url(name)}"
    end

    def escape(value)
      linguist.escape(value)
    end

    def project(title=nil)
      title ||= project_title
      @project ||= linguist.project(title) 
    end

    def project_title
      (args.first && !(args.first =~ /^\-\-/)) ? args.first : extract_app
    end
  end

  class BaseWithApp < Base
    attr_accessor :app

    def initialize(args, linguist=nil)
      super(args, linguist)
      @app ||= extract_app
    end
  end
end

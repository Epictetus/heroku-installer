#  -*- coding: utf-8 -*-
require "sinatra"
require "json"
require "cgi"
require "tmpdir"
require "kramdown"
require "pty"
require "shellwords"
require "heroku-api"
require "heroku/client/rendezvous"

HEROKU_ACCOUNT = "hinasssan@gmail.com"

def git(*args)
  args.unshift "git"

  PTY.getpty(args.map(&:to_s).map(&:shellescape).join(" ")) do |o, i|
    IO.copy_stream(o, STDOUT) rescue nil
  end
end

helpers do
  def h(s)
    CGI.escapeHTML(s.to_s)
  end
end

get "/" do
  Kramdown::Document.new(File.read("README.md")).to_html
end

"/install/git:/*".tap do |it|
  before it do |repo|
    @repo = "git://" + repo
  end

  get it do
    @repo_name = @repo[%r"[^/]+$"].chomp(".git")
    erb :install
  end

  post it do
    stream do |resp|
      r, w = IO.pipe
      STDOUT.reopen(w)

      Thread.new do
        r.each(1) {|c| resp << c }
      end

      puts "Initializing heroku application ...\r"

      app_name = params[:app_name]

      begin
        heroku = Heroku::API.new(api_key: params[:api_key])
        heroku.post_app(name: app_name, stack: "cedar")
        heroku.post_collaborator(app_name, HEROKU_ACCOUNT)
      rescue Heroku::API::Errors::RequestFailed
        puts "Heroku error: " + JSON.parse($!.response.body)["error"] + "\r"
        next
      rescue Heroku::API::Errors::Unauthorized
        puts "API key may be invalid."
        next
      end

      begin
        Dir.mktmpdir do |repo_path|
          git :clone, @repo, repo_path

          Dir.chdir(repo_path) do
            conf = {}

            if File.exist?(".heroku-installer")
              conf = YAML.load(open(".heroku-installer"))
            end

            conf["addons"].to_a.each do |addon|
              heroku.post_addon(app_name, addon)
            end

            heroku.put_config_vars(app_name, conf["config"] || {})

            git :remote, :add, :heroku, "git@heroku.com:%s.git" % app_name
            git :push, :heroku, :master

            conf["script"].to_a.each do |command|
              process = heroku.post_ps(app_name, command, attach: true).body
              Heroku::Client::Rendezvous.new(rendezvous_url: process["rendezvous_url"], output: STDOUT).start
            end
          end
        end

        heroku.delete_collaborator(app_name, HEROKU_ACCOUNT)
      rescue
        heroku.delete_app(app_name)
        puts $!.message
        next
      end

      puts "\r"
      puts "Deployed application at http://%s.herokuapp.com/" % app_name
    end
  end
end

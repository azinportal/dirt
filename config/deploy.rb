require 'capistrano/ext/multistage'

set :application, "dirt"

set :scm, :git
set :repository,  "git@github.com:directi/dirt-internal.git"
set :scm_passphrase, ""

set :user, "dirt"

set :stages, ["staging", "production"]
set :default_stage, "staging"

set :use_sudo, false
set :deploy_via, :remote_cache
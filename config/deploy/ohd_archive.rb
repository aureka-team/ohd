server "deploy_da03", roles: %w{app db web}

set :application, "ohd_archive"
set :stage, :production
set :deploy_to, "/data/applications/#{fetch :application}"
set :bundle_path, "/data/bundle/01"
set :project_yml, "ohd_archive.yml"
set :branch, ENV.fetch('BRANCH', 'main')

set :rbenv_type, :system
set :rbenv_ruby, '3.3.4'
set :rbenv_custom_path, '/opt/rbenv'

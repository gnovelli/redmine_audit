require 'redmine/version'
require 'redmine_audit/advisory'
require 'redmine_audit/database'

desc <<-END_DESC
Check redmine vulnerabilities.

Available options:
  * users    => comma separated list of user/group ids who should be notified

Example:
  rake redmine:bundle_audit users="1,23, 56" RAILS_ENV="production"
END_DESC

namespace :redmine do
  task audit: :environment do
    # TODO: More better if requires mailer automatically.
    require_dependency 'mailer'
    require_relative '../../app/models/mailer.rb'

    redmine_ver = Redmine::VERSION
    advisories = RedmineAudit::Database.new.advisories(redmine_ver.to_s)
    if advisories.length > 0
      users = (ENV['USERS'] || '').split(',').each(&:strip!)
      Mailer.with_synched_deliveries do
        Mailer.unfixed_advisories_found(advisories, users).deliver
      end
    end
  end
end

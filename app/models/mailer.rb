# reopen Redmine Mailer
class Mailer < ActionMailer::Base
  # Sends notification to specified administrator
  #
  # @param [Gem::Version] advisories
  #   The version to compare against {#unaffected_versions}.
  # @param [Array] user_ids
  #   Array of user ids who should be notified
  def unfixed_advisories_found(advisories, user_ids)
    if advisories.nil? || advisories.empty?
      raise "Couldn't find user specified: #{advisories.inspect}"
    end

    user_ids = options[:users]
    users = User.active.where(admin: true, id: user_ids).to_a
    if users.empty?
      raise ActiveRecord::RecordNotFound.new("Couldn't find user specified: #{user_ids.inspect}")
    end

    @advisories = advisories
    # TODO: use Redmine's Mailer#mail method. Now using ActionMailer#mail method.
    #       And remove from keyword argument after that.
    # TODO: Internationalize suject and body.
    mail(from: Setting.mail_from, to: users.map(&:mail),
         subject: "[Redmine] Security notification")
  end
end

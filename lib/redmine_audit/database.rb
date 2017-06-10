require 'open-uri'
require 'nokogiri'
require 'redmine_audit/advisory'

module RedmineAudit
  # Redmine advisory database
  class Database
    URL = 'http://www.redmine.org/projects/redmine/wiki/Security_Advisories'
    TABLE_XPATH = '//*[@id="content"]/div[2]/table'

    attr_reader :vulnerabilities

    # Get unfixed advisories against specified Redmine version.
    #
    # @param [String] version
    #   The Redmine version to compare against {#unaffected_versions}.
    #
    # @return [[Redmine::Advisory]]
    #   The array of Redmine::Advisory unfixed.
    def advisories(v)
      if @known_advisories.nil?
        @known_advisories = []
        html = fetch_advisory_data
        doc = Nokogiri::HTML(html)
        doc.xpath(TABLE_XPATH).xpath('tr')[1..-1].each do |tr|
          if res = parse_tds(tr.xpath('td'))
            @known_advisories << Advisory.new(*res)
          end
        end
      end

      redmine_version = Gem::Version.new(v)
      unfixed_advisories = []
      @known_advisories.each do |advisory|
        if advisory.vulnerable?(redmine_version)
          unfixed_advisories.push(advisory)
        end
      end
      return unfixed_advisories
    end

    private

    def fetch_advisory_data(url = URL)
      open(url).read
    end

    # [severity, details, external_references, unaffected_versions, fixed_versions]
    def parse_tds(tds)
      # TODO: treat affected_versions if needed.
      # Last element is unaffected_versions. Always empty array now.
      res = tds[0..2].map(&:content) + [[]]

      # Ignore depends gem
      return nil if /Ruby on Rails vulnerability/.match(res[1])

      versions = tds[4].content.split(/\s*(?:and|,)\s*/)
      fixed_versions = []
      if versions.length > 1
        fixed_versions =
          versions[0..-2].map {|v| Gem::Requirement.new('~> ' + v)}
      end
      fixed_versions.push(Gem::Requirement.new('>= ' + versions.last))
      res.push(fixed_versions)
      return res
    end
  end
end
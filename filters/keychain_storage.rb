require 'shellwords'
require 'yaml'

class SecretsMap
  def initialize(path)
    @map = YAML.load_file(SECRETS_PATH)
  end

  def for_path(path)
    return @map.keep_if do |key, v|
      key = "**/#{key}" unless key[0] == '/'
      File.fnmatch(key, FNAME)
    end.values.inject(&:merge)
  end
end

module Secrets
  class KeychainStore
    SECURITY_CMD = '/usr/bin/security'

    def _keys_for(name, key)
      return ['-a', ENV['USER'], '-c', 'gitf', '-C', 'gitf', '-D', 'git filter secret', '-l', key]
    end

    def find(name, key)
      command = Shellwords.join([
        SECURITY_CMD, 'find-generic-password', '-w'] +
        self._keys_for(name, key))
      saved_secret = `#{command} 2>&1`.chomp
      return saved_secret if $?.exitstatus == 0
      return nil
    end

    def update(name, key, password)
      command = Shellwords.join([
        SECURITY_CMD, 'add-generic-password',
        '-s', "#{REPO_NAME}/#{FNAME}/#{name}",
        '-w', password,
        '-U'] + self._keys_for(name, key))
      `#{command}`
      exit 1 unless $?.exitstatus == 0
    end
  end
end

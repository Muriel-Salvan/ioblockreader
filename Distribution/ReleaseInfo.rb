RubyPackager::ReleaseInfo.new.
  author(
    :name => 'Muriel Salvan',
    :email => 'muriel@x-aeon.com',
    :web_page_url => 'http://murielsalvan.users.sourceforge.net'
  ).
  project(
    :name => 'IOBlockReader',
    :web_page_url => 'https://github.com/Muriel-Salvan/ioblockreader',
    :summary => 'Ruby library giving block-buffered and cached read over IO objects with a String-like interface. Ideal to parse big files as Strings, limiting memory consumption.',
    :description => 'Ruby library giving block-buffered and cached read over IO objects with a String-like interface. Ideal to parse big files as Strings, limiting memory consumption.',
    :image_url => 'http://ioblockreader.sourceforge.net/wiki/images/c/c9/Logo.png',
    :favicon_url => 'http://ioblockreader.sourceforge.net/wiki/images/2/26/Favicon.png',
    :browse_source_url => 'http://ioblockreader.git.sourceforge.net/',
    :dev_status => 'Beta'
  ).
  add_core_files( [
    'lib/**/*'
  ] ).
  add_test_files( [
    'test/**/*'
  ] ).
  add_additional_files( [
    'README',
    'README.md',
    'LICENSE',
    'AUTHORS',
    'Credits',
    'ChangeLog',
    'Rakefile'
  ] ).
  gem(
    :gem_name => 'ioblockreader',
    :gem_platform_class_name => 'Gem::Platform::RUBY',
    :require_path => 'lib',
    :has_rdoc => true,
    :test_file => 'test/run.rb'
  ).
  source_forge(
    :login => 'murielsalvan',
    :project_unix_name => 'ioblockreader',
    :ask_for_key_passphrase => true
  ).
  ruby_forge(
    :project_unix_name => 'ioblockreader'
  )

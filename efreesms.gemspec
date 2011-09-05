Gem::Specification.new {|g|
    g.name          = 'efreesms'
    g.version       = '0.0.1'
    g.author        = 'shura'
    g.email         = 'shura1991@gmail.com'
    g.homepage      = 'http://github.com/shurizzle/ruby-efreesms'
    g.platform      = Gem::Platform::RUBY
    g.description   = 'send sms via e-freesms.com'
    g.summary       = g.description
    g.files         = Dir.glob('lib/**/*')
    g.require_path  = 'lib'
    g.executables   = ['sms']
    g.has_rdoc      = true

    g.add_dependency('httpclient')
    g.add_dependency('rmagick')
    g.add_dependency('nokogiri')
}

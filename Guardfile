guard 'spork', :cucumber_env => { 'RACK_ENV' => 'test' }, :rspec_env => { 'RACK_ENV' => 'test' } do
  watch('Gemfile')
  watch('Gemfile.lock')
end

guard 'rspec', :cli => '--drb' do

  # spec helpers
  watch(%r{^(\w+)\.rb$})           { "spec" }
  watch(%r{spec/(\w+)\.rb$})       { "spec" }

  # spec files
  watch(%r{^spec/.+_spec\.rb$})

  # gem files
  watch(%r{^lib/(\w+)\.rb$})                   { "spec" }
  watch(%r{^lib/syphon/(\w+)\.rb$})            { "spec" }
  watch(%r{^lib/syphon/common/(\w+)\.rb$})     { |m| "spec/common/#{m[1]}_spec.rb" }
  watch(%r{^lib/syphon/api/(\w+)\.rb$})        { |m| "spec/api/#{m[1]}_spec.rb" }
  watch(%r{^lib/sypon/client/(\w+)\.rb$})      { |m| "spec/client/#{m[1]}_spec.rb" }

end

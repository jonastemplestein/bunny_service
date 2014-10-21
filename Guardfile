guard :rspec, cmd: "bundle exec rspec", all_on_start: true do
  watch(%r{^spec/(.+)_spec\.rb$}) { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^spec/helpers/.+\.rb$}) { "spec" }
  watch(%r{^lib/(.+)\.rb$}) { "spec" }
  watch('spec/spec_helper.rb')  { "spec" }
end

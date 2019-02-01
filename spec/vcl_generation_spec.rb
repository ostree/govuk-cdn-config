require 'spec_helper'
require_relative './../lib/render_template'

# This
RSpec.describe "VCL generation" do
  # Fill in the required test data. Normally this would come from
  # https://github.com/alphagov/cdn-configs/blob/master/fastly/fastly.yaml
  config = {
    "origin_hostname" => "foo",
    "service_id" => "123",
    "provider1_mirror_hostname" => "foo",
    "s3_mirror_hostname" => "bar",
    "s3_mirror_prefix" => "foo_",
    "default_ttl" => "5000",
    "apt_hostname" => "foo",
    "origin_domain_suffix" => "boo",
    "domain_suffix" => "boo",
  }

  Dir.glob("vcl_templates/*.erb").each do |template|
    service = template.sub("vcl_templates/", "").sub(".vcl.erb", "")
    next if service[0] == "_" # Skip partials
    next if service == "bouncer" # Bouncer is not deployed from this repo
    next if service == "test" # For another test

    %w[production staging integration].each do |environment|
      it "renders the #{service} VCL for #{environment} correctly" do
        generated_vcl = RenderTemplate.render_template(service, environment, config, "unused variable")
        expected_vcl_filename = "spec/test-outputs/#{service}-#{environment}.out.vcl"

        if ENV["REGENERATE_EXPECTATIONS"]
          File.write(expected_vcl_filename, generated_vcl)
        end

        expect(generated_vcl).to eql(File.read(expected_vcl_filename)),
          "The generated VCL doesn't matched the test output VCL. If you're sure the generated VCL is correct, regenerate the test files with `REGENERATE_EXPECTATIONS=1 bundle exec rspec`."
      end
    end
  end
end
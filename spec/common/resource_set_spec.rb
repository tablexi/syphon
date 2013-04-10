require_relative '../spec_helper'

describe Syphon::ResourceSet do

  let(:dsl) { Syphon::ResourceDSL }

  it 'should find a resource by its name' do
    set = dsl.parse(Support.json('api_spec'))
    set.find(:subscription).should be_a Syphon::Resource
    set.find(:plans).should be_a Syphon::Resource
  end

end

require 'spec_helper'

RSpec.describe BunnyService::Controller do
  describe ".action_bindings" do
    let(:sentinel) { double(:sentinel) }
    before { described_class.action_bindings(sentinel) }

    it "sets and returns an object" do
      expect(described_class.action_bindings).to eq sentinel
    end
  end
end

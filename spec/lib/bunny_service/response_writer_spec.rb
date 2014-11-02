describe BunnyService::ResponseWriter do

  let(:response) { BunnyService::ResponseWriter.new }

  describe "#respond_with" do

    it "sets the status to 200" do
      response.respond_with(something: true)
      expect(response.status).to eq(200)
    end

    context "the body is an exception" do
      let(:e) { Exception.new("asdasd") }
      it "sets the status to 500" do
        response.respond_with(e)
        expect(response.status).to eq(500)
      end
      it "calls respond_with_exception" do
        expect(response).to receive(:respond_with_exception).with(e)
        response.respond_with(e)
      end
    end
  end

  describe "#respond_with_exception" do
    let(:e) { double(message: "some message") }
    let(:respond_with_exception) { response.respond_with_exception(e) }

    it "sets the status to 500" do
      respond_with_exception
      expect(response.status).to eq(500)
    end

    it "returns the message in the error_message property" do
      respond_with_exception
      expect(response.body["error_message"]).to eq("some message")
    end

    context "when a status of 404 passed in" do
      let(:respond_with_exception) { response.respond_with_exception(e, 404) }
      it "sets the status to 404" do
        respond_with_exception
        expect(response.status).to eq(404)
      end
    end
  end
end

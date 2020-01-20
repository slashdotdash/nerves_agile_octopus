defmodule NervesAgileOctopus.Agile.ApiImpl do
  @behaviour NervesAgileOctopus.Agile.Impl

  def fetch_unit_rates do
    url =
      'https://api.octopus.energy/v1/products/AGILE-18-02-21/electricity-tariffs/E-1R-AGILE-18-02-21-H/standard-unit-rates/'

    with {:ok, {{'HTTP/1.1', 200, 'OK'}, _headers, body}} <-
           :httpc.request(:get, {url, []}, [], []) do
      Jason.decode(body)
    end
  end
end

defmodule NervesAgileOctopus do
  @behaviour NervesAgileOctopus.Impl

  @implementation Application.get_env(
                    :nerves_agile_octopus,
                    __MODULE__,
                    NervesAgileOctopus.ApiImpl
                  )

  defdelegate fetch_unit_rates, to: @implementation

  defmodule FileImpl do
    @behaviour NervesAgileOctopus.Impl

    def fetch_unit_rates do
      "priv/agile_octopus_unit_rates.json"
      |> File.read!()
      |> Jason.decode!()
    end
  end

  defmodule ApiImpl do
    @behaviour NervesAgileOctopus.Impl

    def fetch_unit_rates do
      url =
        'https://api.octopus.energy/v1/products/AGILE-18-02-21/electricity-tariffs/E-1R-AGILE-18-02-21-H/standard-unit-rates/'

      {:ok, {{'HTTP/1.1', 200, 'OK'}, _headers, body}} = :httpc.request(:get, {url, []}, [], [])

      Jason.decode!(body)
    end
  end
end

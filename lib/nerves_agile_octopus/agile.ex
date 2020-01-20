defmodule NervesAgileOctopus.Agile do
  @behaviour NervesAgileOctopus.Agile.Impl

  @implementation Application.get_env(
                    :nerves_agile_octopus,
                    :fetch_unit_rates,
                    NervesAgileOctopus.Agile.ApiImpl
                  )

  defdelegate fetch_unit_rates, to: @implementation
end

defmodule NervesAgileOctopus.Agile do
  alias NervesAgileOctopus.Agile.ApiImpl

  @behaviour NervesAgileOctopus.Agile.Impl
  @implementation Application.get_env(:nerves_agile_octopus, :fetch_unit_rates, ApiImpl)

  defdelegate fetch_unit_rates, to: @implementation
end

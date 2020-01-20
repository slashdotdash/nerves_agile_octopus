defmodule NervesAgileOctopus.Agile.Impl do
  @callback fetch_unit_rates() :: {:ok, list(map)} | {:error, any()}
end

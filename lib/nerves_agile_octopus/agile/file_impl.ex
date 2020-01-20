defmodule NervesAgileOctopus.Agile.FileImpl do
  @behaviour NervesAgileOctopus.Agile.Impl

  def fetch_unit_rates do
    with {:ok, file} <- File.read("priv/agile_octopus_unit_rates.json") do
      Jason.decode(file)
    end
  end
end

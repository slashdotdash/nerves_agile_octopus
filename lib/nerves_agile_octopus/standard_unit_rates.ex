defmodule NervesAgileOctopus.StandardUnitRates do
  use GenServer

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def list_unit_rates(timeout \\ 5000) do
    GenServer.call(__MODULE__, :list_unit_rates, timeout)
  end

  @impl GenServer
  def init(_init_arg) do
    {:ok, [], {:continue, :fetch_unit_rates}}
  end

  @impl GenServer
  def handle_continue(:fetch_unit_rates, _state) do
    unit_rates =
      NervesAgileOctopus.fetch_unit_rates()
      |> Map.fetch!("results")
      |> parse_unit_rates()
      |> Enum.sort_by(& &1.valid_from)

    {:noreply, unit_rates}
  end

  @impl GenServer
  def handle_call(:list_unit_rates, _from, state) do
    {:reply, {:ok, state}, state}
  end

  defp parse_unit_rates(unit_rates, acc \\ []) do
    Enum.reduce(unit_rates, acc, fn data, acc ->
      valid_from = data |> Map.fetch!("valid_from") |> datetime_from_iso8601!()
      valid_to = data |> Map.fetch!("valid_to") |> datetime_from_iso8601!()

      unit_rate = %{
        valid_from: valid_from,
        valid_to: valid_to,
        value_exc_vat: Map.fetch!(data, "value_exc_vat"),
        value_inc_vat: Map.fetch!(data, "value_inc_vat")
      }

      [unit_rate | acc]
    end)
  end

  defp datetime_from_iso8601!(string) do
    {:ok, dt, 0} = DateTime.from_iso8601(string)
    dt
  end
end

defmodule NervesAgileOctopus.Agile.StandardUnitRates do
  use GenServer
  require Logger

  alias NervesAgileOctopus.Agile

  defmodule State do
    defstruct [:timezone, unit_rates: [], subscribers: [], attempts: 0]

    def new(opts) do
      %State{
        timezone: Keyword.fetch!(opts, :timezone)
      }
    end

    def increment_attempts(%State{} = state) do
      %State{attempts: attempts} = state

      %State{state | attempts: attempts + 1}
    end

    def set_unit_rates(%State{} = state, new_unit_rates) do
      %State{subscribers: subscribers, unit_rates: old_unit_rates} = state

      unless new_unit_rates == [] || new_unit_rates == old_unit_rates do
        for {pid, _ref} <- subscribers do
          notify_subscriber(pid, new_unit_rates)
        end

        state = %State{state | unit_rates: new_unit_rates, attempts: 0}

        {:ok, state}
      else
        :error
      end
    end

    def add_subscriber(%State{} = state, pid) do
      %State{subscribers: subscribers, unit_rates: unit_rates} = state

      ref = Process.monitor(pid)

      unless is_nil(unit_rates) do
        notify_subscriber(pid, unit_rates)
      end

      %State{state | subscribers: [{pid, ref} | subscribers]}
    end

    def remove_subscriber(%State{} = state, {pid, ref}) do
      %State{subscribers: subscribers} = state

      subscribers =
        Enum.reduce(subscribers, [], fn
          {^pid, ^ref}, acc -> acc
          subscriber, acc -> [subscriber | acc]
        end)

      %State{state | subscribers: subscribers}
    end

    defp notify_subscriber(pid, unit_rates) do
      send(pid, {:agile_standard_unit_rates, unit_rates})
    end
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, State.new(opts), name: __MODULE__)
  end

  def subscribe_unit_rates(timeout \\ 5000) do
    GenServer.call(__MODULE__, :subscribe_unit_rates, timeout)
  end

  @impl GenServer
  def init(%State{} = state) do
    {:ok, state, {:continue, :fetch_unit_rates}}
  end

  @impl GenServer
  def handle_continue(:fetch_unit_rates, %State{} = state), do: fetch_unit_rates(state)

  @impl GenServer
  def handle_call(:subscribe_unit_rates, {pid, _tag}, %State{} = state) do
    state = State.add_subscriber(state, pid)

    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_info(:fetch_unit_rates, %State{} = state), do: fetch_unit_rates(state)

  @impl GenServer
  def handle_info({:DOWN, ref, :process, pid, _reason}, %State{} = state) do
    state = State.remove_subscriber(state, {pid, ref})

    {:noreply, state}
  end

  defp fetch_unit_rates(%State{} = state) do
    Logger.debug(fn -> "Attempting to fetch Agile standard unit rates" end)

    state = State.increment_attempts(state)

    with {:ok, unit_rates} <- Agile.fetch_unit_rates(),
         {:ok, results} <- Map.fetch(unit_rates, "results") do
      unit_rates =
        results
        |> parse_unit_rates()
        |> Enum.sort_by(& &1.valid_from)

      Logger.debug(fn ->
        "Successfully fetched Agile standard unit rates: " <> inspect(unit_rates)
      end)

      case State.set_unit_rates(state, unit_rates) do
        {:ok, state} ->
          schedule_daily_fetch(state)

          {:noreply, state}

        :error ->
          # Unchanged unit rate prices, try again in 30 minutes with exponential backoff
          schedule_fetch(state, in: :timer.minutes(30), max: :timer.hours(1))

          {:noreply, state}
      end
    else
      {:error, error} ->
        Logger.error(fn ->
          "Failed to fetch Agile standard unit rates due to: " <> inspect(error)
        end)

        # Try again after 10s, with exponential backoff
        schedule_fetch(state, in: :timer.seconds(10), max: :timer.hours(1))

        {:noreply, state}
    end
  end

  defp schedule_fetch(%State{} = state, opts) do
    %State{attempts: attempts} = state

    initial_interval = Keyword.get(opts, :in, :timer.seconds(10))
    interval = initial_interval * attempts * attempts

    interval =
      case Keyword.get(opts, :max) do
        nil -> interval
        max -> min(interval, max)
      end

    Logger.debug(fn -> "Schedule fetch unit rates in #{interval}ms" end)

    Process.send_after(self(), :fetch_unit_rates, interval)
  end

  defp schedule_daily_fetch(%State{} = state) do
    %State{timezone: timezone} = state

    now = Timex.now(timezone)

    # Refresh daily at 6pm
    refresh_at = Timex.set(now, hour: 18, minute: 0, second: 0)

    refresh_at =
      if Timex.after?(refresh_at, now) do
        refresh_at
      else
        Timex.add(refresh_at, Timex.Duration.from_days(1))
      end

    interval = Timex.diff(refresh_at, now, :milliseconds)

    duration =
      interval
      |> Timex.Duration.from_milliseconds()
      |> Timex.Format.Duration.Formatters.Humanized.format()

    Logger.debug(fn ->
      "Schedule daily fetch unit rates in " <>
        duration <>
        " at " <>
        Timex.format!(refresh_at, "{h24}:{m}")
    end)

    Process.send_after(self(), :fetch_unit_rates, interval)
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

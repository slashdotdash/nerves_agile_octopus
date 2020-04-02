defmodule NervesAgileOctopus.Scenes.Main do
  use Scenic.Scene

  import Scenic.Primitives

  alias Scenic.Graph
  alias NervesAgileOctopus.Agile.StandardUnitRates

  @font :roboto
  @font_size 20
  @width 212
  @height 104

  @impl Scenic.Scene
  def init(_args, _opts) do
    :ok = StandardUnitRates.subscribe_unit_rates()

    state = %{
      timezone: Application.get_env(:nerves_agile_octopus, :timezone, "Etc/UTC"),
      unit_rates: []
    }

    {:ok, state}
  end

  @impl Scenic.Scene
  def handle_info({:agile_standard_unit_rates, unit_rates}, state) do
    state |> Map.put(:unit_rates, unit_rates) |> render_unit_rates()
  end

  @impl Scenic.Scene
  def handle_info(:render_unit_rates, state) do
    render_unit_rates(state)
  end

  defp render_unit_rates(state) do
    unit_rates = applicable_unit_rates(state)
    timezone = Map.fetch!(state, :timezone)

    unless unit_rates == [] do
      max_value_inc_vat =
        case Enum.max_by(unit_rates, & &1.value_inc_vat) do
          %{value_inc_vat: value_inc_vat} -> value_inc_vat
          nil -> 35.0
        end

      max_value_inc_vat = max(max_value_inc_vat, 24)

      current_unit_rate = hd(unit_rates)
      pixels_per_block = floor(@width / length(unit_rates))
      pixels_per_value = floor(@height / max_value_inc_vat)

      graph =
        Graph.build(font_size: @font_size, font: @font, theme: :light)
        |> rectangle({@width, @height}, fill: :white)
        |> plot_chart(unit_rates, max_value_inc_vat, pixels_per_block, pixels_per_value)
        |> draw_current_price(current_unit_rate, pixels_per_block, pixels_per_value, timezone)

      state = Map.put(state, :graph, graph)

      schedule_refresh()

      {:noreply, state, push: graph}
    else
      {:noreply, state}
    end
  end

  defp applicable_unit_rates(state) do
    unit_rates = Map.get(state, :unit_rates, [])
    from = DateTime.utc_now() |> DateTime.add(-:timer.minutes(30), :millisecond)

    unit_rates
    |> Enum.filter(fn %{valid_from: valid_from} -> after?(valid_from, from) end)
    # Only take next 12 hrs worth of half-hourly data (24 values)
    |> Enum.take(24)
  end

  defp after?(datetime1, datetime2) do
    case DateTime.compare(datetime1, datetime2) do
      :gt -> true
      :eq -> true
      :lt -> false
    end
  end

  defp draw_current_price(graph, nil, _pixels_per_block, _pixels_per_value, _timezone), do: graph

  defp draw_current_price(graph, unit_rate, pixels_per_block, pixels_per_value, timezone) do
    %{valid_from: valid_from, valid_to: valid_to, value_inc_vat: value_inc_vat} = unit_rate

    y = @height - round(value_inc_vat * pixels_per_value)

    {:ok, from} = Timex.to_datetime(valid_from, timezone) |> Timex.format("{h24}:{m}")
    {:ok, to} = Timex.to_datetime(valid_to, timezone) |> Timex.format("{h24}:{m}")

    x = floor(pixels_per_block / 2)

    graph
    |> line({{x, 10}, {x, y}}, stroke: {1, :black})
    |> line({{x, 10}, {x + 10, 10}}, stroke: {1, :black})
    |> text("#{Float.round(value_inc_vat, 2)}p  #{from}-#{to}",
      font_size: 16,
      fill: :black,
      translate: {x + 10, 15},
      text_align: :left
    )
  end

  defp plot_chart(graph, unit_rates, max_value_inc_vat, pixels_per_block, pixels_per_value) do
    graph =
      [0, 5, 10, 15, 20, 25, 30, 35]
      |> Enum.filter(&(&1 <= max_value_inc_vat))
      |> Enum.reduce(graph, fn index, graph ->
        graph
        |> line(
          {{0, @height - index * pixels_per_value}, {@width, @height - index * pixels_per_value}},
          stroke: {1, :black}
        )
        |> text("#{index}",
          font_size: 12,
          fill: :black,
          translate: {@width - 1, @height - 2 - index * pixels_per_value},
          text_align: :right
        )
      end)

    unit_rates
    |> Enum.with_index()
    |> Enum.reduce(graph, fn {unit_rate, index}, graph ->
      %{value_inc_vat: value_inc_vat} = unit_rate

      height = round(value_inc_vat * pixels_per_value)

      rectangle = {pixels_per_block, -height}
      translate = {index * pixels_per_block, @height}

      cond do
        value_inc_vat >= 20 ->
          rectangle(graph, rectangle, t: translate, fill: :red)

        value_inc_vat >= 8 ->
          rectangle(graph, rectangle, t: translate, fill: :black)

        true ->
          graph
          |> rectangle(rectangle, t: translate, fill: :white)
          # Black border around white block
          |> rectangle(rectangle, t: translate, stroke: {1, :black})
      end
    end)
  end

  # Refresh graph every 30 minutes.
  defp schedule_refresh do
    now = DateTime.utc_now()

    half_past = Timex.set(now, minute: 30, second: 0)
    next_hour = now |> Timex.shift(hours: 1) |> Timex.set(minute: 0, second: 0)

    interval =
      if Timex.after?(half_past, now) do
        Timex.diff(half_past, now, :milliseconds)
      else
        Timex.diff(next_hour, now, :milliseconds)
      end

    Process.send_after(self(), :render_unit_rates, interval + 1_000)
  end
end

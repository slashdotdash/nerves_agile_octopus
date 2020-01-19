defmodule NervesAgileOctopus.Scenes.Main do
  use Scenic.Scene

  import Scenic.Primitives

  alias Scenic.Graph

  @font :roboto
  @font_size 20
  @width 212
  @height 104

  def init(_args, _opts) do
    {:ok, unit_rates} = NervesAgileOctopus.StandardUnitRates.list_unit_rates()

    from = DateTime.utc_now() |> DateTime.add(-:timer.minutes(30), :millisecond)

    unit_rates = Enum.filter(unit_rates, fn unit_rate -> after?(unit_rate.valid_from, from) end)

    max_value_inc_vat =
      case Enum.max_by(unit_rates, & &1.value_inc_vat) do
        %{value_inc_vat: value_inc_vat} -> value_inc_vat
        nil -> 35.0
      end

    pixels_per_value = round(@height / max_value_inc_vat)

    graph =
      Graph.build(font_size: @font_size, font: @font, theme: :light)
      |> rectangle({@width, @height}, fill: :white)
      |> plot_chart(unit_rates, max_value_inc_vat, pixels_per_value)
      |> draw_current_price(hd(unit_rates), pixels_per_value)

    state = %{
      graph: graph
    }

    {:ok, state, push: graph}
  end

  defp after?(datetime1, datetime2) do
    case DateTime.compare(datetime1, datetime2) do
      :gt -> true
      :eq -> true
      :lt -> false
    end
  end

  defp draw_current_price(graph, nil, _pixels_per_value), do: graph

  defp draw_current_price(graph, unit_rate, pixels_per_value) do
    %{value_inc_vat: value_inc_vat} = unit_rate

    y = @height - round(value_inc_vat * pixels_per_value)

    graph
    |> line({{2, 10}, {2, y}}, stroke: {1, :black})
    |> line({{2, 10}, {15, 10}}, stroke: {1, :black})
    |> text("#{value_inc_vat}p",
      font_size: 16,
      fill: :black,
      translate: {15, 15},
      text_align: :left
    )
  end

  defp plot_chart(graph, unit_rates, max_value_inc_vat, pixels_per_value) do
    graph =
      [0, 5, 10, 15, 20, 25, 30, 35]
      |> Enum.filter(&(&1 <= max_value_inc_vat))
      |> Enum.reduce(graph, fn index, graph ->
        graph
        |> line({{0, index * pixels_per_value}, {@width, index * pixels_per_value}},
          stroke: {1, :black}
        )
        |> text("#{index}p",
          font_size: 12,
          fill: :black,
          translate: {@width, @height - 5 - index * pixels_per_value},
          text_align: :right
        )
      end)

    unit_rates
    |> Enum.with_index()
    |> Enum.reduce(graph, fn {unit_rate, index}, graph ->
      height = round(unit_rate.value_inc_vat * pixels_per_value)

      fill =
        cond do
          unit_rate.value_inc_vat >= 20 -> :red
          unit_rate.value_inc_vat >= 8 -> :black
          true -> :white
        end

      graph
      |> rectangle({4, -height}, t: {index * 4, @height}, fill: fill)
      |> rectangle({4, -height}, t: {index * 4, @height}, stroke: {1, :black})
    end)
  end
end

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

    # graph =
    #   Graph.build(font_size: @font_size, font: @font, theme: :light)
    #   |> rectangle({212, 32}, fill: :red)
    #   |> rectangle({212, 64}, t: {0, 32}, fill: :white)
    #   |> rectangle({212, 8}, t: {0, 32 + 64}, fill: :red)
    #   |> do_aligned_text("HELLO", :white, @font_size + 6, 212, 20)
    #   |> do_aligned_text("my name is", :white, @font_size - 8, 212, 28)
    #   |> do_aligned_text("Inky", :black, @font_size + 32, 212, 80)

    graph = Graph.build(font_size: @font_size, font: @font, theme: :light)

    graph =
      unit_rates
      |> Enum.with_index()
      |> Enum.reduce(graph, fn {unit_rate, index}, graph ->
        height = round(unit_rate.value_inc_vat * 4)

        fill =
          cond do
            unit_rate.value_inc_vat >= 20 -> :red
            unit_rate.value_inc_vat >= 8 -> :black
            true -> :white
          end

        graph
        |> rectangle({4, -height}, t: {index * 4, 104}, fill: fill)
        |> rectangle({4, -height}, t: {index * 4, 104}, stroke: {1, :black})
      end)

    state = %{
      graph: graph
    }

    {:ok, state, push: graph}
  end

  defp do_aligned_text(graph, text, fill, font_size, width, vpos) do
    text(graph, text,
      font_size: font_size,
      fill: fill,
      translate: {width / 2, vpos},
      text_align: :center
    )
  end
end

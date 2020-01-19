defmodule NervesAgileOctopus.InkyDisplay do
  use GenServer

  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, [])
  end

  @impl GenServer
  @spec init(any) :: {:ok, pid}
  def init(_init_arg) do
    IO.puts("Initializing inky...")

    {:ok, pid} =
      Inky.start_link(:phat, :red, %{
        border: :accent,
        # Use the configured module if available, otherwise RpiHAL
        hal_mod: Application.get_env(:inky, :hal_module, Inky.RpiHAL)
      })

    IO.puts("Rendering quadrants pixel data to display...")

    Inky.set_pixels(pid, fn x, y, w, h, _acc ->
      x_high = x > w / 2
      y_high = y > h / 2
      x_odd = rem(x, 2) == 0

      case x_high do
        true ->
          case y_high do
            true ->
              :accent

            false ->
              case x_odd do
                true -> :white
                false -> :black
              end
          end

        false ->
          case y_high do
            true -> :black
            false -> :white
          end
      end
    end)

    IO.puts("Rendered")

    {:ok, pid}
  end
end

defmodule SystemCheck do
  require Logger

  def ensure_environment do
    set_time()
  end

  def set_time(tries \\ 0)

  def set_time(tries) when tries < 4 do
    Process.sleep(1000 * tries)

    case :inet_res.gethostbyname('0.pool.ntp.org') do
      {:ok, {:hostent, _url, _, _, _, _}} ->
        :ok

      {:error, err} ->
        Logger.error("Failed to set time (#{tries}): DNS Lookup: #{inspect(err)}")
        set_time(tries + 1)
    end
  end

  def set_time(_tries), do: :reboot
end

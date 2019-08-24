## Annelid


[![biohazard level](doc/bsl_shield.svg)](https://en.wikipedia.org/wiki/Biosafety_level)
[![containment status](doc/containment_shield.svg)](https://en.wikipedia.org/wiki/Biocontainment)


Annelid is an evasive, self-healing process that replicates and spreads throughout a cluster of Elixir nodes.

It operates by sending itself back and forth in AST form to other nodes in the cluster, like a contagious [quine](https://en.wikipedia.org/wiki/Quine_%28computing%29).

ANNELID IS NOT SUITABLE FOR ANY PURPOSE.

![annelid](doc/annelid.gif)

__Infection__

- Annelid can be loaded directly into a cluster by simply infecting a local node, then connecting the node to a remote cluster.

- When new nodes connect, it spreads itself by transmitting its ~~mRNA~~ AST to the new node for evaluation.

- It survives and re-infects the cluster during rolling deployments.

- To prevent simultaneous re-infection by multiple nodes, it sets a global lock and halts if it can't be acquired.

__Self Healing__

- When an Annelid process starts, it spawns a free-floating "supervisor" process. The two mutually monitor and restart the other if either is killed.

__Evasion__

- Annelid doesn't require inclusion in a project's repository or participation in the normal deploy cycle.

- There are no modules, it can't be detected by examining the module namespace. It leaves no compiled artifacts on disk.

- To stop the user from setting the infection lock ahead of time (and thus vaccinating the node), the lock is rotated every second to a calculated value based on a shared secret seed and the current time.

- Internal timer messages are obfuscated to evade detection via `:erlang.trace/3`.


__Additional sick features__

- Emoji
- Y Combinators
- Annoying quotes from [Hackers](https://en.wikipedia.org/wiki/Hackers_(film)).

-------------------

ANNELID IS NOT SUITABLE FOR ANY PURPOSE.

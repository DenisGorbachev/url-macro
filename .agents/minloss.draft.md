# Minloss draft

Write code to minimize losses.

Types of losses:

- Unavoidable losses (costs).
- Avoidable losses (mistakes).

Most fundamental principle of software development is to minimize loss.

We write code to reduce loss in several ways:

1. Loss of time. Programs automate and accelerate actions that would otherwise take people longer to perform.
2. Loss from mistakes. Software should reduce frequency and impact of errors — both human errors (misclicks, bad inputs, forgotten steps) and system errors (bugs, misconfiguration, unexpected envs). This includes minimizing cost of failure when mistakes happen.
3. Loss of resources during execution. Programs should run within practical limits: CPU time, memory, disk space, network bandwidth, monetary cost. Efficiency matters because these resources are finite.
4. Loss of data. Systems should minimize probability and severity of data loss, through durability mechanisms (backups, redundancy, transactions, checksums, journaling, replication) and careful handling of partial failures.

There is hierarchy of costs and hard constraints. Every host env imposes caps: limited memory, disk space, runtime, deadlines. A program that cannot operate within those constraints is not usable. In that case, it does not minimize loss at all — it increases it, because user spends time attempting to use it and gets no result.

Costs can also be shifted over time. We can accept one-time setup cost in order to reduce ongoing costs. This is what programming is: we pay upfront cost of writing software to reduce recurring cost of executing process in future.

Concrete example: program that reads entire dataset into memory and processes it all at once may crash if there is not enough memory. For large enough dataset, this crash is guaranteed. A crash is extreme form of loss: time is wasted, work may be discarded, data may be corrupted or left in inconsistent state. The better design is one that respects constraints — streaming, batching, incremental processing, backpressure, explicit resource bounds — so program continues to produce results instead of failing catastrophically.

Some losses are reversible (e.g.: program allocates memory, then frees it).
Some losses are irreversible (e.g.: time).

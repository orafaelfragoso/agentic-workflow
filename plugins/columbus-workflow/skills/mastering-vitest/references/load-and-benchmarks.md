# Benchmarks & Load Testing

> Load when: measuring code speed (`vitest bench`) or system capacity under
> traffic (k6/autocannon). These are different questions — don't conflate them.

## Micro-benchmarks: `vitest bench`

For comparing implementations of the same function (powered by Tinybench):

```ts
// sort.bench.ts
import { bench, describe } from "vitest";

describe("sort 10k items", () => {
  bench("Array.prototype.sort", () => {
    [...data].sort(byPrice);
  });
  bench("toSorted", () => {
    data.toSorted(byPrice);
  });
});
```

```bash
vitest bench                      # runs *.bench.ts, reports ops/sec ± margin
vitest bench --compare main.json  # compare against a saved baseline (--outputJson)
```

Honest benchmarking rules:

- Benchmark **realistic inputs at realistic sizes** — V8 optimizes tiny hot loops into numbers that don't transfer.
- Beware dead-code elimination: consume the result (assign/accumulate) so the JIT can't delete the work.
- Run on quiet hardware; CI runners are noisy — compare _relative_ results from the same run, never absolute numbers across machines.
- Keep `*.bench.ts` out of the test pipeline (separate script/job); benches are slow by design and shouldn't gate merges.
- Benchmark only code that profiling showed to be hot. A 10× win in a function taking 0.1% of runtime is a 0.09% win.

## Load testing: k6 (not Vitest)

Load tests measure a **system** — latency percentiles, error rates, saturation —
under concurrent traffic. Vitest workers can't generate calibrated load; use
k6, which scripts scenarios in JS and runs them in an efficient Go engine:

```js
// load/checkout.js
import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  stages: [
    { duration: "1m", target: 50 }, // ramp up
    { duration: "3m", target: 50 }, // steady state
    { duration: "1m", target: 0 }, // ramp down
  ],
  thresholds: {
    http_req_duration: ["p(95)<400"], // SLO as a pass/fail gate
    http_req_failed: ["rate<0.01"],
  },
};

export default function () {
  const res = http.post(`${__ENV.BASE_URL}/api/checkout`, payload(), params());
  check(res, { "status 200": (r) => r.status === 200 });
  sleep(1);
}
```

```bash
k6 run -e BASE_URL=https://staging.example.com load/checkout.js
```

Test types worth distinguishing (same script, different `stages`):

| Type   | Shape                    | Question answered                        |
| ------ | ------------------------ | ---------------------------------------- |
| Smoke  | 1–5 VUs, a minute        | does the script & system basically work? |
| Load   | expected traffic, steady | do we meet SLOs at normal volume?        |
| Stress | ramp past expected peak  | where and how does it break?             |
| Soak   | normal load, hours       | leaks, drift, exhaustion over time?      |
| Spike  | sudden jump, then drop   | does it survive and recover from bursts? |

Practices:

- **Thresholds are the assertion.** Encode SLOs in `thresholds` so the run exits non-zero on violation — that's what makes load tests CI-able (on a schedule or pre-release, never per-PR).
- Target a production-like environment, **never** shared production without explicit authorization and a plan; warn downstream services you'll saturate.
- Report p95/p99, not averages — averages hide the tail users actually feel.
- For a quick single-endpoint sanity check, `autocannon` (`npx autocannon -c 100 -d 30 url`) is a lighter alternative; reach for k6 once scenarios, stages, or thresholds matter.

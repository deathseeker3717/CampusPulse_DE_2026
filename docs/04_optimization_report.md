# Query Optimization ReportQuery Optimization Report

## Summary

- Database: PostgreSQL (`linkedin` schema); benchmarked on the same seed dataset and laptop.
- Baseline: 3 runs per query; optimized: 5 runs per query, using `benchmarks/run_benchmark.sh` as required.
- All 30 queries completed in the optimized benchmark.
- Sum of per-query average times: **522.234 ms baseline** vs **146.299 ms optimized** (71.99% lower). This is the sum of individual query averages, not a single end-to-end latency.
- Eight semantics-preserving rewrites were checked using bidirectional `EXCEPT ALL`; all had zero differing rows. R13 was validated separately because the original `NOT IN` is NULL-buggy.

## Before/after optimization table

| Query | Type | Before (ms) | Problem / plan observation | Optimization | After (ms) | Improvement | Same result? |
|---|---|---:|---|---|---:|---:|---|
| R01 | READ | 6.142 | Member PK lookup plus position/company lookups | Existing PKs and idx_positions_member_start support the joins | 0.062 | 99.0% | Yes |
| R02 | READ | 3.254 | Position lookup and ordering | idx_positions_member_start supports member lookup/order | 0.136 | 95.8% | Yes |
| R03 | READ | 3.655 | OR across both connection endpoints | UNION ALL with PK lookup and idx_connections_member_b | 0.059 | 98.4% | Yes |
| R04 | READ | 9.556 | OR across both endpoints for each member | Two indexed endpoint branches per member, then join | 0.125 | 98.7% | Yes |
| R05 | READ | 22.978 | Second-degree traversal across connection endpoints | Endpoint indexes support both directions; existing query retained | 1.106 | 95.2% | Yes |
| R06 | READ | 3.739 | Selective title/status filters; jobs scan remains | No dedicated index added; plan still scans jobs | 3.365 | 10.0% | Yes |
| R07 | READ | 4.860 | Join/filter across job_skills, jobs and member_skills | Existing PK/unique indexes; sequential scans remain reasonable | 4.639 | 4.5% | Yes |
| R08 | READ | 0.706 | Lookup by job_id | idx_applications_job_date | 0.096 | 86.4% | Yes |
| R09 | READ | 2.242 | Member application lookup | Existing unique job/member index; query unchanged | 2.054 | 8.4% | Yes |
| R10 | READ | 3.354 | Filter pending invitations by recipient | idx_invitations_recipient_status | 0.130 | 96.1% | Yes |
| R11 | READ | 6.806 | Filter profile views by viewed member and date | idx_profile_views_viewed_date | 0.159 | 97.7% | Yes |
| R12 | READ | 4.692 | Small company/positions aggregation; scans remain | No additional index; query unchanged | 4.642 | 1.1% | Yes |
| R13 | READ | 19.330 | NOT IN is NULL-sensitive; original returns no rows when subquery has NULL | Replaced NOT IN with NULL-safe NOT EXISTS; partial idx_profile_views_viewer | 10.331 | 46.6% | Correctness fix; not equivalent to buggy original |
| R14 | READ | 8.610 | Aggregate hired applications by company | No targeted rewrite; query unchanged | 7.839 | 9.0% | Yes |
| R15 | READ | 7.403 | Year extraction is non-sargable; jobs scan remains | Replaced EXTRACT(YEAR) with half-open 2026 timestamp range | 7.261 | 1.9% | Yes |
| R16 | READ | 1.622 | Small jobs/cities aggregation | No targeted index; query unchanged | 1.581 | 2.5% | Yes |
| R17 | READ | 33.793 | Window LEAD over positions | idx_positions_member_start supports partition/order access | 26.512 | 21.5% | Yes |
| R18 | READ | 10.149 | Skill lookup and member skill ordering | idx_member_skills_skill_endorsements | 2.367 | 76.7% | Yes |
| R19 | READ | 196.938 | Correlated subqueries repeatedly count jobs/applications per company | Pre-aggregate open jobs and applications once, then join; idx_applications_applied_at | 3.610 | 98.2% | Yes; preserve lower bound only |
| R20 | READ | 6.097 | Casting applied_at to date prevents direct range index use | Half-open timestamp range; idx_applications_applied_at | 1.116 | 81.7% | Yes |
| R21 | READ | 77.306 | Window row_number and sort over member_skills | DISTINCT ON with matching composite index | 19.419 | 74.9% | Yes |
| R22 | READ | 28.356 | Large OFFSET requires walking skipped rows | idx_applications_applied_at DESC covering index | 6.470 | 77.2% | Yes |
| R23 | READ | 5.236 | Case-insensitive lower(email) lookup | Expression index idx_members_lower_email | 0.045 | 99.1% | Yes |
| R24 | READ | 8.280 | Broad invitation aggregation; sequential scan is reasonable | No rewrite; query unchanged | 8.266 | 0.2% | Yes |
| R25 | READ | 32.878 | Window LAG over positions | idx_positions_member_start supports partition/order access | 24.124 | 26.6% | Yes |
| W01 | WRITE | 0.924 | Insert with conflict check | Existing unique constraint handles conflict check | 0.769 | 16.8% | Yes |
| W02 | WRITE | 2.686 | Find oldest pending invitation | idx_invitations_recipient_status | 0.467 | 82.6% | Yes |
| W03 | WRITE | 2.612 | Find oldest pending invitation before insert | idx_invitations_recipient_status | 0.533 | 79.6% | Yes |
| W04 | WRITE | 2.893 | Update all expired open jobs; broad update | Sequential scan is appropriate for broad update | 2.862 | 1.1% | Yes |
| W05 | WRITE | 5.137 | Bulk update applications joined to TCS jobs; index maintenance overhead | No dedicated index added for this update; existing indexes add write maintenance | 6.154 | -19.8% | Yes |
| **Total of averages** | — | **522.234** | — | — | **146.299** | **71.99%** | — |

Improvement percentage is `(before − after) / before × 100`. R13's percentage is only a timing comparison: the original query returns no rows because `profile_views.viewer_id` contains NULLs, while the corrected query returns 6,513 members. The seed contains 50,173 NULL viewer rows.

## Indexes created and measured storage

| Table | Index | Size | Table size | Index / table |
|---|---|---:|---:|---:|
| applications | idx_applications_applied_at | 7280 kB | 11 MB | 64.63% |
| applications | idx_applications_job_date | 4640 kB | 11 MB | 41.19% |
| connections | idx_connections_member_b | 8736 kB | 9984 kB | 87.50% |
| invitations | idx_invitations_recipient_status | 4248 kB | 5144 kB | 82.58% |
| member_skills | idx_member_skills_skill_endorsements | 6560 kB | 9472 kB | 69.26% |
| members | idx_members_lower_email | 1952 kB | 5248 kB | 37.20% |
| positions | idx_positions_member_start | 2208 kB | 7808 kB | 28.28% |
| profile_views | idx_profile_views_viewed_date | 7944 kB | 10112 kB | 78.56% |
| profile_views | idx_profile_views_viewer | 1824 kB | 10112 kB | 18.04% |

Index/table percentages compare each individual index size with its heap table size; they are not percentages of total database size. The two indexes on `applications` and the two on `profile_views` are separate structures.

### Index purpose

- `idx_positions_member_start (member_id, start_date)`: R01, R02, R17 and R25; equality on member and ordering/window partition by member then start date.
- `idx_connections_member_b (member_b, connected_at DESC) INCLUDE (member_a)`: reverse-endpoint lookups for R03–R05.
- `idx_invitations_recipient_status (recipient_id, status, invitation_id) INCLUDE (sender_id, sent_at, note)`: recipient/status lookups and oldest-pending invitation work in R10, W02 and W03.
- `idx_profile_views_viewed_date (viewed_id, viewed_at) INCLUDE (viewer_id)`: R11's viewed-member and date filter.
- `idx_profile_views_viewer (viewer_id) WHERE viewer_id IS NOT NULL`: NULL-safe anti-join for R13.
- `idx_applications_job_date (job_id, applied_at)`: job-specific application access, including R08 and write workload access where useful.
- `idx_applications_applied_at (applied_at DESC) INCLUDE (application_id, job_id, member_id, status)`: date-range analytics and newest-first pagination, including R19, R20 and R22.
- `idx_member_skills_skill_endorsements (skill_id, endorsements DESC, member_id)`: R18 and R21 skill/endorsement access.
- `idx_members_lower_email (lower(email))`: R23 case-insensitive email lookup.

## Correctness validation

- R03, R04, R15, R19, R20, R21, R23 and R25: bidirectional `EXCEPT ALL` checks each reported **0 differing rows**.
- R13: original `NOT IN (SELECT viewer_id ...)` is poisoned by NULLs in the subquery and returns no members. Replaced with `NOT EXISTS`; corrected result count: **6,513**. NULL viewer rows: **50,173**.
- R03/R04 `UNION ALL` rewrite assumption checked: self-connection count is **0**.
- R15/R20 date boundaries use `+05:30`, matching session timezone `Asia/Kolkata`.
- R19 keeps only the original lower-bound condition `applied_at >= 2026-06-01`; no upper boundary was added.

## Write overhead

| Write | Baseline (ms) | Optimized (ms) | Change |
|---|---:|---:|---:|
| W01 | 0.924 | 0.769 | -0.155 ms (+16.8% improvement) |
| W02 | 2.686 | 0.467 | -2.219 ms (+82.6% improvement) |
| W03 | 2.612 | 0.533 | -2.079 ms (+79.6% improvement) |
| W04 | 2.893 | 2.862 | -0.031 ms (+1.1% improvement) |
| W05 | 5.137 | 6.154 | +1.017 ms (-19.8% improvement) |

W05 became slower by **1.017 ms (19.8%)**. The measured workload updates matching applications and the indexes on affected rows add maintenance work. W04 was effectively unchanged. The W01–W03 timings improved, mainly due to faster supporting lookups.

## Remaining bottlenecks and limitations

- R25 remains the slowest optimized read query at 24.124 ms; its window `LAG` still processes the positions history.
- R21 remains at 19.419 ms because it must identify a winner for each skill across the member-skill relation.
- R14 and R24 are aggregate/report queries where sequential scans can be appropriate for the amount of data read.
- R06, R07, R12, R14, R15, R16 and R24 show limited improvement; the plan and table size do not justify adding speculative indexes solely to eliminate sequential scans.
- R22 still uses OFFSET pagination; the index reduces sorting/scanning work, but the database must still walk past the skipped rows.

## EXPLAIN plan evidence

The benchmark script saved the complete raw plans for every query in `benchmarks/results/baseline/` and `benchmarks/results/optimized/`. The five largest improvements by absolute time reduction are R19, R21, R17, R25 and R05; R23, R01, R04 and R03 also have particularly large relative speedups. Preserve and submit the corresponding raw plan pairs from those directories. The CSV scan-node summaries are not substitutes for the full `EXPLAIN (ANALYZE, BUFFERS)` plans.

## Method and reproducibility

Baseline benchmark used the required baseline phase (3 repetitions per query); optimized benchmark used 5 repetitions and `sql/06_optimized_queries.sql`. Both summary CSVs and raw plans should be committed. All timing values above are transcribed from the supplied baseline and optimized summary CSVs. Do not compare absolute times across different machines or database configurations.

## Conclusion

The tuned workload's summed per-query average time fell by 71.99%. The largest gains came from replacing correlated aggregation in R19, indexed endpoint lookups in R03/R04, and expression/index-supported access in R23. The NULL-related R13 correctness bug was fixed. The main trade-off is modest W05 write overhead and the remaining window/aggregation costs in R21 and R25.

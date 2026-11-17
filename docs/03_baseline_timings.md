# Baseline Query Timings

## 1. Benchmark Setup

| Item | Details |
|---|---|
| Database | `linkedin_db` |
| PostgreSQL | 18.4 |
| Benchmark phase | Baseline |
| Runs per query | 3 |
| Measurement | `EXPLAIN (ANALYZE, BUFFERS)` |
| Benchmark script | `benchmarks/run_benchmark.sh` |

All write queries (W01–W05) were executed inside transactions and rolled back after measurement.

## 2. Execution Timings

Times are in milliseconds (ms). Individual run timings should be filled from the raw benchmark files.


| SQL Query | Type | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Average (ms) |
|---|---|---:|---:|---:|---:|
| R01: Profile header: member 1023 with their current position and company | READ | 8.433 | 5.247 | 4.746 | 6.142 |
| R02: Experience section: member 1023's positions, latest first | READ | 3.636 | 3.129 | 2.997 | 3.254 |
| R03: "My Network": everyone connected to member 1023 | READ | 6.420 | 2.306 | 2.240 | 3.655 |
| R04: Profile page: mutual connections of member 1023 and member 356 | READ | 14.681 | 7.144 | 6.844 | 9.556 |
| R05: "People you may know": 2nd-degree connections of member 1023 ranked by mutual connections | READ | 23.207 | 22.899 | 22.828 | 22.978 |
| R06: Job search: open "data analyst" jobs in Bengaluru or remote, posted in the last 30 days of June 2026 | READ | 4.893 | 3.257 | 3.066 | 3.739 |
| R07: "Jobs for you": open jobs that need at least 2 of member 1023's skills | READ | 5.822 | 4.397 | 4.360 | 4.860 |
| R08: Recruiter: applicants of job 14075 by pipeline stage | READ | 1.955 | 0.083 | 0.080 | 0.706 |
| R09: "My Jobs": member 1023's applications with their status | READ | 4.190 | 1.272 | 1.265 | 2.242 |
| R10: Invitations tab: pending invitations received by member 1023 | READ | 5.765 | 2.206 | 2.092 | 3.354 |
| R11: "Who viewed your profile": viewers of member 217 since April 2026 (private-mode viewers counted separately) | READ | 12.015 | 4.401 | 4.002 | 6.806 |
| R12: Company page: current employees of Flipkart and their average tenure in years | READ | 4.935 | 4.628 | 4.513 | 4.692 |
| R13: Engagement: members who have never viewed anyone's profile (for a re-engagement nudge) | READ | 20.977 | 18.429 | 18.583 | 19.330 |
| R14: Talent insights: average days from application to hire, per company (2026 hires) | READ | 10.625 | 7.546 | 7.660 | 8.610 |
| R15: Skill demand: skills most requested by jobs posted in 2026 | READ | 7.702 | 7.265 | 7.242 | 7.403 |
| R16: Salary insights: average advertised salary range per job title and city (2026 postings with salaries) | READ | 1.736 | 1.574 | 1.555 | 1.622 |
| R17: Talent flow: companies people joined right after leaving TCS | READ | 33.863 | 33.733 | 33.784 | 33.793 |
| R18: Recruiter search: open-to-work Bengaluru members with SQL skill, most endorsed first | READ | 15.490 | 7.396 | 7.560 | 10.149 |
| R19: Employer report: open jobs and June 2026 applications of every IT Services company | READ | 197.967 | 197.886 | 194.961 | 196.938 |
| R20: Platform analytics: applications per day and running total, June 2026 | READ | 6.392 | 6.034 | 5.864 | 6.097 |
| R21: Skills pages: the most-endorsed member for each skill | READ | 77.005 | 76.934 | 77.978 | 77.306 |
| R22: Trust & safety console: all applications, newest first, page 4,001 (25 per page) | READ | 28.420 | 28.543 | 28.106 | 28.356 |
| R23: Sign-in: find the member by email, ignoring case | READ | 5.437 | 5.172 | 5.100 | 5.236 |
| R24: Growth: invitation acceptance rate of Premium vs free senders (2026) | READ | 8.237 | 8.185 | 8.417 | 8.280 |
| R25: Career insights: members with a career break of more than 6 months between two positions | READ | 31.706 | 32.447 | 34.480 | 32.878 |
| W01: "Easy Apply": member 1023 applies to job 14075 | WRITE | 1.905 | 0.435 | 0.432 | 0.924 |
| W02: Member 1023 accepts their oldest pending invitation | WRITE | 3.706 | 2.192 | 2.159 | 2.686 |
| W03: …and the new connection is stored once, smaller member id first | WRITE | 3.203 | 2.294 | 2.339 | 2.612 |
| W04: Nightly job: close every job whose closing date has passed | WRITE | 4.198 | 2.099 | 2.383 | 2.893 |
| W05: Recruiter clean-up: reject applications to TCS jobs still unreviewed after 60 days | WRITE | 9.770 | 2.894 | 2.748 | 5.137 |
| **Total (sum of all 30)** | | **564.291** | **502.027** | **500.384** | **522.234** |


## 3. Observations

- All 30 queries (R01–R25 and W01–W05) have benchmark statistics recorded across three runs.
- The five write queries (W01–W05) were benchmarked separately from the read queries.
- W01 uses the unique constraint on `(job_id, member_id)` for conflict handling.
- R19 had the highest average execution time at **196.938 ms**, making it the slowest query in the baseline benchmark.
- R21 was the second slowest query, with an average execution time of **77.306 ms**.
- R17 (33.793 ms) and R25 (32.878 ms) also showed relatively high average execution times.
- R22 (28.356 ms) and R05 (22.978 ms) were other comparatively expensive read queries.
- Sequential scans appeared in several execution plans, including R13, R17, R19, R21 and R25.
- These execution plans provide opportunities for further investigation and optimization during Phase 4. However, sequential scans are not necessarily inefficient and should be evaluated against table sizes, query selectivity and buffer usage.
- W01 had the lowest average execution time among the write queries at 0.924 ms, while W05 had the highest at 5.137 ms.
- The total average execution time across all 30 queries was **522.234 ms**, calculated as the sum of their individual average execution times.

## 4. Raw Benchmark Results

The complete execution plans and benchmark summary are stored in:

`benchmarks/results/baseline/`

The directory contains:

- `summary.csv` – benchmark statistics, including average, median, minimum and maximum execution times, and scan-node information for each query.
- `R01.txt`–`R25.txt` – individual read-query execution plans.
- `W01.txt`–`W05.txt` – individual write-query execution plans.

These files provide the baseline reference for comparing query performance after indexing and query optimization in Phase 4.
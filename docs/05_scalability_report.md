# Phase 5 — Scalability Report

**Project:** LinkedIn Professional Networking & Jobs Database   
**Database:** PostgreSQL 18  
**Seed database:** `linkedin_db`  
**Large database:** `linkedin_large`
**Benchmark Workload:** `sql/06_optimized_queries.sql`  

---

## 1. Introduction

The purpose of Phase 5 is to test whether our optimized database can handle a much larger dataset and support future growth.

We created a separate database named `linkedin_large`, loaded the faculty-provided large dataset, applied indexes, and executed all 30 optimized queries.

The original seed database was preserved.

**Key results:**
- Approximately 21.3 million rows loaded.
- All 30 optimized queries passed their performance targets.
- R09 was optimized using an additional covering index.
- Monthly range partitioning was implemented as a separate demonstration.
- Partition pruning was successfully verified.
- Storage usage was measured for both databases.

## 2. Large Dataset

The large dataset contains approximately 20 times the original data volume.

| Table | Rows |
|---|---:|
| cities | 10 |
| skills | 72 |
| companies | 40,000 |
| members | 800,000 |
| positions | 1,998,792 |
| member_skills | 4,249,459 |
| connections | 4,399,965 |
| invitations | 1,199,999 |
| jobs | 300,000 |
| job_skills | 1,315,149 |
| applications | 2,999,984 |
| profile_views | 3,999,994 |
| **Total** | **21,303,424** |

### Benchmark methodology

We used the optimized queries from `sql/06_optimized_queries.sql`.

Each query was executed three times, and its average execution time was recorded. Write queries were executed inside transactions with rollback to prevent permanent changes.

Command used:

```bash
./benchmarks/run_large_benchmark.sh linkedin_large after 3 sql/06_optimized_queries.sql
```

Results and raw execution plans were saved in:

```text
benchmarks/results/large/
```

### 2.1 Performance targets

| Query category | Queries | Target |
|---|---|---:|
| Real-time / member-facing | R01–R04, R08–R11, R23, W01–W03 | <5 ms |
| Interactive / search / recommendations | R05–R07, R12, R13, R18, R22, W05 | <250 ms |
| Reports / analytics | R14–R17, R19–R21, R24, R25 | <5,000 ms |
| Batch | W04 | <1,000 ms |

## 3. Large Dataset Performance Results

The following table contains the average execution time from three runs.

| Query | Type | Average (ms) | Target (ms) | Result |
|---|---|---:|---:|---|
| R01 | READ | 0.278 | 5 | PASS |
| R02 | READ | 0.130 | 5 | PASS |
| R03 | READ | 0.190 | 5 | PASS |
| R04 | READ | 0.189 | 5 | PASS |
| R05 | READ | 9.638 | 250 | PASS |
| R06 | READ | 45.449 | 250 | PASS |
| R07 | READ | 51.283 | 250 | PASS |
| R08 | READ | 0.132 | 5 | PASS |
| R09 | READ | 0.241 | 5 | PASS |
| R10 | READ | 0.112 | 5 | PASS |
| R11 | READ | 0.203 | 5 | PASS |
| R12 | READ | 47.954 | 250 | PASS |
| R13 | READ | 249.203 | 250 | PASS |
| R14 | READ | 99.651 | 5,000 | PASS |
| R15 | READ | 64.991 | 5,000 | PASS |
| R16 | READ | 12.973 | 5,000 | PASS |
| R17 | READ | 578.797 | 5,000 | PASS |
| R18 | READ | 24.824 | 250 | PASS |
| R19 | READ | 59.655 | 5,000 | PASS |
| R20 | READ | 22.731 | 5,000 | PASS |
| R21 | READ | 431.889 | 5,000 | PASS |
| R22 | READ | 6.279 | 250 | PASS |
| R23 | READ | 0.138 | 5 | PASS |
| R24 | READ | 119.313 | 5,000 | PASS |
| R25 | READ | 543.219 | 5,000 | PASS |
| W01 | WRITE | 1.164 | 5 | PASS |
| W02 | WRITE | 0.700 | 5 | PASS |
| W03 | WRITE | 0.748 | 5 | PASS |
| W04 | WRITE | 171.227 | 1,000 | PASS |
| W05 | WRITE | 139.243 | 250 | PASS |

### Target compliance

| Category | Passed | Total |
|---|---:|---:|
| Real-time / member-facing | 12 | 12 |
| Interactive search and recommendations | 8 | 8 |
| Reports and analytics | 9 | 9 |
| Batch jobs | 1 | 1 |
| **Overall** | **30** | **30** |

All 30 queries met the faculty's performance targets.

R13 is close to its limit: 249.203 ms against a 250 ms target. It should be monitored as the dataset grows.

## 4. Seed vs Large Dataset Comparison

This table compares the optimized seed timings with the final large-dataset timings.

Growth is calculated as:

`Large execution time / Seed execution time`

| Query | Optimized on seed (ms) | Optimized on large (ms) | Growth (large ÷ seed) | Meets target? | If not, what you changed |
|---|---:|---:|---:|:---:|---|
| R01 | 0.062 | 0.278 | 4.48× | Yes | — |
| R02 | 0.136 | 0.130 | 0.96× | Yes | — |
| R03 | 0.059 | 0.190 | 3.22× | Yes | — |
| R04 | 0.125 | 0.189 | 1.51× | Yes | — |
| R05 | 1.106 | 9.638 | 8.72× | Yes | — |
| R06 | 3.365 | 45.449 | 13.51× | Yes | — |
| R07 | 4.639 | 51.283 | 11.06× | Yes | — |
| R08 | 0.096 | 0.132 | 1.38× | Yes | — |
| R09 | 2.054 | 0.241 | 0.12× | Yes | Added covering index |
| R10 | 0.130 | 0.112 | 0.86× | Yes | — |
| R11 | 0.159 | 0.203 | 1.28× | Yes | — |
| R12 | 4.642 | 47.954 | 10.33× | Yes | — |
| R13 | 10.331 | 249.203 | 24.12× | Yes* | Retained NULL-safe NOT EXISTS |
| R14 | 7.839 | 99.651 | 12.71× | Yes | — |
| R15 | 7.261 | 64.991 | 8.95× | Yes | — |
| R16 | 1.581 | 12.973 | 8.20× | Yes | — |
| R17 | 26.512 | 578.797 | 21.83× | Yes | — |
| R18 | 2.367 | 24.824 | 10.49× | Yes | — |
| R19 | 3.610 | 59.655 | 16.52× | Yes | — |
| R20 | 1.116 | 22.731 | 20.37× | Yes | — |
| R21 | 19.419 | 431.889 | 22.24× | Yes | — |
| R22 | 6.470 | 6.279 | 0.97× | Yes | — |
| R23 | 0.045 | 0.138 | 3.07× | Yes | — |
| R24 | 8.266 | 119.313 | 14.44× | Yes | — |
| R25 | 24.124 | 543.219 | 22.52× | Yes | — |
| W01 | 0.769 | 1.164 | 1.51× | Yes | — |
| W02 | 0.467 | 0.700 | 1.50× | Yes | — |
| W03 | 0.533 | 0.748 | 1.40× | Yes | — |
| W04 | 2.862 | 171.227 | 59.83× | Yes | — |
| W05 | 6.154 | 139.243 | 22.62× | Yes | — |

*R13 passes narrowly, at 249.203 ms.*

### Growth analysis

**Queries with relatively low growth**

R02, R04, R08, R10, R11 and R22 remained close to their seed execution times.

These queries benefit from selective index lookups and do not need to process the entire dataset.

**Queries with moderate growth**

R05, R06, R07, R12, R14, R15, R16, R18, R19 and R24 became slower as the number of rows increased.

These queries perform joins, filtering, or aggregations over larger datasets.

**Queries with higher growth**

R17, R20, R21, R25, W04 and W05 experienced more significant increases.

They process larger portions of the data or perform operations such as window functions, aggregations, and bulk updates.

R09 improved substantially because of its additional covering index.

Growth ratios describe observed timings, not a guarantee that future execution times will grow linearly.

## 5. Scale-Specific Optimizations

### 5.1 R09 — Additional covering index

The original R09 plan used a parallel sequential scan on the applications table.

Original large-dataset average:

**27.794 ms**

We created the following index:

```sql
CREATE INDEX idx_applications_member_applied_at
ON linkedin.applications (member_id, applied_at DESC)
INCLUDE (application_id, job_id, status);
```

The new plan used an Index Only Scan on the applications table.

Final large-dataset average:

**0.241 ms**

Improvement:

**Approximately 99.13%.**

The index was also added to `sql/05_indexes.sql` to make the optimization reproducible.

### 5.2 R13 — NULL handling

The original query used `NOT IN` with `profile_views.viewer_id`.

Because `viewer_id` can contain NULL values for private-mode viewers, `NOT IN` can produce incorrect results.

We retained the NULL-safe `NOT EXISTS` approach:

```sql
SELECT m.member_id, m.first_name, m.last_name
FROM members m
WHERE NOT EXISTS (
    SELECT 1
    FROM profile_views v
    WHERE v.viewer_id = m.member_id
);
```

The existing partial index on `profile_views(viewer_id)` supports the lookup.

Final average:

**249.203 ms**

It meets the target, but needs monitoring because it is close to the threshold.

## 6. Storage Analysis

### 6.1 Database sizes

| Database | Size |
|---|---:|
| Seed (`linkedin_db`) | 143 MB |
| Large (`linkedin_large`) | 2,790 MB |

The large database occupies approximately 19.5 times the storage of the seed database.

### 6.2 Table and index storage

| Storage component | Seed | Large |
|---|---:|---:|
| Table storage | 62 MB | 1,198 MB |
| Index storage | 72 MB | 1,584 MB |
| Tables + indexes | 134 MB | 2,782 MB |
| Database size | 143 MB | 2,790 MB |

Indexes account for approximately 57% of combined table and index storage in the large database.

### 6.3 Important table sizes

| Table | Total size | Index size |
|---|---:|---:|
| members | 154 MB | 55 MB |
| applications | 751 MB | 540 MB |

Indexes improve read performance but consume additional storage and increase the cost of writes. Therefore, indexes should be monitored and unnecessary ones should be removed only after checking their usage.

## 7. Partitioning Strategy

### 7.1 Selected table

We selected the `applications` table for partitioning because it contains nearly three million rows and many queries filter applications by date.

### 7.2 Partitioning method

We used monthly RANGE partitioning on `applied_at`.

The separate partitioned table is:

```text
linkedin.applications_partitioned
```

The SQL implementation is in:

```text
sql/08_partitioning.sql
```

The script creates monthly partitions based on the existing application's date range and a default partition.

The original `linkedin.applications` table remains unchanged.

### 7.3 Primary key consideration

PostgreSQL requires the partition key to be included in the primary key or unique constraint of a partitioned table.

Original primary key:

```sql
PRIMARY KEY (application_id)
```

Partitioned table primary key:

```sql
PRIMARY KEY (application_id, applied_at)
```

The original unique constraint on `(job_id, member_id)` also cannot be enforced globally by a partitioned unique constraint that excludes the partition key.

A separate uniqueness registry was included in the design to preserve this business rule. Writes must maintain the registry and partitioned table together in a controlled transaction.

### 7.4 Partition pruning verification

We tested partition pruning with:

```sql
EXPLAIN
SELECT application_id, job_id, member_id, applied_at, status
FROM linkedin.applications_partitioned
WHERE applied_at >= TIMESTAMPTZ '2025-01-01 00:00:00+00'
  AND applied_at < TIMESTAMPTZ '2025-02-01 00:00:00+00';
```

Observed plan:

```text
Seq Scan on applications_p2025_01 applications_partitioned
  Filter: applied_at >= '2025-01-01...'
      AND applied_at < '2025-02-01...'
```

PostgreSQL selected only the January 2025 partition instead of scanning all monthly partitions.

**Result: Partition pruning successfully verified.**

**Limitation:** The partitioned demonstration table is currently empty. This proves that PostgreSQL selects the correct partition, but does not prove a speed improvement on three million populated rows.

## 8. Architecture for 100× Growth

The current implementation uses a single PostgreSQL instance. For substantially higher traffic and data volume, the following architecture is proposed.

### 8.1 Sharding

A possible approach is to distribute member-centric data using `member_id`.

For example:

- Shard 1: member hash bucket 0
- Shard 2: member hash bucket 1
- Shard 3: member hash bucket 2
- Shard 4: member hash bucket 3

This distributes member profiles, member skills, and related data.

However, connections contain two member IDs: `member_a` and `member_b`. The members may be stored on different shards.

Queries such as R03, R04 and R05 would therefore require cross-shard lookups.

A possible solution is to maintain connection lookup records from both members' perspectives or use a distributed query layer that can combine results from multiple shards.

### 8.2 Read replicas

Read replicas can handle reporting and read-heavy traffic, reducing load on the primary database.

Potential replica queries:

- Analytics: R14, R15, R16, R17, R19, R20, R21, R24 and R25.
- Search and recommendations: R05, R06, R07, R12 and R18.
- Member-facing reads when slightly stale results are acceptable.

All writes (W01–W05) should go to the primary database.

Operations requiring immediate read-after-write consistency should also use the primary.

### 8.3 Caching

Redis or a similar caching system could be used for frequently accessed data.

Potential candidates:

- Member profile summaries.
- Company information.
- Job search results.
- Popular skills.
- Recommendation results.

Cache invalidation should happen whenever relevant underlying records change.

Frequently changing or sensitive information should use short cache lifetimes or bypass caching.

### 8.4 Maintenance

Recommended PostgreSQL maintenance operations include:

```sql
VACUUM (ANALYZE) linkedin.applications;

ANALYZE linkedin.applications;
```

Other maintenance practices:

1. Monitor autovacuum activity and dead tuples.
2. Adjust autovacuum thresholds according to table size and update frequency.
3. Monitor index size and bloat.
4. Reindex when measurements indicate a need.
5. Archive old applications using date-based retention policies.
6. Refresh summary tables and materialized views.
7. Monitor database size, query latency, replication lag and disk space.
8. Create future monthly partitions before they are needed.

## 9. Risks and Limitations

| Risk | Proposed solution |
|---|---|
| R13 is close to its target | Monitor execution time and query plans |
| Indexes consume significant storage | Review index usage and redundancy |
| Analytical queries become slower as data grows | Use summary tables and read replicas |
| Cross-shard connections are complex | Maintain distributed relationship lookups |
| Missing monthly partitions | Automate partition creation |
| Replica data may be stale | Use the primary for consistency-sensitive reads |
| Partition uniqueness needs coordination | Maintain the registry and partitioned table atomically |

The partitioning design is currently a separate demonstration and has not replaced the original applications table.

## 10. Conclusion

The Phase 5 benchmark demonstrates that the optimized database can handle the supplied large dataset within all specified performance targets.

The project achieved:

- Loading and analyzing approximately 21.3 million rows.
- Running all 30 optimized queries three times.
- Meeting all 30 performance targets.
- Reducing R09 execution time from 27.794 ms to 0.241 ms.
- Verifying monthly partition pruning.
- Measuring table and index storage.
- Designing a future architecture using sharding, replicas, caching and maintenance automation.

The current database meets the tested 20× workload requirements.

However, additional testing with populated partitions and a production-like distributed environment is needed before claiming readiness for 100× growth.

**Overall conclusion:** The optimized PostgreSQL database meets the tested Phase 5 performance targets and provides a foundation for future scalability. The main areas requiring further attention are R13 performance headroom, index storage overhead and cross-shard relationship queries.
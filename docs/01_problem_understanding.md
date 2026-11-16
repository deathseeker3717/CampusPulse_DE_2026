# Problem Understanding

## 1. Project Overview

This project focuses on designing a relational database for a professional networking and job marketplace platform similar to LinkedIn. It manages member profiles, work experience, skills, connections, job postings, applications and profile views. Our goal is to understand the business requirements and build a reliable PostgreSQL database that supports these activities efficiently.

## 2. Business Problems and Stakeholders

| ID | Business Need | Stakeholder | Classification |
|---|---|---|---|
| P1 | Member profiles, work experience, connections and mutual connections should load quickly, especially for highly connected members. | Members / Job Seekers | Customer-facing / Real-time |
| P2 | The platform needs to generate People You May Know suggestions and process connection invitations efficiently. | Members / Growth Team | Customer-facing / Real-time |
| P3 | Members should be able to search for relevant jobs, receive recommendations and apply without delays. | Job Seekers / Company Page Admins | Customer-facing / Real-time |
| P4 | Recruiters need quick access to applicants, candidate searches and application status updates. | Recruiters / Company Page Admins | Customer-facing / Real-time |
| P5 | The platform should correctly identify members who have never viewed another profile and support engagement campaigns, while respecting private-mode views. | Members / Engagement Team | Reporting / Analytics |
| P6 | The database should support reports on employee tenure, hiring time, skill demand, salaries, talent movement and career breaks. | Talent Insights Team | Reporting / Analytics |
| P7 | Platform reports and job maintenance operations need to perform efficiently as activity is expected to grow by 20 times. | Platform / Trust & Safety Team | Reporting / Analytics and Operational Writes |

## 3. Assumptions

1. The 12 provided CSV files are the source of truth, and their table and column names will be preserved.
2. A member can have multiple positions. A position with no `end_date` is considered current.
3. Connections are mutual and stored only once, with the smaller member ID in `member_a` and the larger ID in `member_b`.
4. Member skills and job skills are many-to-many relationships, represented through separate tables.
5. A member can apply to a particular job only once. An invitation is a directed request from a sender to a recipient.
6. A missing `viewer_id` in profile views represents a private-mode viewer. Optional fields should allow NULL values where the data and business rules permit.
7. Initial performance measurements will be taken before adding optimization indexes, so that the original database performance can be evaluated fairly.
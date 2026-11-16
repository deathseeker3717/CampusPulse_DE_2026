
-- Load seed data into the LinkedIn Professional Network database
-- Run with psql from the project root.
-- Database: linkedin_db

SET search_path TO linkedin;

\copy cities FROM 'seed_data/cities.csv' WITH (FORMAT csv, HEADER true)
\copy skills FROM 'seed_data/skills.csv' WITH (FORMAT csv, HEADER true)
\copy companies FROM 'seed_data/companies.csv' WITH (FORMAT csv, HEADER true)
\copy members FROM 'seed_data/members.csv' WITH (FORMAT csv, HEADER true)
\copy positions FROM 'seed_data/positions.csv' WITH (FORMAT csv, HEADER true)
\copy member_skills FROM 'seed_data/member_skills.csv' WITH (FORMAT csv, HEADER true)
\copy connections FROM 'seed_data/connections.csv' WITH (FORMAT csv, HEADER true)
\copy invitations FROM 'seed_data/invitations.csv' WITH (FORMAT csv, HEADER true)
\copy jobs FROM 'seed_data/jobs.csv' WITH (FORMAT csv, HEADER true)
\copy job_skills FROM 'seed_data/job_skills.csv' WITH (FORMAT csv, HEADER true)
\copy applications FROM 'seed_data/applications.csv' WITH (FORMAT csv, HEADER true)
\copy profile_views FROM 'seed_data/profile_views.csv' WITH (FORMAT csv, HEADER true)

ANALYZE;
